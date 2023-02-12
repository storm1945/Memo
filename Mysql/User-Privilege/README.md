## 用户定义
用户名@'白名单'
例:
```sql
wordpress@'%'
wordpress@'localhost'
wordpress@'127.0.0.1'
wordpress@'10.0.0.%'
wordpress@'10.0.0.5%'
wordpress@'10.0.0.0/255.255.254.0'
```

## 建立用户
赋予权限
```sql
create user oldboy@'%' identified by '123';
grant all on *.* to oldboy@'%';
```
(`*.*` 指那些数据库，表)\
(all 也可以 SELECT，DELETE，INSERT，UPDATE等)

撤销权限:
```sql
revoke DELETE on *.* from oldboy@'%';
show grants for oldboy@'%';
```

## 修改密码
```sql
alter user oldboy@'%' identified by '1234';
alter user root@'%' identified by '';
```

## 修改权限域
出现 `Access denied for user 'root'@'%' to database 'information_schema'`
```sql
UPDATE mysql.user SET Grant_priv='Y', Super_priv='Y' WHERE User='root';
flush privileges;
```