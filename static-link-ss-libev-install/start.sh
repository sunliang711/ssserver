#!/bin/bash
export PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin
ulimit -n 52100
server=ROOT/ss-server
db=ROOT/db

# sqlite3 "$db" "create table config(port int primary key,password text,method text,owner text,trafficLimit int,udpRelay int,fastOpen int,enabled int);" || { echo "create table config failed!"; exit 1; }

#不管数据库中有没有配置,一定要启动一个ss-server,因为这个是在systemd中使用的,而systemd的服务文件中的service Type是forking,type是forking的时候要求指定PIDFile,所以只要要启动一个服务
#当然也可以试用一个假的程序,比如tail -f /dev/null &;然后把pid写到service文件的PIDFile中,pid用$!来获得
# ROOT/ss-server -p 65000 -k password -m chacha20 -f /var/run/sslibev.pid

#type为forking的service需要一个PIDFile文件,而这时候,如果数据中没有配置的话,则不会有任何后台程序运行
#会导致service失败,所以加一个后台没有意义多进程来运行,并把pid写入PIDFile文件中
tail -f /dev/null &
echo "$!" >/var/run/sslibev.pid

ports=$(sqlite3 "$db" "select port,password,method,udpRelay,fastOpen from config where enabled=1") || { echo "Query failed!"; exit 1; }

if [[ -z "$ports" ]];then
    echo "Cannot find any port config."
else
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
        echo "Start port $port"
        bash -c "$cmd"
    done
fi
