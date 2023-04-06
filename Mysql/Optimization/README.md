# 优化简介
## 存储.主机.操作系统
+ 主机构架稳定性
+ IO规划及配置
+ Swap
+ OS内核参数
+ 网络问题
## 应用程序(Index,lock,session)
+ 应用程序稳定性和性能
+ sql语句性能
+ 串行访问资源
+ 性能欠佳的会话管理
## 数据库优化(内存,数据库设计,参数)
+ 内存
+ 数据库结构(物理和逻辑)
+ 实例配置

## 优化层次
1. 硬件层
2. 操作系统层
3. 文件系统层
4. 数据库实例层数
5. Schema设计
6. SQL优化
7. 构架

# 优化工具
## 系统层面
### CPU
`top`命令
关注CPU,内存,swap
```
%Cpu(s):  0.0 us,  0.0 sy,  0.0 ni,100.0 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
KiB Mem :  1881980 total,    87596 free,   805132 used,   989252 buff/cache
KiB Swap:        0 total,        0 free,        0 used.   908580 avail Mem 

  PID USER      PR  NI    VIRT    RES    SHR S %CPU %MEM     TIME+ COMMAND                
  829 root      20   0  573920  18348   5244 S  0.3  1.0   1:30.33 tuned                  
    1 root      20   0  125460   3736   2416 S  0.0  0.2   0:10.37 systemd                
    2 root      20   0       0      0      0 S  0.0  0.0   0:00.01 kthreadd               
    3 root      20   0       0      0      0 S  0.0  0.0   0:00.29 ksoftirqd/0            
```
主要关心用户态占比,内核态占比超过百分之10说明有些问题,可以考虑是锁的问题,wa指的是平均等待时间也不应该过高.
### MEM
+ total 总的物理内存量
+ avail Mem tempFS文件系统要占掉一部分内存,这部分也可以被用户程序使用
+ buff/cache buffer主要是写操作,例如undo redo日志,需要进行磁盘写入后方可释放.cache是读操作随时可以释放.
+ swap 应该尽量避免,swap高了以后说明内存不足,一般sql服务器直接设置为零,在配置文件`/etc/sysctl.conf`里面添加`vm.swappiness=0`
## IO 
`iostat`命令查看 IO\
现象说明\
+ IO高 cpu us也高,属于正常现象
+ CPU us高 IO很低,当Mysql不在增删改查的话,可能是存储过程,函数,排序,分组,多表连接
+ wait高,IO低:IO出问题了,锁等待的几率比较大
+ IOPS 每秒磁盘最多能够发生的IO次数,这是个定值
频繁小事务,IOPS很高,达到阈值,可能IO吞吐量没超过IO最大吞吐量,无法进行新的IO
案例:存储规划多次条带化,将1.5m的数据拆成N多份写入磁盘,造成频繁IO超过IOPS上限.

## sql内部监控
    + show status  
    + show variables 
    + show index  
    + show processlist 
    + show slave status
    + show engine innodb status 
    + desc /explain 
    + slowlog

    扩展类深度优化:
    + pt系列
    + mysqlslap 
    + sysbench 
    + information_schema 
    + performance_schema
    + sys

# 优化
## 主机
+ 真实的硬件（PC Server）: DELL  R系列 ，华为，浪潮，HP，联想
+ 云产品：ECS、数据库RDS、DRDS
+ IBM 小型机 P6  570  595   P7 720  750 780     P8 
## CPU根据数据库类型
+ OLTP 
+ OLAP  
+ IO密集型：线上系统，OLTP主要是IO密集型的业务，高并发
+ CPU密集型：数据分析数据处理，OLAP，cpu密集型的，需要CPU高计算能力（i系列，IBM power系列）
+ CPU密集型： I 系列的，主频很高，核心少 
+ IO密集型：  E系列（至强），主频相对低，核心数量多
内存 2-4倍核心数量\
