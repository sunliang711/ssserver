#!/bin/bash

if (($EUID!=0));then
    echo -e "Need run as $(tput setaf 1)root \u2717"
    exit 1
fi

limitfile=/etc/security/limits.conf
limit=51200
cp -v "$limitfile" "${limitfile}.bak"
echo "* soft nofile $limit" >> "$limitfile"
echo "* hard nofile $limit" >> "$limitfile"

#tested on debian
/sbin/modprobe tcp_hybla && echo tcp_hybla > /etc/modules-load.d/shadowsocks.conf

ctlfile=/etc/sysctl.d/local.conf
cat > $ctlfile <<EOF
fs.file-max = 51200
net.ipv4.conf.lo.accept_redirects=0
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.eth0.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv4.ip_local_port_range = 10000 65000
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.tcp_rmem  = 32768 436600 873200
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_max_tw_buckets = 9000
net.ipv4.tcp_max_syn_backlog = 65536
net.ipv4.tcp_mem = 94500000 91500000 92700000
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_wmem = 8192 436600 873200
net.core.netdev_max_backlog = 250000
net.core.somaxconn = 32768
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
EOF
if sysctl net.ipv4.tcp_available_congestion_control | grep -q hybla;then
	echo 'net.ipv4.tcp_congestion_control = hybla' >>$ctlfile	
fi
sysctl -p
