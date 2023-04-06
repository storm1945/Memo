# 安装
## 官网下载
+ mongodb-mongosh shell程序
+ mongodb-org-mongos 主程序
+ mongodb-org-server 守护程序

`yum install mongodb-org-server-6.0.5-1.el7.x86_64`
## 关闭 Transparent Huge Pages (THP)
在vi /etc/rc.local最后添加如下代码:
```sh
if test -f /sys/kernel/mm/transparent_hugepage/enabled; then
  echo never > /sys/kernel/mm/transparent_hugepage/enabled
fi
if test -f /sys/kernel/mm/transparent_hugepage/defrag; then
   echo never > /sys/kernel/mm/transparent_hugepage/defrag
fi
```
## 查看安装位置
`whereis mongod'
`systemctl status mongod'

## 配置文件
`vim /etc/mongod.conf'
```sh
-- 进程控制  
processManagement:
   fork: true                         --后台守护进程
```
务必添加fork后台运行，否则systemctl可能会卡死



    