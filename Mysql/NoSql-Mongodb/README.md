# 安装
## 官网下载
+ mongodb-mongosh shell程序
+ mongodb-org-mongos 主程序
+ mongodb-org-server 守护程序

`yum install mongodb-org-server-6.0.5-1.el7.x86_64`
## 关闭 Transparent Huge Pages (THP)
在vi /etc/rc.local最后添加如下代码:
```sh
if test -f /sys/kernel/mm/transparent_hugepage/enabled; then
  echo never > /sys/kernel/mm/transparent_hugepage/enabled
fi
if test -f /sys/kernel/mm/transparent_hugepage/defrag; then
   echo never > /sys/kernel/mm/transparent_hugepage/defrag
fi
```
## 查看安装位置
`whereis mongod'
`systemctl status mongod'

## 配置文件
`vim /etc/mongod.conf'
```sh
-- 进程控制  
processManagement:
   fork: true                         --后台守护进程
```
务必添加fork后台运行，否则systemctl可能会卡死

# Mongodb使用
## 查看命令
```
show databases;
show tables;
use db;
```
## 操作命令
### db类
```
db.help()
db.dropDatabase()
use oldboy; --创建命令
```
### 表命令
表命令，也可以不用建表
```sql
db.createCollection('tb')
db.tb.help()
db.tb.drop()

db.tb.insertOne({id:101,name:"wmz",age:18})
db.tb.insertOne({name:"wmz",age:18,id:101,gender:"M"})

db.tb.find()
db.tb.find().pretty()
db.tb.find({id:101})
db.tb.countDocuments()

for(i=0;i<100;i++){db.tb.insertOne({id:i,name:"wmz",age:18,data:new Date()})}
```
### rs复制集命令
rs.help()

# 用户权限管理
## 管理员
+ 必须在admin库下创建
+ 建用户时，use到的库，就是此用户的验证库
+ 登录时，必须要指定验证库才能登陆
+ 如果直接登录到数据库,不进行use,默认的验证库是test,不是我们生产建议的
+ 不添加bindIp参数,默认不让远程登录,只能本地管理员登录

## 用户创建的语法
```
use admin 
db.createUser
{
    user: "<name>",
    pwd: "<cleartext password>",
    roles: [
       { role: "<role>",
     db: "<database>" } | "<role>",
    ...
    ]
}
```
基本语法说明：\
pwd:密码\
roles:\
    role:角色名\
    db:作用对象 \
role：root, readWrite,read   \
验证数据库：\
mongo -u oldboy -p 123 10.0.0.53/oldboy

### 创建超级管理员
```
use admin
db.createUser(
{
    user: "root",
    pwd: "root123",
    roles: [ { role: "root", db: "admin" } ]
}
)
```
### 验证用户
```
use admin
db.auth('root','root123')
```
或者在登录时指定用户:
```
mongo -uroot -proot123  admin
mongo -uroot -proot123  10.0.0.53/admin
```
### 配置文件中开启用户验证
```
security:
  authorization: enabled
```
### 查看用户
```
use admin
db.system.users.find().pretty()
```
### 创建应用用户
```
use oldboy
db.createUser(
    {
        user: "app01",
        pwd: "app01",
        roles: [ { role: "readWrite" , db: "oldboy" } ]
    }
)

mongo  -uapp01 -papp01 app
```
### 删除用户
```
db.createUser({user: "app02",pwd: "app02",roles: [ { role: "readWrite" , db: "oldboy1" } ]})
mongo -uroot -proot123 10.0.0.53/admin
use oldboy1
db.dropUser("app02")
```
### 用户管理注意事项
1. 建用户要有验证库，管理员admin，普通用户是要管理的库
2. 登录时，注意验证库
`mongo -uapp01 -papp01 10.0.0.51:27017/oldboy`
3. 重点参数
```
net:
   port: 27017
   bindIp: 10.0.0.51,127.0.0.1
security:
   authorization: enabled
