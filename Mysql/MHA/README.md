# 主从架构演变
## 基础架构
+ 一主一从
+ 一主多从
+ 双主结构
+ 多级主从
+ 循环复制
+ MGR (主流)
## 高级架构演变(需要第三方软件)
+ 高可用构架\
  单活: KA+2主+从(MMM),MHA(三节点,1主2从),TMHA(1主1从)\
  多活: NDB Cluster,InnoDB cluster,PXC(Percona XtraDB Cluster), MGC(MariaDB Galera Cluster)
+ 高性能构架
  - 读写分离架构:Atlas(360),Cobar,ProxySQL(Percona),MySQL Router(Oracle),Maxscale,Mycat
  - 分布式架构:Mycat,Atlas-Sharding(360),TDDL(淘宝),InnoDB cluster

# MHA高可用构架
## 原理介绍
### 功能
+ 监控节点\
    系统,网络,SSH连接性\
    监控主从状态,重点是主库
+ 如果主库宕机\
    选从库替代主库,对比从库,选择最接近主库的从库.
### 主库宕机处理过程
1. 监控节点 (通过配置文件获取所有节点信息)\
   系统,网络,SSH连接性\
   主从状态,重点是主库
2. 选主
  + 如果判断从库(position或者GTID),数据有差异,最接近于Master的slave,成为备选主
  + 如果判断从库(position或者GTID),数据一致,按照配置文件顺序,选主.
  + 如果设定有权重(candidate_master=1),按照权重强制指定备选主.
    - 默认情况下如果一个slave落后master 100M的relay logs的话，即使有权重,也会失效.
    - 如果check_repl_delay=0的化,即使落后很多日志,也强制选择其为备选主
3. 数据补偿
  + 当SSH能连接,从库对比主库GTID 或者position号,立即将二进制日志保存至各个从节点并且应用(save_binary_logs )
  + 当SSH不能连接, 对比从库之间的relaylog的差异(apply_diff_relay_logs) 
4. Failover(切换)
    - 将备选主进行身份切换,对外提供服务
    - 其余从库和新主库确认新的主从关系
5. 应用透明(VIP)
6. 故障切换通知(send_reprt)
7. 二次数据补偿(binlog_server)

## 安装部署
### 软件架构
1主2从，master：db01 slave：db02 db03：\
MHA 高可用方案软件构成\
Manager软件：选择一个从节点安装\
Node软件：所有节点都要安装

Manager工具包主要包括以下几个工具：
+ masterha_manger             启动MHA 
+ masterha_check_ssh      检查MHA的SSH配置状况 
+ masterha_check_repl         检查MySQL复制状况 
+ masterha_master_monitor     检测master是否宕机 
+ masterha_check_status       检测当前MHA运行状态 
+ masterha_master_switch  控制故障转移（自动或者手动）
+ masterha_conf_host      添加或删除配置的server信息

