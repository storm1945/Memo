# 高可用性介绍
## 标准
全年无故障率:
+ 99.9% 525.6min/year
+ 99.99% 52.56min/year
+ 99.999% 5.256min/year

## 构架
+ 负载均衡:有一定高可用性 LVS,Nginx
+ 主备(单活): 有高可用性，但是需要切换 KA,MHA
+ 真正的高可用性(多活): NDB,Oracle RAC,Sysbase cluster,InnoDB Cluster(MGR)

# 主从复制
## 主从复制的作用
+ 处理数据库的物理损坏,例如系统层面的rm，物理磁盘损坏。不能处理逻辑损坏(例如drop)。
+ 比备份恢复更快恢复故障。
+ 扩展新型的架构：高可用，高性能，分布式构架

## 实现原理
基于二进制日志复制，主库的修改操作会记录二进制日志，从库请求日志，达到同步。
1. 准备两台已上mysql实例，server_id,server_uuid不同。
2. (主库)开启主库binlog
3. (主库)建立专用的slave用户账号
4. (从库)保证从库开启之前的某个时间点，从库数据是和主库一致的（补齐数据）
5. (从库)change master to,设置从库中主库的信息，写入ip,port,password，复制的起点
6. (主库从库)开启主库中slave线程。(主库:binlog_dump_T，从库IO_T,SQL_T)

## 具体实现
1. 准备实例
2. 权限
```sql
create user repl@'%' identified by '123';
grant replication slave on *.* to repl@'%';
```
3. 备份主库,找到备份结束的position
4. 从库中恢复
5. help change
```sql
CHANGE MASTER TO
MASTER_HOST='150.158.138.78',
MASTER_USER='repl',
MASTER_PASSWORD='123',
MASTER_PORT=3306,
MASTER_LOG_FILE='mysql_bin.000004',
MASTER_LOG_POS=637,
MASTER_CONNECT_RETRY=10;
```
6. 启动线程
```
start slave;
```

## 主从复制监控
### 查看监控主从复制状态
```
show slave status \G;
```
### 主库相关信息
```
Master_Host: 150.158.138.78
Master_User: repl
Master_Port: 3306
Master_Log_File: mysql_bin.000002
```
### 从库中继日志的应用状态
```
Relay_Log_File: VM-4-17-centos-relay-bin.000002
Relay_Log_Pos: 1248
```
### 从库的线程状态
```
Slave_IO_Running: Yes
Slave_SQL_Running: Yes

Last_IO_Errno: 0
Last_IO_Error: 
Last_SQL_Errno: 0
Last_SQL_Error: 
```
### 过滤复制相关的状态
```
Replicate_Do_DB:
Replicate_Ignore_DB:
Replicate_Do_Table:
Replicate_Ignore_Table:
Replicate_Wild_Do_Table:
Replicate_Wild_Ignore_Table:
```
### 主从延时的相关状态(非人为)
```
Seconds_Behind_Master: 0
```
### 延时从库有关的状态(人为配置)
```
SQL_Delay: 0
SQL_Remaining_Delay: NULL
```
### GTID复制状态
```
Retrieved_Gtid_Set: cad5ab8f-aec6-11ed-81eb-5254003bb641:41-44
Executed_Gtid_Set: cad5ab8f-aec6-11ed-81eb-5254003bb641:41-44
Auto_Position: 0
```
## 主从复制的结构
### 文件结构
主库: 
+ mysql_bin.000002 二进制日志


从库:
+ db01-relay-bin.000001 中继日志文件
+ master.info 主库信息
+ relay-log.info 中继日志信息
### 线程结构
主库：
+ Binlog_Dump_Thread

