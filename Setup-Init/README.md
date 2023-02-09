## 解压
```
mkdir -p /application/mysql
tar xf 文件名.tar
```
## 创建用户
```
useradd -s /sbin/nologin mysql
id mysql
```
## 修改环境变量
`vi /etc/profile`\
添加 `export PATH=/application/mysql/bin:$PATH`

## 解决依赖
```
find / -name 'libncurses*
ln -s libncurses.so.6 libncurses.so.5
ln -s libtinfo.so.6 libtinfo.so.5
```

## 查看版本
`mysql -V`

## 挂载磁盘
```
mkfs.xfs /dev/sdb
mkdir /data
blkid
vim /etc/fstab
UUID="a374d1b0-d552-404a-ae26-22af3cc23a3e" /data xfs defaults 0 0
mount -a
df -h
```

## 授权
```
chown -R mysql.mysql /application/*
chown -R mysql.mysql /data
```

## 创建初始数据
```
mkdir /data/mysql/data -p 
chown -R mysql.mysql /data 
mysqld --initialize --user=mysql --basedir=/application/mysql --datadir=/data/mysql/data
```
临时密码 y/CS_WX%3a0n

## 无安全密码初始化
```
rm -rf /data/mysql/data/*
mysqld --initialize-insecure --user=mysql --basedir=/application/mysql --datadir=/data/mysql/data
```
## 启动配置
```
cat >/etc/my.cnf <<EOF
[mysqld]
user=mysql
basedir=/application/mysql
datadir=/data/mysql/data
socket=/tmp/mysql.sock
server_id=6
port=3306
[mysql]
socket=/tmp/mysql.sock
EOF
```

## 启动数据库(sys-v)
```
cp /application/mysql/support-files/mysql.server /etc/init.d/mysqld
service mysqld start
ps -ef |grep mysql
netstat -lnp|grep 330
```

## 修改密码
`mysqladmin -uroot -p password oldboy123`

## 登录
- 登录 TCPIP方式\
`mysql -uroot -p -h 10.0.0.3 -P3306`
- 登陆 SOCKET方式\
`mysql -uroot -p -S /tmp/mysql.sock`

## 显示连接用户
`show processlist;`

使用SQLyog工具连接
注意关闭防火墙
以及用户名后白名单

启动维护模式
mysqld_safe &
关闭维护模式
mysqladmin -uroot -p123 shutdown

修改权限使用sqllog进行连接
use mysql;
show tables;
select Host, User from user;
update user set Host='%' where User='root';
flush privileges;

ALTER USER 'root'@'%' IDENTIFIED WITH mysql_native_password BY 'password';
password是密码

防火墙状态
systemctl status firewalld.service
firewall-cmd --zone=public --add-port=3306/tcp --permanent
systemctl restart firewalld.service
firewall-cmd --zone=public --list-ports

自启动:
cd /etc/rc.d/
chmod 755 rc.local
vi rc.local
添加service mysqld start