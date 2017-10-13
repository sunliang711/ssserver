#!/bin/bash
thisScriptDir=$(cd $(dirname ${BASH_SOURCE}) && pwd)
cd ${thisScriptDir}

root=/opt/sslibev
db=$root/db
#TODO serviceFileDir may be difference on many OSes
serviceFileDir=/etc/systemd/system

#must install rng-tools after run better.sh and ruisu
apt install rng-tools -y
check(){
    if ! command -v sqlite3 >/dev/null 2>&1;then
        echo "Error: need sqlite3 support!"
        exit 1
    fi
}
installss(){
    systemctl stop sslibev >/dev/null 2>&1
    rm -rf $root >/dev/null 2>&1
    mkdir -p $root >/dev/null 2>&1

    if ! command -v sqlite3 >/dev/null 2>&1;then
        echo "try to install sqlite3..."
        apt update >/dev/null 2>&1
        apt install -y sqlte3 || { echo "you mast install sqlite3 yourself."; }
    fi
    #create db
    sqlite3 "$db" "create table config(port int primary key,password text,method text,owner text,trafficLimit text,udpRelay int,fastOpen int,enabled int);" || { echo "create table config failed!"; exit 1; }

    #iptables.service plugin
    cp ./iptables-plugin.sh /opt/iptables/plugin/ || { echo "You didn't install iptables service,install iptables-plugin.sh plugin failed!"; }

    sed "s|ROOT|$root|" ./sslibev.service > "$serviceFileDir/sslibev.service"
    sed "s|ROOT|$root|" ./start.sh > "$root/start.sh"
    sed "s|ROOT|$root|" ./ssserver.sh > "$root/ssserver.sh"
    ln -sf "$root/ssserver.sh" /usr/local/bin/ssserver.sh

    chmod +x "$root/start.sh"
    chmod +x /usr/local/bin/ssserver.sh

    cp ./ss-server $root
    chmod +x "$root/ss-server"
    systemctl daemon-reload
}

check
installss
