#!/bin/bash
#本脚本用来执行账户管理操作
#也就是修改sqlite3数据库的操作
db=ROOT/db
# sqlite3 "$db" "create table config(port int primary key,password text,method text,owner text,trafficLimit int,udpRelay int,fastOpen int,enabled int);" || { echo "create table config failed!"; exit 1; }
list(){
    echo -e ".header on\n.mode column\nselect * from config;" | sqlite3 "$db"
}
add(){
    if (( $#<3 ));then
        echo "usage: add port password method [owner] [trafficLimit] [udp-relay:1 or 0]"
        exit 1
    fi
    port=$1
    password=$2
    method=$3
    owner=${4:-nobody}
    trafficLimit=${5:-100G}
    udpRelay=${6:-1}
    sqlite3 "$db" "insert into config(port,password,method,owner,trafficLimit,udpRelay,fastOpen,enabled) values($port,\"$password\",\"$method\",\"$owner\",\"$trafficLimit\",$udpRelay,1,1);" || { echo "add failed!"; exit 1; }
}

del(){
    if (($#<1));then
        echo "Usage: del port"
        exit 1
    fi
    port=$1
    sqlite3 "$db" "delete from config where port=$port;" || { echo "del failed!"; exit 1; }
}

enable(){
    if (($#<1));then
        echo "Usage: del port"
        exit 1
    fi
    port=$1
    sqlite3 "$db" "update config set enabled=1 where port=$port;" || { echo "enable port:$port failed!"; exit 1; }
}

disable(){
    if (($#<1));then
        echo "Usage: del port"
        exit 1
    fi
    port=$1
    sqlite3 "$db" "update config set enabled=0 where port=$port;" || { echo "enable port:$port failed!"; exit 1; }
}

update(){
    if (($#<3));then
        echo "Usage: update port new-password new-method [new-owner new-trafficLimit new-udpRelay new-fastOpen new-enabled]"
        exit 1
    fi
    port=$1
    password=$2
    method=$3
    #get old value of owner trafficLimit udpRelay fastOpen enabled
    old=$(sqlite3 "$db" "select owner,trafficLimit,udpRelay,fastOpen,enabled from config where port=$port;") || { echo "query port:$port failed!"; exit 1; }
    if [ -z "$old" ];then
        echo "Cannot find port $port config!"
        exit 1
    fi
    oldOwner=$(echo "$old" | awk -F'|' '{print $1}')
    oldTrafficLimit=$(echo "$old" | awk -F'|' '{print $2}')
    oldUdpRelay=$(echo "$old" | awk -F'|' '{print $3}')
    oldFastOpen=$(echo "$old" | awk -F'|' '{print $4}')
    oldEnabled=$(echo "$old" | awk -F'|' '{print $5}')
    owner=${4:-$oldOwner}
    trafficLimit=${5:-$oldTrafficLimit}
    udpRelay=${6:-$oldUdpRelay}
    fastOpen=${7:-$oldFastOpen}
    enabled=${8:-$oldEnabled}

    sqlite3 "$db" "update config set password=\"$password\",method=\"$method\",owner=\"$owner\",trafficLimit=\"$trafficLimit\",udpRelay=$udpRelay,fastOpen=$fastOpen,enabled=$enabled where port=$port;" || { echo "update port:$port failed!"; exit 1; }

}
uninstall(){
    rm -rf ROOT
    rm /usr/local/bin/ssserver.sh
}

usage(){
    echo "Usage: $(basename $0) CMD"
    echo
    echo "CMD:"
    echo -e "\t\tlist"
    echo -e "\t\tadd port password method [owner] [trafficLimit(default 100G)] [udpRelay: 0 or 1]"
    echo -e "\t\tdel port"
    echo -e "\t\tenable port"
    echo -e "\t\tdisable port"
    echo -e "\t\tupdate port password method [owner] [trafficLimit] [udpRelay] [fastOpen] [enabled]"
    echo -e "\t\tuninstall"
}
cmd=$1
shift 1
case $cmd in
    list)
        list
        ;;
    add)
        add "$@"
        ;;
    del)
        del "$@"
        ;;
    enable)
        enable "$@"
        ;;
    disable)
        disable "$@"
        ;;
    update)
        update "$@"
        ;;
    uninstall)
        uninstall
        ;;
    *)
        usage
        ;;
esac
