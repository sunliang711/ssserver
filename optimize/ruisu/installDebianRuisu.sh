#!/bin/bash
#tested on debian 8.8 linux kernel: 3.16.0-4-amd64
if [ ! -e serverspeeder-v.sh ];then
	wget -N --no-check-certificate https://github.com/91yun/serverspeeder/raw/master/serverspeeder-v.sh
fi
bash serverspeeder-v.sh Debian 8 3.16.0-4-amd64 x64 3.10.61.0 serverspeeder_31604
