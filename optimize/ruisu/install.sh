#!/bin/bash
bash serverspeeder-all.sh
cp -v /serverspeeder/etc/config{,.bak}
sed -i 's/^advinacc="0"/advinacc="1"/' /serverspeeder/etc/config
sed -i 's/^initialCwndWan="[0-9]\+"/initialCwndWan="32"/' /serverspeeder/etc/config
service serverSpeeder restart
