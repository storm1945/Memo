#! /bin/bash
wget https://dev.mysql.com/get/mysql80-community-release-el7-7.noarch.rpm
yum localinstall -y mysql80-community-release-el7-7.noarch.rpm 
sh ini-rw.sh /etc/yum.repos.d/mysql-community.repo mysql57-community enabled 1
sh ini-rw.sh /etc/yum.repos.d/mysql-community.repo mysql80-community enabled 0
yum install -y mysql-community-server
if ! cut -d: -f1 /etc/passwd | grep -q -w "mysql"; then
useradd -s /sbin/nologin mysql
fi
#---------------
cat >/etc/my.cnf<<EOF
[mysqld]
datadir=/data/mysql/3306/data
socket=/var/lib/mysql/mysql.sock
pid-file=/var/run/mysqld/mysqld.pid
port=3306
server_id=9

log-error=/data/mysql/3306/log/mysqld-3306.log

slow_query_log=1
slow_query_log_file=/data/mysql/3306/log/slow.log
long_query_time=0.1
log_queries_not_using_indexes

log_bin=/data/mysql/3306/log/mysql_bin
binlog_format=row
expire_logs_days=15
gtid-mode=on
enforce-gtid-consistency=true

autocommit=0
EOF
#---------------
mkdir -p /data/mysql/{3306,3307}/{log,data,backup}
chown -R mysql.mysql /data/mysql
mysqld --initialize-insecure --user=mysql --basedir=/usr/bin/mysql --datadir=/data/mysql/3306/data
#mysqld --initialize-insecure --user=mysql --basedir=/usr/bin/mysql --datadir=/data/mysql/3307/data
systemctl start mysqld