#! /bin/bash
mkdir /downloads
cd downloads
wget https://dev.mysql.com/get/mysql80-community-release-el7-7.noarch.rpm
if [ ! -e "/downloads/mysql80-community-release-el7-7.noarch.rpm"]
	exit
fi
yum localinstall -y mysql80-community-release-el7-7.noarch.rpm

cnf="/etc/my.cnf"
#得到区块数组
g_sec=(`sed -n '/\[*\]/p' $cnf |grep -v '^#'|tr -d []`)
#sed -n '/\[*\]/p' 得到包含[*]的行
#grep -v '^#' 去掉#打头的行
#tr -d [] 去掉[]
#g_sec=(client mysqld mysqld_safe)

for ((i=0;i<${#g_sec[@]};i++))
do
	if [ ${g_sec[i]} == "mysql57-community" ] 
	then
		sec_name=${g_sec[i]}
		g_names=(`sed -n '/\['$sec_name'\]/,/\[/p' $cnf|grep -Ev '\[|\]|^$|^#'|awk -F '=' '{print $1}'`)
		#sed -n '/\['$sec_name'\]/,/\[/p' 得到从[$sec_name]到临近[的所有行
		#grep -Ev '\[|\]|^$|^#' 去掉包含[或]的行 去掉空行 去掉#打头的行
		#awk -F '=' '{print $1}'`得到=号前面字符

		g_values=(`sed -n '/\['$sec_name'\]/,/\[/p' $cnf|grep -Ev '\[|\]|^$|^#'|awk -F '=' '{print $2}'`)
		#awk -F '=' '{print $1}'`得到=号后面字符
		
		for ((j=0;j<${#g_names[@]};j++))
		do
			echo ${g_names[$j]}" "${g_values[$j]}
		done
	elif  [ ${g_sec[i]} == "mysql80-community" ]
	then
		
	fi
done
vim /etc/yum.repos.d/mysql-community.repo
yum install -y mysql-community-server
useradd -s /sbin/nologin mysql
