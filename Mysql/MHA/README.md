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
create user repl@'150.158.138.78' identified by '123';
grant replication slave on *.* to repl@'150.158.138.78';
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
MASTER_LOG_FILE='mysql_bin.000002',
MASTER_LOG_POS=194,
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
![原理图](https://github.com/storm1945/Memo/blob/master/Mysql/MHA/structure.png "原理图")

