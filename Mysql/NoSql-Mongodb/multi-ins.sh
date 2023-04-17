#!/bin/bash
for i in `seq 28018 28021`
do
mkdir -p /opt/mongodb/$i/conf /opt/mongodb/$i/data /opt/mongodb/$i/log
cat >/opt/mongodb/$i/conf/mongod.conf<<EOF
systemLog:
  destination: file
  path: /opt/mongodb/$i/log/mongodb.log
  logAppend: true
storage:
  journal:
    enabled: true
  dbPath: /opt/mongodb/$i/data
  directoryPerDB: true
  #engine: wiredTiger
  wiredTiger:
    engineConfig:
      cacheSizeGB: 1
      directoryForIndexes: true
    collectionConfig:
      blockCompressor: zlib
    indexConfig:
      prefixCompression: true
processManagement:
  fork: true
net:
  bindIp: 127.0.0.1
  port: $i
replication:
  oplogSizeMB: 2048
  replSetName: my_repl
EOF
done

chown -R mongod.mongod /opt/mongodb

for i in `seq 28018 28021`
do
mongod -f /opt/mongodb/$i/conf/mongod.conf
done

netstat -lnp|grep 280
