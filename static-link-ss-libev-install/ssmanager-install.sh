#!/bin/bash
proxy=0
while getopts "p" opt;do
    case $opt in
        p)
            proxy=1
            ;;
    esac
done

setProxy(){
    export http_proxy=http://localhost:8118
    export https_proxy=http://localhost:8118
    sslocal.sh restart 1 g || { echo "Start sslocal in global mode failed!"; exit 1; }
}

root=/opt/nodejs
if (($proxy==1));then
    setProxy
fi

rm -rf $root >/dev/null 2>&1
mkdir $root

wget -N --no-check-certificate https://nodejs.org/dist/v6.9.1/node-v6.9.1-linux-x64.tar.gz
tar -xf node-v6.9.1-linux-x64.tar.gz -C $root
rm -rf node-v6.9.1-linux-x64.tar.gz
ln -sf $root/node-v6.9.1-linux-x64/bin/node /usr/local/bin/node
ln -sf $root/node-v6.9.1-linux-x64/bin/npm /usr/local/bin/npm
if (($proxy==1));then
    #npm config set proxy http://localhost:8118
    #npm config set https-proxy http://localhost:8118
    npm config set strict-ssl false
    npm config set registry "http://registry.npmjs.org/"
    npm --proxy http://localhost:8118 i -g shadowsocks-manager
else
    npm i -g shadowsocks-manager
fi

ln -sf $root/node-v6.9.1-linux-x64/lib/node_modules/shadowsocks-manager/bin/ssmgr /usr/local/bin/ssmgr

tar jxf ../static-link-ss-libev-install/ss-libev-binaries-static-link.tar.bzip2
cp ss-libev-binaries-static-link/ss-server /usr/local/bin
cp ss-libev-binaries-static-link/ss-manager /usr/local/bin
rm -rf ss-libev-binaries-static-link/

mkdir ~/.ssmgr
cat>~/.ssmgr/ss.yml<<EOF
type: s
empty: false
shadowsocks:
  address: 127.0.0.1:2397
manager:
  address: 0.0.0.0:2398
  password: 'passwd'
  # 更改为你自己的密码
db: 'ss.sqlite'
EOF
cat>~/.ssmgr/webgui.yml<<EOF
type: m
empty: false

manager:
  address: 127.0.0.1:2398
  password: 'passwd'
  # 这部分的端口和密码需要跟上一步 manager 参数里的保持一致
plugins:
  flowSaver:
    use: true
  user:
    use: true
  account:
    use: true
    pay:
      hour:
        price: 0.03
        flow: 500000000
      day:
        price: 0.5
        flow: 7000000000
      week:
        price: 3
        flow: 50000000000
      month:
        price: 10
        flow: 200000000000
      season:
        price: 30
        flow: 200000000000
      year:
        price: 120
        flow: 200000000000
  email:
    use: true
    #username: 'postmaster@sandbox920d4cd2c4ca4588be4325b85bbbe8f3.mailgun.org'
    #password: '7a3fc9a4e129aa0880fdec7cb34dd8b8'
    #host: 'smtp.mailgun.org'
    username: 'sunliang711@163.com'
    password: 'sl262732'
    host: 'smtp.163.com'
    #username: 'eagle@mailgun.eagle711.win'
    #password: 'sl262732'
    #host: 'smtp.mailgun.org'
    # 这部分的邮箱和密码是用于发送注册验证邮件，重置密码邮件使用的，推荐使用 Mailgun.com
  webgui:
    use: true
    host: '0.0.0.0'
    port: '80'
    site: 'http://eagle.com'
    # 改成你自己的域名
    gcmSenderId: '456102641793'
    gcmAPIKey: 'AAAAGzzdqrE:XXXXXXXXXXXXXX'
  alipay:
    use: false
    # 若要使用支付宝收款，请自己研究
    appid: 2015012108272442
    notifyUrl: ''
    merchantPrivateKey: 'xxxxxxxxxxxx'
    alipayPublicKey: 'xxxxxxxxxxx'
    gatewayUrl: 'https://openapi.alipay.com/gateway.do'

db: 'webgui.sqlite'
EOF

cat>$root/start.sh<<EOF
ss-manager -m aes-256-cfb -u --executable /usr/local/bin/ss-server --manager-address 127.0.0.1:2397 &
ssmgr -c ~/.ssmgr/ss.yml &
ssmgr -c ~/.ssmgr/webgui.yml&
EOF
chmod +x $root/start.sh

cat>$root/stop.sh<<'EOF'
#!/bin/bash
pids=$(ps aux | grep ssmgr | grep -v grep | awk '{print $2}')
for i in $pids;do
    kill $i
done

pids=$(ps aux | grep ss-manager | grep -v grep | awk '{print $2}')
for i in $pids;do
    kill $i
done
EOF

chmod +x $root/stop.sh
