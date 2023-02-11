## 备份策略的设计
备份周期:
根据数据量.80G每天做全备\
备份工具: mysqldump, Percona Xtrabackup, MEB(Mysql enterprise Backup)\
逻辑方式:(备份出来的就是create insert这样的语句,根据数据得来,重构数据库,转换时间较长)\
全备mysqldump\
增量binlog\

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

其他特殊参数
+ -F 备份时同时flush binlog
+ --master-data 以注释形式(=2时)将binlog的当前文件和position号记录下来.自动锁表
+ --single-transation 对于innodb进行快照备份,使所有表一致的dump出来在一个事务中.

## mysqldump的完整命令
```sh
mysqldump -uroot -p123 -A -triggers -R --master-data=2 --single-transation >/data/mysql/3306/backup/full.sql
```
