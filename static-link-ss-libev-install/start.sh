#!/bin/bash
ulimit -n 52100
server=ROOT/ss-server
db=ROOT/db

    # sqlite3 "$db" "create table config(port int primary key,password text,method text,udpRelay int,fastOpen int,enabled int);" || { echo "create table config failed!"; exit 1; }
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
