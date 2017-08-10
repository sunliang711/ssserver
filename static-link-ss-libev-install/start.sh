#!/bin/bash
ulimit -n 52100
server=ROOT/ss-server
db=ROOT/db

# sqlite3 "$db" "create table config(port int primary key,password text,method text,udpRelay int,fastOpen int,enabled int);" || { echo "create table config failed!"; exit 1; }

#不管数据库中有没有配置,一定要启动一个ss-server,因为这个是在systemd中使用的,而systemd的服务文件中的service Type是forking,type是forking的时候要求指定PIDFile,所以只要要启动一个服务
#当然也可以试用一个假的程序,比如tail -f /dev/null &;然后把pid写到service文件的PIDFile中,pid用$!来获得
ROOT/ss-server -p 65000 -k password -m chacha20 -f /var/run/sslibev.pid

ports=$(sqlite3 "$db" "select port,password,method,udpRelay,fastOpen from config where enabled=1") || { echo "Query failed!"; exit 1; }

echo "$ports" | while read record;do
    port=$(echo "$record" | awk -F'|' {'print $1'})
    password=$(echo "$record" | awk -F'|' {'print $2'})
    method=$(echo "$record" | awk -F'|' {'print $3'})
    udpRelay=$(echo "$record" | awk -F'|' {'print $4'})
    fastOpen=$(echo "$record" | awk -F'|' {'print $5'})

    cmd="ROOT/ss-server -p $port -k $password -m $method -f /var/run/sslibev$port.pid"
    if (($udpRelay==1));then
        cmd="$cmd -u"
    fi
    if (($fastOpen==1));then
        cmd="$cmd --fast-open"
    fi
    bash -c "$cmd"
done
