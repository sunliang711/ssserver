#!/bin/bash
shopt -s expand_aliases
if ! command -v apt-get;then
    echo "Only run on debian"
    echo "Tested on debian9"
    exit 1
fi

if [[ $EUID -ne 0 ]];then
    if command -v sudo;then
        echo "You are not run as root,try use sudo"
        sudo /bin/true || { echo "And you can not use command sudo";exit 1; }
        echo "OK,you can use sudo command"
    else
        echo "You are not root,and the os doesn't have sudo cmd"
        exit 1
    fi
fi

proxy="$1"
if [[ -n $proxy ]];then
    echo "Using socks5 proxy: $proxy"
    alias curl="curl --socks5 $proxy"
    proxyIP=$(curl -s ip.cn)
    if [[ -z $proxyIP ]];then
        echo "But the proxy does not work"
        exit 1
    fi
    git config --global http.proxy "$proxy"
    git config --global https.proxy "$proxy"
fi

user=${SUDO_USER:-$(whoami)}
HOME=$(eval echo "~$user")
ROOT="$HOME"/build-ss-libev
echo "root dir is : $ROOT"
outputdir="$ROOT"/output
sodiumVer=1.0.12
mbedtlsVer=2.5.1
pcreVer=8.40
libevVer=4.24

tool(){
    if [[ $EUID -ne 0 ]];then
        sudo apt-get update
        sudo apt install -y curl gettext build-essential autoconf libtool  asciidoc xmlto  automake git
    else
        apt-get update
        apt install -y curl gettext build-essential autoconf libtool  asciidoc xmlto  automake git
    fi
    if [[ $? -ne 0 ]];then
        echo "Install tools failed"
        exit 1
    fi
    rm -rf "$ROOT" >/dev/null 2>&1
    mkdir -pv "$ROOT"
    mkdir -pv "$outputdir"
}


#compile mbedtls
mbedtls(){
    cd "$ROOT"
    echo "Downloading mbedtls..."
    curl  https://tls.mbed.org/download/mbedtls-${mbedtlsVer}-gpl.tgz -O || { echo "Download mbedtls source failed!"; exit 1; }
    echo "Extracting mbedtls..."
    tar xf mbedtls-${mbedtlsVer}-gpl.tgz
    cd mbedtls-${mbedtlsVer}
    echo "Install mbedtls..."
    LDFLAGS=-static make DESTDIR=$outputdir/mbedtls install
}


#compile pcre
pcre(){
    cd "$ROOT"
    echo "Downloading pcre..."
    curl https://ftp.pcre.org/pub/pcre/pcre-${pcreVer}.tar.gz -O || { echo "Download pcre source failed!";exit 1; }
    echo "Extracting pcre..."
    tar xf pcre-${pcreVer}.tar.gz
    cd pcre-${pcreVer}
    echo "Configure pcre..."
    ./configure --prefix=$outputdir/pcre --disable-shared --enable-utf8 --enable-unicode-properties
    echo "Compile pcre..."
    make || { echo "compile pcre failed!";exit 1; }
    make install
    cd -
}

#compile libsodium
libsodium(){
    cd "$ROOT"
    echo "Downloading libsodium..."
    curl  https://download.libsodium.org/libsodium/releases/libsodium-${sodiumVer}.tar.gz -O || { echo "Download libsodium source failed!";exit 1;}
    echo "Extract libsodium..."
    tar xf libsodium-${sodiumVer}.tar.gz
    cd libsodium-${sodiumVer}
    echo "Configure libsodium..."
    ./configure --prefix=$outputdir/libsodium --disable-ssp --disable-shared || { echo "configure libsodium failed!";exit 1;}
    echo "Compile libsodium..."
    make || { echo "compile libsodium failed!";exit 1; }
    make install
    cd -
}

#compile libev
libev(){
    cd "$ROOT"
    echo "Downloading libev..."
    git clone https://github.com/enki/libev || { echo "Download libev failed!"; exit 1; }
    cd libev
    echo "Configure libev..."
    ./configure --prefix=$outputdir/libev --disable-shared
    echo "Compile libev..."
    make || { echo "compile libev failed!";exit 1; }
    make install
    cd -
}

#compile libudns
libudns(){
    cd "$ROOT"
    echo "Downloading libudns..."
    git clone https://github.com/shadowsocks/libudns || { echo "Download libudns failed!";exit 1; }
    cd libudns
    echo "Configure libudns..."
    ./autogen.sh || { echo "libudns: run autogen.sh failed!"; exit 1; }
    ./configure --prefix=$outputdir/libudns || { echo "configure libudns failed!"; exit 1; }
    echo "Compile libudns..."
    make || { echo "compile libudns failed!"; exit 1; }
    make install
    cd -
}

#compile shadowsocks-libev
shadowsocks-libev(){
    cd "$ROOT"
    echo "Downloading shadowsocks-libev..."
    git clone https://github.com/shadowsocks/shadowsocks-libev.git || { echo "Download shadowsocks-libev failed!"; exit 1; }
    cd shadowsocks-libev
    git submodule update --init --recursive || { echo "Download shadowsocks-libev submodule failed!"; exit 1; }
    echo "Configure shadowsocks-libev..."
    ./autogen.sh
    LIBS="-lpthread -lm" LDFLAGS="-Wl,-static -static -static-libgcc -L$outputdir/libudns/lib -L$outputdir/libev/lib" CFLAGS="-I$outputdir/libudns/include -I$outputdir/libev/include" ./configure  --prefix=$outputdir/shadowsocks-libev --disable-ssp --disable-documentation --with-mbedtls=$outputdir/mbedtls --with-pcre=$outputdir/pcre --with-sodium=$outputdir/libsodium || { echo "configure shadowsocks-libev failed!"; exit 1; }
    echo "Compile shadowsocks-libev..."
    make || { echo "compile shadowsocks-libev failed!"; exit 1; }
    make install
    cd -
}

#compile simple-obfs
simple-obfs(){
    cd "$ROOT"
    echo "Downloading simple-obfs"
    git clone https://github.com/shadowsocks/simple-obfs || { echo "Download simple-obfs failed"; exit 1; }
    cd simple-obfs
    # git checkout v$ver -b v$ver
    git submodule init && git submodule update
    echo "Configure simple-obfs..."
    ./autogen.sh || { echo "simple-obfs autogen.sh failed!"; exit 1; }
    LIBS="-lpthread -lm" LDFLAGS="-Wl,-static -static -static-libgcc -L$outputdir/libsodium/lib -L$outputdir/libudns/lib -L$outputdir/libev/lib" CFLAGS="-I$outputdir/libsodium/include -I$outputdir/libudns/include -I$outputdir/libev/include" ./configure --prefix=$outputdir/shadowsocks-libev --disable-ssp --disable-documentation || { echo "configure simple-obfs failed!"; exit 1; }
    echo "Compile simple-obfs..."
    make || { echo "compile simple-obfs failed!"; exit 1; }
    make install
    cd -
}

stripBin(){
    echo "Strip binaries..."
    find $outputdir/shadowsocks-libev/bin ! -name "ss-nat" -type f | xargs strip
}
tool
mbedtls
pcre
libsodium
libev
libudns
shadowsocks-libev
simple-obfs
stripBin