从库: 
+ Slave_IO_Thread
+ Slave_SQL_Thread
### 主从复制的原理图
![原理图](https://github.com/storm1945/Memo/blob/master/Mysql/Master-Slave-Replication/structure.png "原理图")
### IO线程故障
##### 主库连接问题:
+ IP,Port,user,password
+ 主库没启动
+ 防火墙
+ 网络不通
+ 连接数上限

表现为 Slave_IO_Running: connecting,可以使用手动连接数据库,看报错确定具体问题.
```
Last_IO_Errno: 0
Last_IO_Error: 
```
##### 二进制请求问题:
例如在主库中执行`reset master;`\
Slave_IO_Running: Yes --> Slave_IO_Running: No\
Last_IO_Errno: 1236\
Last_IO_Error: Got fatal error 1236 from master when reading data from binary log: 'could not find next log; the first event 'mysql_bin.000002' at 194, the last event read from '/data/mysql/3306/log/mysql_bin.000002' at 1122, the last byte read from '/data/mysql/3306/log/mysql_bin.000002' at 1122.'\

或者使用 `cat mysqld-3307.log` 查看从库error log \

处理过程:
1. 从库`stop slave;`
2. 重置从库信息`reset slave all`;
3. 重新搭建主从.

⚠️主从环境中主库禁止使用reset master,可以使用log expire 定期清理
### SQL线程功能:
+ 读写relay-log.info
+ relay-log损坏,断节,找不到
+ 接受到的sql无法运行
#### 导致sql线程故障原因分析
+ 版本差异,参数设置不同,例如:数据类型的差异,SQL_MODE影响
+ 要创建数据库的对象,已经存在
+ 要修改删除的对象不存在
+ DML语句不符合表定义及约束时
+ 权限不一致
+ ⚠️从库发生写入

#### 从库写入错误模拟
```sql
create database rep charset=latinl; --从库修改,建立rep,连错数据库
```
```sql
create database rep charset=utf8mb4; --主库修改,建立rep,同步时会出现sql语句无法执行
```
报错:
```
Slave_SQL_Running: No
Last_SQL_Errno: 1007
Last_SQL_Error: Error 'Can't create database 'rep'; database exists' on query. Default database: 'rep'. Query: 'create database rep charset=utf8mb4'
```
恢复方法:
+ 删掉rep
+ 重新建库
+ mysql方法1 (⚠️风险很高,跳过不能执行的语句)
  ```sql
  stop slave;
  set global sql_slave_skip_counter=1;
  start slave;
  ```
  上个例子中字符集不一致,写入时候会遇到错误.
+ mysql方法2 (⚠️风险很高,生产中禁止使用,忽略错误编号)
  ```sh
  vim /etc/my.cnf
  slave-skip-errors = 1032,1062,1007 #错误编号
  ```
预防方法: 
+ 从库设置只读
  ```sh
  vim /etc/my.cnf #从库
  read_only=1 #⚠️对root用户不生效
  ```
+ 加入中间件,实现读写分离
## 主从延迟故障
### 查看延迟
```sql
show slave status;
Master_Log_File: mysql_bin.000001
Read_Master_Log_Pos: 589
```
### 外在因素:
+ 网络
+ 硬件性能差异大
+ 数据库版本差距
+ 数据库参数设置不一致
### 主从因素
#### 主库因素
+ 主库的binlog写入不及时,可能受到系统缓存写入影响,调整binlog_sync参数调整缓存写入策略
+ Classic的主从复制中,binlog_dump线程,事件为单元,串行传送二进制日志(5.6 5.5早起版本的做法)
  - 主库并发大量事务
  - 主库发生一个大型事务,会阻塞后续的事务\
  5.6开始使用GTID,实现了group commit机制,可以并行传输日志给从库\
  5.7开始即使不开启GTID,系统也会自动使用匿名GTID实现GC.但是仍然建议开启GTID\
  对大型事务进行拆分
#### 从库因素
IO 问题一般就是需要把日志放固态硬盘提高性能.\
SQL线程导致的主从延迟:
+ 从库默认情况下只有一个SQL,只能串行回放事务SQL(主库并行,从库串行)\
解决方案: \
5.6 以后开启GTID,加入了多线程,但是只能针不同库.\
5.7 实现了真正的logical clock模式的多线程并发模式.在主库binlog记录时,假如seq_no机制,实现了事务级别的并发. 技术叫做Enhanced multi-threaded slave(MTS)

## 延时型主从控制
### 场景
一定程度上解决逻辑错误,一般设置慢3-6小时,具体看公司运费人员对于故障的反应时间
### 配置延时从库
原理是在SQL执行时候延时执行.\
```
CHANGE MASTER TO
MASTER_DELAY=600
```
具体要执行的实现可以看
```
SQL_Remaining_Delay: NULL
```
### 恢复逻辑故障的恢复思路
1. 及时发现故障
2. 立即停止延时从库的sql线程
   ```sql
   stop slave sql_thread;
   ```
3. 挂维护页
4. 从relay log截取终点\
  起点:stop sql线程时的relay log位置点
  ```
  Relay_Log_File: VM-4-17-centos-relay-bin.000002
  Relay_Log_Pos: 583
  ```
  终点:drop 以前的位置点.
  ```sql
  show relaylog events in 'VM-4-17-centos-relay-bin.000002'
  ```
5. 截取的日志恢复到从库\
  截取方法同binlog
6. 从库替代主库工作\
  恢复同binlog

## 半同步复制
解决主从数据一致性问题.5.7出现的MGR复制. 主要是假如一个ACK应答信号,在从库已经落盘到relaylog时候才通知主库继续向下执行.
## 复制过滤
只复制某些指定库
### 配置
+ 主库配置(不推荐)\
  修改binlog记录方式,分别是黑白名单模式,不符合条件的库不写入binlog,从库自然复制不到.
  ```
  Binlog_Do-DB
  Binlog_Ignore_DB
  ```
+ 从库配置(推荐)
```sql
Replicate_Do_DB:    --库级别
Replicate_Ignore_DB: 

Replicate_Do_Table: --表级别
Replicate_Ignore_Table: 

Replicate_Wild_Do_Table: --模糊表级别
Replicate_Wild_Ignore_Table: 
```
```sh
vim /etc/my.cnf
replicate_do_db=day1  #全部小写,每行只能写一个
replicate_do_db=day2
```

## GTID复制
### 介绍
GTID(Global Transaction ID)是对于一个已提交事务的唯一编号，并且是一个全局(主从复制)唯一的编号。\
它的官方定义如下：\
GTID = source_id ：transaction_id\
7E11FA47-31CA-19E1-9E56-C43AA21293967:29\
什么是sever_uuid，和Server-id 区别？\
核心特性: 全局唯一,具备幂等性
### 配置参数
```sh
vim my.cnf
gtid-mode=on                        #启用gtid类型，否则就是普通的复制架构
enforce-gtid-consistency=true       #强制GTID的一致性
log-slave-updates=1                 #slave更新是否记入日志
```
配置过程同普通主从,主要区别是在,且从库的binlog是强制需要开启的.
```SQL
CHANGE MASTER TO 
MASTER_HOST='150.158.138.78',
MASTER_USER='repl',
MASTER_PASSWORD='123',
MASTER_PORT=3306,
MASTER_CONNECT_RETRY=10,
MASTER_AUTO_POSITION=1; 
--普通的是binlog相关的设置
--MASTER_LOG_FILE='mysql_bin.000004',
--MASTER_LOG_POS=637,
```
⚠️主库备份时候GTID-PURGE一定要ON,通过备份中`SET @@GLOBAL.GTID_PURGED=‘e024c334-8b64-11e9-80dc-fa163e4bfc29:1-761734’;`告诉从库GTID复制起点.
### 在GTID下从库写入故障
⚠️GTID必须连续,如果有断点就会报错
例如 从库先进行了`create database oldboy;`主库再进行`create database oldboy;`,从库无法回放主库的语句造成SQL报错.
```sh
Retrieved_Gtid_Set: cad5ab8f-aec6-11ed-81eb-5254003bb641:1-3 #从主库获得三条事务
 Executed_Gtid_Set: 6197c838-b032-11ed-9238-5254003bb641:1,  #只执行了一条事务
```
解决方法: 可以通过从库输入空的begin; commit;事务占据两个位置,但是有风险,一般不使用

