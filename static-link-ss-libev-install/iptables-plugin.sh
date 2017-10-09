#!/bin/bash
export PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin
if [[ ! -x /usr/local/bin/rulesManager.sh ]];then
    echo "Can not find rulesManger,not install iptables servie?"
    exit 1
fi
ports=$(sqlite3 /opt/sslibev/db "select port,udpRelay from config where enabled=1;")
echo "sslibev enabled ports: $ports"

echo "$ports" | while read record;do
    port=$(echo "$record" | awk -F'|' '{print $1}')
    udpRelay=$(echo "$record" | awk -F'|' '{print $2}')
    rulesManager.sh add tcp $port
    if (($udpRelay ==1));then
        rulesManager.sh add udp $port
    fi
done