Node工具包主要包括以下几个工具：\
这些工具通常由MHA Manager的脚本触发，无需人为操作
+ save_binary_logs            保存和复制master的二进制日志 
+ apply_diff_relay_logs       识别差异的中继日志事件并将其差异的事件应用于其他的
+ purge_relay_logs            清除中继日志（不会阻塞SQL线程）
### 软连接
MHA软件中硬编码的绝对路径: `/user/bin/`
```sh
ln -s /app/mysql/bin/mysqlbinlog /user/bin/mysqlbinlog
ln -s /app/mysql/bin/mysql /user/bin/mysql
```
### 配置互信
```sh
#db01：
rm -rf /root/.ssh 
ssh-keygen
cd /root/.ssh 
mv id_rsa.pub authorized_keys
# 当前节点配置另外两个
scp  -r  /root/.ssh  47.96.167.195:/root 
scp  -r  /root/.ssh  120.55.54.37:/root 
scp  -r  /root/.ssh  47.110.144.171:/root 
#scp  -r  /root/.ssh  150.158.138.78:/root 
#各节点验证
ssh 47.96.167.195 date
ssh 120.55.54.37 date
ssh 150.158.138.78 date
ssh 47.110.144.171 date
```
### 监控和节点安装
```sh
## manager
wget github.com/yoshinorim/mha4mysql-manager/releases/download/v0.58/mha4mysql-manager-0.58-0.el7.centos.noarch.rpm
yum install -y perl-Config-Tiny epel-release perl-Log-Dispatch perl-Parallel-ForkManager perl-Time-HiRes
rpm -ivh mha4mysql-manager-0.58-0.el7.centos.noarch.rpm
## node (!!!所有四个节点都要装,包括监控器)
wget github.com/yoshinorim/mha4mysql-node/releases/download/v0.58/mha4mysql-node-0.58-0.el7.centos.noarch.rpm
yum install perl-DBD-MySQL -y
rpm -ivh mha4mysql-node-0.58-0.el7.centos.noarch.rpm
```
### 在主库建立MHA用户
```sql
grant all privileges on *.* to mha@'%' identified by '123';
```
### 准备启动配置
```sh
#创建日志目录
mkdir -p /var/log/mha/app1
#编辑mha配置文件
cat >/etc/masterha_default.cnf<<EOF
[server default]
manager_log=/var/log/mha/app1/manager        
manager_workdir=/var/log/mha/app1            
master_binlog_dir=/data/mysql/3306/log       
user=mha                                   
password=123                               
ping_interval=2
repl_password=123
repl_user=repl
ssh_user=root                               
[server1]                                   
hostname=150.158.138.78
port=3306                                  
[server2]            
hostname=47.96.167.195
port=3306
[server3]
hostname=120.55.54.37
port=3306
EOF
```
### 检查准备状态
```sh
#检查互信
masterha_check_ssh --conf=/etc/masterha_default.cnf
#检查主从状态
masterha_check_repl --conf=/etc/masterha_default.cnf
```
### 开启监控
```sh
nohup masterha_manager --conf=/etc/masterha_default.cnf --remove_dead_master_conf --ignore_last_failover  < /dev/null> /var/log/mha/app1/manager.log 2>&1 &
```
### 查看启动状态
```sh
masterha_check_status --conf=/etc/masterha_default.cnf
```
## 故障模拟及修复
模拟主机宕机 pkill mysqld,MHA会切换主机到从机节点,并把该从机该为主节点,并使另外一节点作为他的从机,并在cnf文件中删除有问题的节点.并关闭MHA\
修复方法:修复数据库,恢复主从结构,加入配置文件,重启MHA
## MHA的VIP功能(应用程序透明服务)(监控节点添加)
### 准备脚本文件
master_ip_failover为第三方脚本,自行下载,有些不能运行,配置好以后可以使用`masterha_check_repl --conf=/etc/masterha_default.cnf`查看是否好用.
```sh
cd /usr/local/bin/
chmod 755 master_ip_failover
dos2unix master_ip_failover
# !!! 需要转换否则脚本文件字符出错
```
修改其中的
```sh
vim /usr/local/bin/master_ip_failover
# 主库的eth0 IP ,需要在同一个号段,主库虚拟对外服务的IP./24是掩码位数8*3=24位
my $vip = '10.0.4/24';
my $key = '1';
my $ssh_start_vip = "/sbin/ifconfig eth0:$key $vip";
my $ssh_stop_vip = "/sbin/ifconfig eth0:$key down";
# 建立临时子网卡 例如eth0:1 ,地址需要跟主网路一个IP段
```
### 添加配置文件
```sh
vim /etc/masterha_default.cnf
[server default]
master_ip_failover_script=/usr/local/bin/master_ip_failover
```
### 主库手动生成虚拟子网卡
因为该脚本在发生故障的时候才会被调用,第一次启动需要手动配置主库子网卡eth0:1\
```sh
ifconfig eth0:1 10.0.4.20/24
```
### 重启manager
```sh
masterha_stop --conf=/etc/masterha_default.cnf
nohup masterha_manager --conf=/etc/masterha_default.cnf --remove_dead_master_conf --ignore_last_failover  < /dev/null> /var/log/mha/app1/manager.log 2>&1 &
```
### 测试
当down掉主机的数据库实例时,可以观察到在从机的网卡上出现`eth0:1 10.0.4.20/24`,代表业务已经切到从机上.其他步骤同普通切换过程.

## 警告发送
略

## Binlog server配置
### 介绍
配置一个单独的机器与主机binlog 同步,用于主机宕机时修复从机的数据.
### 配置
binlogserver配置：\
找一台额外的机器，必须要有5.6以上的版本，支持gtid并开启
```sh
vim /etc/mha/app1.cnf 
[binlog1]
no_master=1
hostname=10.0.0.53
master_binlog_dir=/data/mysql/binlog
### !!!这里的master_binlog_dir一定要和主机的master binlog不同.
```
目录建立: \
```sh
mkdir -p /data/mysql/binlog
chown -R mysql.mysql /data/*
```
修改完成后，将主库binlog拉过来（从000001开始拉，之后的binlog会自动按顺序过来）\
```sh
# !!!必须进入到自己创建好的目录
cd /data/mysql/binlog     
mysqlbinlog  -R --host=10.0.0.52 --user=mha --password=mha --raw  --stop-never mysql-bin.000001 &
# !!!开始持续拉取主机binlog,注意选择合适的binlog起点.拉取日志的起点,需要按照目前从库的已经获取到的二进制日志点为起点
```
### 故障处理过程
当MHA执行基于GTID的故障转移时，MHA会先检查binlog服务器，如果binlog server记录的BINLOG在其他从属服务器之前，MHA在恢复之前将来自binlog server的差异binlog event应用到新master，如果没有binlogserver，使用gtid的情况下将不会去主库拉取差异日志。
