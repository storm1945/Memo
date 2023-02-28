#! /bin/bash
wget https://dev.mysql.com/get/mysql80-community-release-el7-7.noarch.rpm
if [ ! -e "/downloads/mysql80-community-release-el7-7.noarch.rpm"]
	exit 0
fi
yum localinstall -y mysql80-community-release-el7-7.noarch.rpm

yum install -y mysql-community-server
useradd -s /sbin/nologin mysql
