这里只安装ss-server,如果需要ss-manager ss-local ss-redir ss-nat ss-tunnel obfs-local obfs-server可以使用make.sh进行静态编译


install.sh: 安装脚本
make.sh: 静态编译shadowsocks-libev所有软件
ssmanager-install.sh: ss-manager 安装脚本(目前可用,但是支付宝支付不可以用,支付宝的问题)

ss-server: shadowsocks-libev服务端主程序
iptables-plugin.sh: iptables service插件
ssserver.sh: ss-server的管理成员,包括添加删除端口配置等
sslibev.service: systemd service file
start.sh: systemd service的启动文件
