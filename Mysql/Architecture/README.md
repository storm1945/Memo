## 实例:
一个实例=mysql的守护进程+Master Thread(主线程)+工作Thread(工作线程)+预分配的内存空间

SQL语句的引入:
结构化查询语言 DQL DDL DML DCL (query,define,manipulate,control)

## 三个层次:连接层,SQL语句处理层,存储引擎层
![三个层次](Mysql\Architecture\layers.jpeg "三个层次")

连接层 两种协议 socket，tcpip
1. 提供链接协议
2. 验证用户密码ip合法性
3. 开启链接线程
4. 交给下一层

SQL层
1. 接受语句
2. 语法检查
3. 语义和权限检查
4. 解析语句，生成多种计划
5. 优化算法（预执行，评估代价）
6. 选择最优算法

存储引擎：\
执行SQL找到相应数据，返回SQL层，结构化成二维表，返回连接层，返回数据。

## 逻辑存储结构:
```sql
create database wordpress charset utf8mb4;
/*utf8bm4才是真正的unicode utf8,相当于mkdir /wordpress，在data下建立文件夹相当于建立数据库*/
show databases;
use wordpress;
```
数据库的逻辑结构\
库：\
库名字\
库属性：字符集，排序规则\
字符集: `show charset;`

表：\
表名\
表属性：存储引擎类型，字符集，排序规则\
列名\
列属性：数据类型，约束，其他属性\
数据行
## 物理存储结构
InnoDB(mysql的文件系统)
+ .frm: 表结构，列，列属性
+ .ibd: 存储的数据记录和索引
+ ibdata1:数据字典

Innodb 段 区 页
+ 一个表就是一个段
+ 一个段由多个区构成
+ 区由页(16k)构成，连续64，总共1M(不变)\
![物理存储结构](Mysql\Architecture\layers.jpeg "物理存储结构")


## 排序规则
凡是遇到有比较的都适用该规则\
`show collation;`\
对于英文字符串的，大小写的敏感\
后面带ci大小写不敏感，带bin的敏感\
utf8mb4_gerneral_ci 大小写不敏感\
utf8mb4_bin			大小写敏感

## 数据类型介绍：
数字：\
TINTINT(0-255，-127-128),SMALLINT(16位)INT(32位)..\
浮点FLOAT 单精度4字节，DOUBLE双精度八位\
BIT位字段值

字符串:\
char(100)		定长字符串，不管使用多少，都立即分配100字符长度的存储空间，未填满的空间用空格填充\
varchar(100)	变长字符串类型，每次存储之前，判断长度，按需分配。会单独申请一个字符长度的空间描述字符长度。（字符串长度低于255，超过则占用两个字符长度描述符）\
char最多255,varchar最多65533，两个用作长度描述符\
如何选择？
+ 少于255，定长的列值，选择char。char不用计算长度，录入的性能高。
+ 多于255字符长度，变长的字符串，选择varchar\
会影响索引性能。

enum 枚举\
`address enum('sz','sh','bj'...)`\

时间:\
DATETIME\
1000年0-9999年\
TIMESTAMP\
1970-01-01 00：00..到2038年..时间戳\
二进制
