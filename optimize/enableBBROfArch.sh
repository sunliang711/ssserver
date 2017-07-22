#!/bin/sh

if (($EUID!=0));then
    echo -e "Need run as $(tput setaf 1)root \u2717"
    exit 1
fi

#echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
#echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf

if command -v pacman >/dev/null 2>&1;then
    echo "net.ipv4.tcp_congestion_control=bbr" >  /etc/sysctl.d/80-bbr.conf
    echo "please reboot now" 
else
	echo -e "Only support $(tput setaf 1)Archlinux$(tput sgr0) now,because bbr need linux kernel 4.9!"
fi

