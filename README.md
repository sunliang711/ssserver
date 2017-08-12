# ssserver
从 https://github.com/ss2 里面的关于ss的部分分解出来


optimize/ 里面包含锐速,bbr等加速脚本
static-link-ss-libev-install/ shadowsocks-libev(服务版)安装包

#安装完之后,使用ssserver.sh管理端口,使用systemctl restart sslibev来重启服务

#新加端口:
ssserver.sh add 命令增加
然后systemctl restart sslibev重启服务
如果使用了iptables服务,则还要使用rulesManager add命令来允许的新加的端口