```
## mongodb复制集RS(ReplicationSet)
### 基本原理
基本构成是1主2从的结构，自带互相监控投票机制（Raft（MongoDB）  Paxos（mysql MGR 用的是变种））\
如果发生主库宕机，复制集内部会进行投票选举，选择一个新的主库替代原有主库对外提供服务。同时复制集会自动通知\
客户端程序，主库已经发生切换了。应用就会连接到新的主库。\
### 配置多实例
使用附件中.sh文件
### 配置普通复制集
```c
mongosh --port 28018 admin
config = {_id: 'my_repl', members: [
                          {_id: 0, host: '127.0.0.1:28018'},
                          {_id: 1, host: '127.0.0.1:28019'},
                          {_id: 2, host: '127.0.0.1:28020'}]
          }                   
rs.initiate(config) 
```
### 1主1从1个arbiter
```c
mongosh --port 28018 admin
config = {_id: 'my_repl', members: [    //创建变量config，送到下面进行初始化
                          {_id: 0, host: '127.0.0.1:28018'},
                          {_id: 1, host: '127.0.0.1:28019'},
                          {_id: 2, host: '127.0.0.1:28020',"arbiterOnly":true}]
          }                   
rs.initiate(config) 
```
### 复制集管理操作
```c
rs.status();    //查看整体复制集状态
rs.isMaster(); // 查看当前是否是主节点
rs.conf()；   //查看复制集配置信息
```
### 添加删除节点
```c
rs.remove("ip:port"); // 删除一个节点
rs.add("ip:port"); // 新增从节点
rs.addArb("ip:port"); // 新增仲裁节点
```

例子：\
添加 arbiter节点\
1. 连接到主节点
[mongod@db03 ~]$ mongo --port 28018 admin
2. 添加仲裁节点
my_repl:PRIMARY> rs.addArb("127.0.0.1:28020")
3. 查看节点状态
```c 
my_repl:PRIMARY> rs.isMaster()
{
    "hosts" : [
        "10.0.0.53:28017",
        "10.0.0.53:28018",
        "10.0.0.53:28019"
    ],
    "arbiters" : [
        "10.0.0.53:28020"
    ],
}
rs.remove("ip:port"); // 删除一个节点
```
例子：
```c 
my_repl:PRIMARY> rs.remove("10.0.0.53:28019");
{ "ok" : 1 }
my_repl:PRIMARY> rs.isMaster()
rs.add("ip:port"); // 新增从节点
```
例子：
```c 
my_repl:PRIMARY> rs.add("10.0.0.53:28019")
{ "ok" : 1 }
my_repl:PRIMARY> rs.isMaster()
```

### 特殊节点
+ arbiter节点：主要负责选主过程中的投票，但是不存储任何数据，也不提供任何服务
+ hidden节点：隐藏节点，不参与选主，也不对外提供服务。
+ delay节点：延时节点，数据落后于主库一段时间，因为数据是延时的，也不应该提供服务或参与选主，所以通常会配合hidden（隐藏）
一般情况下会将delay+hidden一起配置使用

配置:
```c
cfg=rs.conf() 
cfg.members[2].priority=0
cfg.members[2].hidden=true
cfg.members[2].slaveDelay=120
rs.reconfig(cfg)   
```
### 副本集其他命令

```c
rs.conf() //查看副本集的配置信息
rs.status() //查看副本集各成员的状态
rs.stepDown() //副本集角色切换（不要人为随便操作）
rs.freeze(300) //锁定从，使其不会转变成主库
rs.slaveOk()//设置副本节点可读：在副本节点执行
```
查看副本节点（监控主从延时）
```c
admin> rs.printSlaveReplicationInfo()
source: 192.168.1.22:27017
    syncedTo: Thu May 26 2016 10:28:56 GMT+0800 (CST)
    0 secs (0 hrs) behind the primary
```

# MongoDB Sharding Cluster 分片集群
## 规划
10个实例：38017-38026
1. configserver:38018-38020 (管理分片配置)
3台构成的复制集（1主两从，不支持arbiter）38018-38020（复制集名字configsvr）
2. shard节点：
sh1：38021-23    （1主两从，其中一个节点为arbiter，复制集名字sh1）
sh2：38024-26    （1主两从，其中一个节点为arbiter，复制集名字sh2）
3. mongos: (对外提供的节点,路由功能)
38017
## shard节点创建
配置文件中,添加:
```c
replication:
  oplogSizeMB: 2048
  replSetName: sh1
sharding:
  clusterRole: shardsvr
```