# 常用命令
## binlog
+ 查看二进制位置
```sql
show variables like '%log_bin%';
select @@log_bin_basename;
```
+ 查看所有的日志 `show binary logs;`
+ 日志滚动 结束当前文件记录,产生新的日志文件`flush logs;`
+ 查看当前使用的二进制 `show master status;`
+ 查看全部的二进制列表 `show master logs;`
+ 查看二进制事件 `show binlog events in 'mysql_bin.000003';`
+ 在linux下使用工具查看文件(带翻译)
```sh
mysqlbinlog --base64-output=decode-rows -vvv mysql_bin.000003
mysqlbinlog -d 库名 --base64-output=decode-rows -vvv mysql_bin.000003 #按库名过滤功能
```
+ 截取二进制 按position截取,即在二进制文件中的第多少字节.需要保存成文件用作恢复,可以追加 `>tmp.sql`
```sh
mysqlbinlog --base64-output=decode-rows -vvv --start-position=1485 --stop-position=1708 mysql_bin.000003 
```
+ `reset master;`重置日志,从mysql_bin.000001开始

# 错误日志
配置:
`datadir/hostname.err`
包含各种错误

# 慢查询日志
## 配置文件
```ini
slow_query_log=1
##文件位置及名称
slow_query_log_file=/data/mysql/3306/log/slow.log
##设定慢查询时间
long_query_time=0.1
##没走索引的语句也记录
log_queries_not_using_indexes
```
## 分析慢日志:
`mysqldslow -s c /data/slow.log`\
`--s c`代表合并同样的语句记次数\
第三方工具: percona-toolkit

# 二进制日志
## 配置
⚠️默认没开启
⚠️serverid一定要配置好,因为binlog中包含serverid,不配置则会导致数据库无法启动.
```ini
server_id=3
log_bin=/data/mysql/3306/log/mysql_bin #开启并设置文件路径
binlog_format=row
```
## binlog作用
+ 做主从
+ 数据恢复

## 查看binlog信息

## binlog记录方式
DML 有三种方式(statement,row,mixed),通过binlog_format=row参数控制.
+ statement: SBR,语句模式,做什么就记什么
+ row: RBR,行模式,数据行的变化,属于逻辑日志(redo是记录数据页的变化,属于物理日志)
+ mixed: MBR,自动选择\
无论哪种模式,记录的数据库所以变更的操作日志:DDL,DCL,DML都会以sql语句形式记录,例如create,drop,grant等等.

比较:\
SBR和RBR什么区别?怎么选择?
+ SBR:	可读性较强`update t1 set name='zs' from abc where xx>100 and xx<105;`但有可能记录不准确,节省空间.
+ RBR:	记录五条数据的变化,可读性差,日志量大,但是不会出现记录错误,一般用这个选项.

## binlog的记录单元
二进制日志的最小单元是事件(event)
DDL: create database oldguo;
每个语句都是一个事件
DML: 一个事务包含多个语句
begin;		事件1
a			事件2
b			事件3
commit;		事件4


## binlog的gtid记录模式的管理
### GTID介绍
对于binlog中的每个binlog事务(和mysql事务不同概念),都会产生一个GTID号码\
DDL DCL 一个event就是一个事务,就会有一个GTID号\
DML来说begin到commit是一个事务,产生一个GTID号

GTID的组成
server_uuid:TID

cat auto.cnf
结果:server-uuid=4957529a-93d6-11ed-bd8f-080027dd4b93

TID是一个:自增长的数据,从1开始
server-uuid=4957529a-93d6-11ed-bd8f-080027dd4b93

⚠️GTID幂等性
如果拿有GTID的日志去恢复时,检查当前系统中是否有相同的GTID,如果有则忽略该操作

### 开启GTID:
在配置文件中:
```ini
[mysqld]
gtid-mode=on
enforce-gtid-consistency=true
```
GTID截取:
`mysqlbinlog --include-gtids='4957529a-93d6-11ed-bd8f-080027dd4b93:5-7' mysql_bin.000004 >tmp.sql`\
 ⚠️使用该命令产生的sql文件,会报错,因为导入时候连同gtid一起复制过来,由于幂等性,导致这些重复的gtid事务被忽略未执行\
 正确做法:加入--skip-gtids不复制gtid,恢复时当新的事务对待
 ```sh
 mysqlbinlog --skip-gtids --include-gtids='4957529a-93d6-11ed-bd8f-080027dd4b93:5-7' mysql_bin.000004 >tmp.sql
 ```

### binlog的清理
设置的依据:至少1轮全被周期长度+1天\
配置文件:
```ini
expire_logs_days=15
```


## 使用日志恢复实例:
### 建库建表
```sql
create database haoge charset utf8mb4;
use haoge;
create table t1(id INT PRIMARY KEY NOT NULL AUTO_INCREMENT COMMENT 'ID',
v varchar(30) NOT NULL COMMENT 'Value');
insert into t1(v) values('A');
insert into t1(v) values('B');
insert into t1(v) values('C');
commit;
```
### 打开日志确定位置
```sql
show master status;
show binlog events in 'mysql_bin.000003';
mysqlbinlog --start-position=1773 --stop-position=2723 mysql_bin.000003 >tmp.sql
```
### 恢复binlog
当前会话临时关闭binlog
```sql
set sql_log_bin=0;
source /data/tmp.sql
set sql_log_bin=1;
```

