# 常用命令
## 逻辑全备语句
```sh
mysqldump -S mysql.sock -A --triggers -R --master-data=2 -F --single-transaction --set-gtid-purged=OFF --max_allowed_packet=256M|gzip > /data/mysql/3306/backup/full_$(date +%F-%T).sql.gz
```

# 逻辑备份
### 解压缩
```sh
gzip -dk file.gz
```
+ -d解压
+ -k保留源文件
## 备份策略的设计
备份周期:
根据数据量.80G每天做全备\
备份工具: mysqldump, Percona Xtrabackup, MEB(Mysql enterprise Backup)\
逻辑方式:(备份出来的就是create insert这样的语句,根据数据得来,重构数据库,转换时间较长)\
全备mysqldump\
增量binlog

## 备份方式
物理方式:(主要就是cp磁盘上的文件)\
全备+增量Percona Xtrabackup\
对比:逻辑,备份出来的可读性高,压缩比高因为都是文本,二进制文件相当于是视频不好压缩.但是转换时间比较长.\
通常100G以内用mysqldump,100g-TB级别用XBK,再以上用mysqldump因为磁盘空间太大\

## 备份类型:
+ 热备:对业务影响最小(InnoDB支持)
+ 温备:长时间锁表备份
+ 冷备:业务关闭情况下备份

## 新环境,了解当前备份情况
通过查看计划任务crontab看看有没有定时的备份任务
+ `corntab -l`查看计划任务
+ 备份脚本   
+ 查看备份路径
+ 查看备份日志
+ 检查备份文件(大小,内容),空间是否够用

## 定期的恢复演练
一季度或者半年,在测试库上做恢复演练,只要备份和日志是完整的,恢复到故障之前的时间点,并不长时间影响业务.

## 数据迁移
+ mysql -> mysql
+ 其他  -> mysql
+ mysql -> 其他
+ 操作系统之间的数据库迁移

## mysqldump登录
链接数据库-u -p -S -h -P功能和mysql登录相同

## 备份参数
### 基础备份参数
+ -A 全备:`mysqldump -uroot p123 -A >/data/full.sql`
+ -B 备份单库(含有建库语句) `mysqldump -B world oldguo >/backup/db.sql`
+ 库 表(不包含建库语句,只备份表)`mysqldump world city country >/backup/db.sql`\
`mysqldump -uroot p123 库名 表名 表名 >/backup/db.sql`
### 特殊备份参数
自定义的程序体也包含进去,否则只包含数据,基本都要加上
+ -triggers 触发器
+ -R 存储过程和函数
+ -events时间调度器(-E)

### 其他特殊参数
+ -F 备份时同时flush binlog
+ --master-data 以注释形式(=2时)将binlog的当前文件和position号记录下来.自动锁表
+ --single-transaction 对于innodb进行快照备份,使所有表一致的dump出来.
+ --set-gtid-purged=OFF 选择是否备份原库的GTIDs\
⚠️OFF 只是用来做备份的\
⚠️ON 会自动关闭bin_log,用作主从复制
+ --max_allowed_packet=256M 指的用mysqldump服务器端可传输的包大小
## mysqldump的完整命令
```sh
mysqldump -S mysql.sock -A --triggers -R --master-data=2 -F --single-transaction --set-gtid-purged=OFF --max_allowed_packet=256M >/data/mysql/3306/backup/full.sql
```
## 恢复案例
背景:
+ 每天全备
+ binlog日志完整
+ 模拟白天的数据变化
+ 模拟下午两点误删除
需求:利用全备+binlog恢复到误删除数据库之前

故障模拟及恢复:\
模拟周一23:00的全备
```sh
mysqldump -S mysql.sock -A --triggers -R --master-data=2 -F --single-transaction --set-gtid-purged=OFF --max_allowed_packet=256M >/data/mysql/3306/backup/full.sql
```
模拟白天数据变化:\
```sql
create database day1 charset=utf8mb4;
use day1;
create table t1(id int PRIMARY KEY NOT NULL,content varchar(10));
insert into t1 values(1,'one'),(2,'two'),(3,'three');
commit;
use world;
update city set countrycode='CHN';
commit;
```
模拟数据损坏:\
`rm -rf /data/mysql/3306/data/*`

