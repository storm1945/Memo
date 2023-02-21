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

# 部署MHA高可用构架
## 软连接
MHA软件中硬编码的绝对路径: `/user/bin/`
```sh
ln -s /app/mysql/bin/mysqlbinlog /user/bin/mysqlbinlog
ln -s /app/mysql/bin/mysql /user/bin/mysql
```

## 配置互信 