#! /bin/bash
wget https://dev.mysql.com/get/mysql80-community-release-el7-7.noarch.rpm
if [ ! -e "/downloads/mysql80-community-release-el7-7.noarch.rpm"]
	exit 0
fi
yum localinstall -y mysql80-community-release-el7-7.noarch.rpm 
sh ini-rw.sh /etc/yum.repos.d/mysql-community.repo mysql57-community enabled 1
sh ini-rw.sh /etc/yum.repos.d/mysql-community.repo mysql80-community enabled 0
yum install -y mysql-community-server
useradd -s /sbin/nologin mysql
