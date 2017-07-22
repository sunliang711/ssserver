serverSpeeder是作为daemon启动的，可以使用chkconfig serverSpeeder on/off来设置开机启动或不启动

手动开启/etc/init.d/serverSpeeder start
手动关闭/etc/init.d/serverSpeeder stop
查看状态/etc/init.d/serverSpeeder status

或者
service serverSpeeder start/stop/status
