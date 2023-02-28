#! /bin/bash
# get_value_by_key cnf-filepath key value

# file_key file_sec file_line_num
function anaylize_config_file(){
#得到区块数组
local g_sec=(`sed -n '/\[*\]/p' $1 |grep -v '^#'|tr -d []`)
local g_sec_num=(`sed -n '/\[*\]/p' $1 |grep -v '^#'|awk '{print NR}'`)
#sed -n '/\[*\]/p' 得到包含[*]的行
#grep -v '^#' 去掉#打头的行
#tr -d [] 去掉[]
#g_sec=(client mysqld mysqld_safe)

local i=0 j=0 k=0
for ((i=0;i<${#g_sec[@]};i++))
do
local g_names=(`sed -n '/\['${g_sec[i]}'\]/,/\[/p' $1|grep -Ev '\[|\]|^$|^#'|awk -F '=' '{print $1}'`)
#sed -n '/\['${g_sec[i]}'\]/,/\[/p' 得到从[${g_sec[i]}]到临近[的所有行
#grep -Ev '\[|\]|^$|^#' 去掉包含[或]的行 去掉空行 去掉#打头的行
#awk -F '=' '{print $1}'`得到=号前面字符
local g_values=(`sed -n '/\['${g_sec[i]}'\]/,/\[/p' $1|grep -Ev '\[|\]|^$|^#'|awk -F '=' '{print $2}'`)
local g_line_num=(`sed -n '/\['${g_sec[i]}'\]/,/\[/p' $1|grep -Ev '\[|\]|^$|^#'|awk '{print NR}'`)
#awk -F '=' '{print $1}'`得到=号后面字符
	for ((j=0;j<${#g_names[@]};j++))
	do
	echo ${g_names[$j]}" "${g_values[$j]}" "`expr ${g_line_num[$j]} + ${g_sec_num[i]}`
	done
done
}
anaylize_config_file "/etc/my.cnf"

mkdir /downloads
cd downloads
wget https://dev.mysql.com/get/mysql80-community-release-el7-7.noarch.rpm
if [ ! -e "/downloads/mysql80-community-release-el7-7.noarch.rpm"]
	exit
fi
yum localinstall -y mysql80-community-release-el7-7.noarch.rpm
vim /etc/yum.repos.d/mysql-community.repo
yum install -y mysql-community-server
useradd -s /sbin/nologin mysql
