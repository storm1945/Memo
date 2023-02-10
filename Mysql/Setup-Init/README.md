## 官方源安装
1. 查看是否存在其他版本`yum list installed | grep mysql`
2. 访问[MySQL Yum Repository](https://docs.oracle.com/cd/E17952_01/mysql-5.7-en/linux-installation-yum-repo.html)获得官方yum源并下载
3. `yum localinstall mysql80-community-release-el7-7.noarch.rpm`
4. 查看源是否正常安装`yum repolist all | grep mysql`
5. 选择版本
```sh
yum-config-manager --disable mysql80-community
yum-config-manager --enable mysql57-community
```
6. 安装`yum install mysql-community-server`\
7. 启动
```sh
systemctl start mysqld.service
systemctl status mysqld.service
```
参考 [Installing MySQL on Linux Using the MySQL Yum Repository](https://docs.oracle.com/cd/E17952_01/mysql-5.7-en/linux-installation-yum-repo.html#yum-repo-installing-mysql)
## 解压安装
```sh
mkdir -p /application/mysql
tar xf 文件名.tar
```
## 创建用户
```sh
useradd -s /sbin/nologin mysql
id mysql
```
## 修改环境变量
`vi /etc/profile`\
添加 `export PATH=/application/mysql/bin:$PATH`

## 解决依赖
```sh
find / -name 'libncurses*
ln -s libncurses.so.6 libncurses.so.5
ln -s libtinfo.so.6 libtinfo.so.5
```

## 查看版本
`mysql -V`

## 挂载磁盘
```sh
mkfs.xfs /dev/sdb
mkdir /data
blkid
vim /etc/fstab
UUID="a374d1b0-d552-404a-ae26-22af3cc23a3e" /data xfs defaults 0 0
mount -a
df -h
```

## 授权
```sh
chown -R mysql.mysql /application/*
chown -R mysql.mysql /data
```

## 创建初始数据
```sh
whereis mysql
mkdir /data/mysql/data -p 
chown -R mysql.mysql /data 
mysqld --initialize --user=mysql --basedir=/usr/bin/mysql --datadir=/data/mysql/data
```
临时密码 y/CS_WX%3a0n

## 无安全密码初始化
```sh
whereis mysql
rm -rf /data/mysql/3306*
mysqld --initialize-insecure --user=mysql --basedir=/usr/bin/mysql --datadir=/data/mysql/3306
```
## 启动配置
```ini
cat >/etc/my.cnf <<EOF
[mysqld]
user=mysql
basedir=/usr/bin/mysql
datadir=/data/mysql/3306
socket=/var/lib/mysql/mysql.sock
server_id=6
port=3306
[mysql]
socket=/var/lib/mysql/mysql.sock
EOF
```

## 启动数据库(sys-v 旧方式)
```sh
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
`mysql -uroot -p -S /var/lib/mysql/mysql.sock`
## 显示连接用户
`show processlist;`
## 使用SQLyog工具连接
防火墙打开对应端口,以及用户名后白名单\
防火墙状态
```sh
systemctl status firewalld.service
firewall-cmd --zone=public --add-port=3306/tcp --permanent
systemctl restart firewalld.service
firewall-cmd --zone=public --list-ports
```
## 启动维护模式
`mysqld_safe &`
- 关闭维护模式\
`mysqladmin -uroot -p123 shutdown`
- 修改权限使用sqlyog进行连接
```sql
use mysql;
show tables;
select Host, User from user;
update user set Host='%' where User='root';
flush privileges;
```
修复报错 `mysql> authentication plugin 'caching_sha2_password' cannot be loaded;`\
原因:mysql8.0 引入了新特性 caching_sha2_password,这种密码加密方式客户端不支持,客户端支持的是mysql_native_password 这种加密方式.\
措施:`ALTER USER 'root'@'%' IDENTIFIED WITH mysql_native_password BY '密码';`\
参考:[mysql错误：mysql_native_password](https://blog.csdn.net/qq_43395428/article/details/104795256)
## 自启动
```sh
cd /etc/rc.d/
chmod 755 rc.local
vi rc.local
```
添加`service mysqld start`
## 多实例配置