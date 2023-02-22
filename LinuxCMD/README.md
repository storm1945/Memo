# 查询
## 查询文件
### 查看文件类型
file xxx
### 按文件名查找
`find / -name *mysql*`
### 树形目录
`tree -L 3 /data`
## 查询网络
### 查看网络连接
`ifconfig`
### 查看监听端口
`netstat -lnp|grep 330`
## 进程查询
`ps -ef|grep mysql`


# 文件操作
## 创建
### 创建整条路径
`mkdir -p /data/mysql/data`
### cat创建文本-代码块
```sh
cat >/data/mysql/3307/my.cnf <<EOF
[mysql]
socket=/var/lib/mysql/mysql.sock
EOF
```
### cat创建文本-键盘输入
```sh
cat >/data/mysql/3307/my.cnf
[mysql]
socket=/var/lib/mysql/mysql.sock
Ctrl+D结束输入
```
### 创建同类多个文件夹
`mkdir 330{6,7}`
## 删除
### 删除目录下所有文件
`rm -rf /data/mysql/3306/data/*`
## 修改
### 修改整个目录所有者
`chown -R mysql.mysql /data/*`
### cat追加字符
⭐>>输出重定向,表示追加;>输出表示覆盖;<输入符
```sh
cat >>/data/mysql/3307/my.cnf <<EOF
[mysql]
socket=/var/lib/mysql/mysql.sock
EOF
```
# 系统管理
## rpm -ivh xxxx.rpm
安装rpm
# VIM
## 退出
保存退出`:wq`\
不保存退出`':q!'`
## 光标移动
移动到文本开头 `gg`
移动到末行`G`
## 删除
删除行 `dd`
# 系统
## 远程登录
`ssh root@150.158.138.78`
## 启动服务 systemD方式
`systemctl start/stop/enable/disable/status mysqld`
## 进程管理
`pkill mysqld`

# 安装包
## sz命令 
`yum install lrzsz -y`