关闭进程:
```sh
ps -ef|grep mysqld
pkill mysqld
```
修复:\
1. 重新建立数据库:
```sh
rm -rf /data/mysql/3306/data/*
mysqld --defaults-file=/etc/my.cnf --initialize-insecure --basedir=/usr/bin/mysql --datadir=/data/mysql/3306/data
chown -R mysql.mysql /data/mysql/3306/data/*
```
2. 截取binlog
`vim full.sql`找到其中的master data 的文件和position并记下\
`mysqlbinlog --start-position=1485 --skip-gtids mysql_bin.000004  >tmp.sql`
3. 启动数据库并进行恢复
```sh
systemctl start mysqld@3306
mysql -S /data/mysql/3306/mysql.sock
```
```sql
set sql_log_bin=0;
source /data/mysql/3306/backup/full.sql;
source /data/mysql/3306/log/tmp.sql;
set sql_log_bin=1;
```

## 案例
### 描述
背景: 正在运行的网站系统,mysql-5.7,数据量50G,日业务增量1-5M\
备份策略: 每天23:00进行全备mysqldump,在单独的备份服务器\
故障时间点: 模拟周三上午10点误删除数据库,并进行恢复
### 恢复
思路:\
1. 停业务,挂维护页,避免数据的二次伤害
2. 找一个临时库,恢复周三23:00的全备
3. 截取周二23:00-周三10点之间误删除的binlog,恢复到临时库
4. 将临时库还原回主库 或者 将业务切换到临时库\
截取binlog，使用tail截取最后一百个，使用grep过滤。:
```sh
mysql -e "show binlog events in 'mysql_bin.000003';" |tail -100 |grep -i insert
```

## 闪回工具
binlog2sql用于分析RAW格式的DML语句，产生相反的语句，恢复误删除误修改的行。

# 物理备份
## 工具安装
```sh
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
yum -y install perl perl-devel libaio libaio-devel perl-Time-HiRes perl-DBD-MySQL libev
wget https://www.percona.com/downloads/XtraBackup/Percona-XtraBackup-2.4.12/binary/redhat/7/x86_64/percona-xtrabackup-24-2.4.12-1.el7.x86_64.rpm
yum -y install percona-xtrabackup-24-2.4.12-1.el7.x86_64.rpm
```
## 备份原理
1. 对于非Innodb表（比如 myisam）是，锁表cp数据文件，属于一种温备份。
2. 对于Innodb的表（支持事务的），不锁表，拷贝数据页，最终以数据文件的方式保存下来，把一部分redo和undo一并备走，属于热备方式。

过程:\
1. xbk备份执行的瞬间,也就是checkpoint,已提交的数据脏页,从内存刷写到磁盘,并记录此时的LSN号
2. 备份时，拷贝磁盘数据页，并且记录备份过程中产生的redo和undo一起拷贝走,也就是checkpoint LSN之后的日志
3. 在恢复之前，模拟Innodb“自动故障恢复”的过程，将redo（前滚）与undo（回滚）进行应用
4. 恢复过程是cp 备份到原来数据目录下

## 备份命令
```sh
innobackupex --user=root --socket=mysql.sock ./backup/
```

## 备份出的文件解析
```sh
backup_type = full-backuped
from_lsn = 0 ##全备都是0开始
to_lsn = 9769790  ##命令开始执行时候的LSN号
last_lsn = 9769799 ##命令开始执行结束的LSN号，只差9个代表无差别，是xtrabackup处理产生的，没有新业务。
compact = 0
recover_binlog_info = 0
```
## 恢复全备
```sh
innobackupex --apply-log 2023-02-17_19-39-30 #先要加载redo undo日志
innobackupex --user=root --defaults-file=my.cnf --copy-back 2023-02-17_19-39-30 #开始恢复
chown -R mysql.mysql /3306/data #修改文件权限
```
⚠️my.cnf文件似乎只能认识`[mysqld]`下的datadir等其他参数。