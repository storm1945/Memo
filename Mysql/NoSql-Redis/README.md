# Nosql产品简介
缓存产品介绍
+ memcached
性能很好,需要大量二次开发
+ redis 
大多数用的产品
+ Tair
由阿里开发,基于memcached
## Redis功能介绍
+ 数据类型丰富
+ 支持持久化
+ 多种内存分配回收策略
+ 支持事务
+ 消息队列,消息订阅(对比kafuka,缺点严重,简单应用可以)
+ 支持高可用
+ 支持分布式分片集群
+ 缓存穿透\雪崩
+ Redis API
## Redis和memcache对比
memcached 适合,多用户访问,每个用户少量的读写(多核实现,适合单机)\
redis 适合,少用户多访问,每个用户大量rw (单核设计,适合多实例)

memcached:\
优点:高性能读写,单一数据类型,支持客户端分布式集群,一致性hash\
多核结构,多线程读写性能高\
缺点: 无持久化,节点故障可能出现缓存穿透,分布式需要客户端实现,跨机房数据同步困难,

# redis的数据类型
## key通用操作
## string的操作
## hash操作
最接近sql表结构的数据类型.\
`hmset stu_1 id 1 name zs age 18 gender m`\
sql表->redis hash导入实例:
```sql
select concat("hmset t_",id ," id ", num ",num," k1 ",k1,"...) from t1000w where id<100 into outfile '/tmp/hsmset.txt';
```
```sh
cat /tmp/hmset.txt |redis-cli -a 123
```
## list操作
```sh
lpush wechet "today is 1"
lpush wechet "today is 2"
lpush wechet "today is 3"
lpush wechet "today is 4"
lrange wechet 0 -1
```
## set集合操作
案例:微博中,用户所有关注人存在一个集合中,将其所有粉丝存在一个集合,可以使用交集,并集,差集等操作.可以非常方便的实现如共同关注,共同爱好,二度好友.

```sh
sadd lxl pg1 baoqiang alexsb oldboy libao marong
sadd baoqiang jnl qiangge hedao bingbing baozhu oldguo
SUNION lxl jnl  #并集
SINTER lxl jnl  #交集
SDIFF lxl jnl   #差集
SDIFF jnl lxl   #差集
```
## SortedSet有序集合操作
排行榜应用,取top N操作\
```sh
zadd topn 0 fskl 0 lzlsfs 0 joifds 0 irei 0 iurewoi
ZREVRANGE topn 0 -1
ZINCRBY topn 1001 fskl
ZINCRBY topn 1031 lzlsfs
ZINCRBY topn 1301 joifds
ZINCRBY topn 3001 irei
ZINCRBY topn 3011 iurewoi
ZREVRANGE topn 0 -1 # 根据票数自动排序,不需要额外操作
```
# 消息订阅
生产-消费者模型\
```sh
SUBSCRIBE fm1039
SUBSCRIBE fm1039 fm1038
SUBSCRIBE fm*
PUBLISH fm1039 helloworld
```

# Redis事务
redis的事务是基于队列实现的\
和mysql的有区别,redis只是把操作送入队列没有执行,要执行exec才会开始做.mysql是已经做的了,要回滚.
```sh
multi
set a 1
set b 2
set aa 22
set bb 22
exec
```

# redis 主复制集
