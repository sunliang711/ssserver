#!/bin/bash
shopt -s expand_aliases
proxy="$1"
if [ -n "$proxy" ];then
    if ! echo "$proxy" | grep -q 'socks5://';then
        proxy="socks5://$proxy"
    fi
    echo "Using socks5 proxy: $proxy"
    git config --global http.proxy "$proxy"
    git config --global https.proxy "$proxy"
    alias curl="curl --socks5 $proxy"
else
    echo "Recommend to use socks5 proxy."
    echo "Usage: $(basename $0) socks5://xxxx:1080"
    sleep 5
fi

ROOT=~/build-ss-libev
outputdir="$ROOT"/output
sodiumVer=1.0.12
mbedtlsVer=2.5.1
pcreVer=8.40
libevVer=4.24
cd "$ROOT"

tool(){
    apt-get update
    apt install -y curl gettext build-essential autoconf libtool  asciidoc xmlto  automake git
    rm -rf "$ROOT" >/dev/null 2>&1
    mkdir -pv "$ROOT"
    mkdir -pv "$outputdir"
}


#compile mbedtls
mbedtls(){
    echo "Downloading mbedtls..."
    curl  https://tls.mbed.org/download/mbedtls-${mbedtlsVer}-gpl.tgz -O
    echo "Extracting mbedtls..."
    tar xf mbedtls*tgz
    cd mbedtls*
    LDFLAGS=-static make DESTDIR=$outputdir/mbedtls install
    cd -
}


#compile pcre
pcre(){

    echo "Downloading pcre..."
    curl https://ftp.pcre.org/pub/pcre/pcre-${pcreVer}.tar.gz -O || { echo "Download pcre source failed!";exit 1; }
    echo "Extracting pcre..."
    tar xf pcre*
    cd pcre*
    ./configure --prefix=$outputdir/pcre --disable-shared --enable-utf8 --enable-unicode-properties
    make || { echo "compile pcre failed!";exit 1; }
    make install
    cd -
}

#compile libsodium
libsodium(){

    echo "Downloading libsodium..."
    curl  https://download.libsodium.org/libsodium/releases/libsodium-${sodiumVer}.tar.gz -O || { echo "Download libsodium source failed!";exit 1;}
    echo "Extract libsodium..."
    tar xf libsodium-${sodiumVer}.tar.gz
    cd libsodium*
    ./configure --prefix=$outputdir/libsodium --disable-ssp --disable-shared || { echo "configure libsodium failed!";exit 1;}
    make || { echo "compile libsodium failed!";exit 1; }
    make install
    cd -
}

#compile libev
libev(){

    echo "Downloading libev..."
    git clone https://github.com/enki/libev || { echo "Download libev failed!"; exit 1; }
    cd libev
    ./configure --prefix=$outputdir/libev --disable-shared
    make || { echo "compile libev failed!";exit 1; }
    make install
    cd -
}

#compile libudns
libudns(){

    echo "Downloading libudns..."
    git clone https://github.com/shadowsocks/libudns || { echo "Download libudns failed!";exit 1; }
    cd libudns
    ./autogen.sh || { echo "libudns: run autogen.sh failed!"; exit 1; }
    ./configure --prefix=$outputdir/libudns || { echo "configure libudns failed!"; exit 1; }
    make || { echo "compile libudns failed!"; exit 1; }
    make install
    cd -
}

#compile shadowsocks-libev
shadowsocks-libev(){
    echo "Downloading shadowsocks-libev..."
    git clone https://github.com/shadowsocks/shadowsocks-libev.git || { echo "Download shadowsocks-libev failed!"; exit 1; }
    cd shadowsocks-libev
    git submodule update --init --recursive || { echo "Download shadowsocks-libev submodule failed!"; exit 1; }
    ./autogen.sh
    LIBS="-lpthread -lm" LDFLAGS="-Wl,-static -static -static-libgcc -L$outputdir/libudns/lib -L$outputdir/libev/lib" CFLAGS="-I$outputdir/libudns/include -I$outputdir/libev/include" ./configure  --prefix=$outputdir/shadowsocks-libev --disable-ssp --disable-documentation --with-mbedtls=$outputdir/mbedtls --with-pcre=$outputdir/pcre --with-sodium=$outputdir/libsodium || { echo "configure shadowsocks-libev failed!"; exit 1; }
    make || { echo "compile shadowsocks-libev failed!"; exit 1; }
    make install
    cd -
}

#compile simple-obfs
simple-obfs(){
    echo "Downloading simple-obfs"
    git clone https://github.com/shadowsocks/simple-obfs || { echo "Download simple-obfs failed"; exit 1; }
    cd simple-obfs
    # git checkout v$ver -b v$ver
    git submodule init && git submodule update
    ./autogen.sh || { echo "simple-obfs autogen.sh failed!"; exit 1; }
    LIBS="-lpthread -lm" LDFLAGS="-Wl,-static -static -static-libgcc -L$outputdir/libsodium/lib -L$outputdir/libudns/lib -L$outputdir/libev/lib" CFLAGS="-I$outputdir/libsodium/include -I$outputdir/libudns/include -I$outputdir/libev/include" ./configure --prefix=$outputdir/shadowsocks-libev --disable-ssp --disable-documentation || { echo "configure simple-obfs failed!"; exit 1; }
    make || { echo "compile simple-obfs failed!"; exit 1; }
    make install
    cd -
}

stripBin(){
    find $outputdir/shadowsocks-libev/bin ! -name "ss-nat" -type f | xargs strip
}
# tool
# mbedtls
# pcre
# libsodium
# libev
# libudns
# shadowsocks-libev
# simple-obfs
stripBin
