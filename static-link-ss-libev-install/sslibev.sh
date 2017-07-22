#!/bin/bash
ports=$(sqlite3 /opt/sslibev/db "select port,udpRelay from config where enabled=1;")
echo "sslibev enabled ports: $ports"

echo "$ports" | while read record;do
    port=$(echo "$record" | awk -F'|' '{print $1}')
    udpRelay=$(echo "$record" | awk -F'|' '{print $2}')
    /usr/local/bin/rulesManager.sh addPluginPort tcp $port
    if (($udpRelay ==1));then
        /usr/local/bin/rulesManager.sh addPluginPort udp $port
    fi
done


