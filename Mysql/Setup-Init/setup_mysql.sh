#! /bin/bash
# get_value_by_key cnf-filepath key value

# file_key file_sec file_line_num
function anaylize_config_file(){
	local filepath=$1
	#得到区块数组
	local g_sec=(`sed -n '/\[*\]/p' $filepath |grep -v '^#'|tr -d []`)
	#sed -n '/\[*\]/p' 得到包含[*]的行
	#grep -v '^#' 去掉#打头的行
	#tr -d [] 去掉[]
	#g_sec=(client mysqld mysqld_safe)
	local i=0 j=0 k=0
	for ((i=0;i<${#g_sec[@]};i++))
	do
		then
			local sec_name=${g_sec[i]}
			local k_key=(`sed -n '/\['$sec_name'\]/,/\[/p' $cnf|grep -Ev '\[|\]|^$|^#'|awk -F '=' '{print $1}'`)
			#sed -n '/\['$sec_name'\]/,/\[/p' 得到从[$sec_name]到临近[的所有行
			#grep -Ev '\[|\]|^$|^#' 去掉包含[或]的行 去掉空行 去掉#打头的行
			#awk -F '=' '{print $1}'`得到=号前面字符
			local k_value=(`sed -n '/\['$sec_name'\]/,/\[/p' $cnf|grep -Ev '\[|\]|^$|^#'|awk -F '=' '{print $2}'`)
			#awk -F '=' '{print $1}'`得到=号后面字符
			for ((j=0;j<${#k_key[@]};j++))
			do	
				file_key[k]=sec_name
				file_sec[k]=k_value[j]
				k++
			done
	done
}
function get_value_by_key(){


}


}
	if [ ${g_sec[i]} == "mysql57-community" ] 
	elif  [ ${g_sec[i]} == "mysql80-community" ]
	then
	fi
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
