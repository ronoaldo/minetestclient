#!/bin/bash
set -e
set -x

export MINETEST_VERSION=${MINETEST_VERSION:-master}
export MINETEST_GAME_VERSION=${MINETEST_GAME_VERSION:-master}
export LUAJIT_VERSION=${LUAJIT_VERSION:-v2.1.0-beta4-mercurio}
export VERSION=${VERSION:-5.6.0-ronoaldo}
export WORKSPACE="$(readlink -f $(dirname $0)/..)"

install_appimage_builder() {
    apt-get update
    apt-get install wget -yq

    pushd /opt
    APPIMAGE_BUILDER_DOWNLOAD=https://github.com/AppImageCrafters/appimage-builder/releases/download/v1.1.0/appimage-builder-1.1.0-x86_64.AppImage
    wget -O appimage-builder "$APPIMAGE_BUILDER_DOWNLOAD"
    chmod +x appimage-builder
    # Required to run inside container
    # Ref: https://github.com/AppImageCrafters/appimage-builder/pull/179/files
    # Ref: https://github.com/AppImage/AppImageKit/issues/828
    sed '0,/AI\x02/{s|AI\x02|\x00\x00\x00|}' -i appimage-builder
    ./appimage-builder --appimage-extract
    mv squashfs-root appimage-builder.AppDir
    ln -s /opt/appimage-builder.AppDir/AppRun /usr/bin/appimage-builder
    appimage-builder --version
    popd
}

download_sources() {
    mkdir -p /tmp/work/build
    
    pushd /tmp/work
    git clone --depth=1 -b ${LUAJIT_VERSION} https://github.com/ronoaldo/LuaJIT.git ./luajit
    git clone --depth=1 -b ${MINETEST_VERSION} https://github.com/ronoaldo/minetest.git ./minetest
    git clone --depth=1 -b ${MINETEST_GAME_VERSION} https://github.com/ronoaldo/minetest_game.git ./minetest/games/minetest_game
    git clone --depth=1 https://github.com/minetest/irrlicht ./minetest/lib/irrlichtmt
    popd
}

install_build_dependencies() {
    apt-get update
    apt-get install build-essential cmake git \
        gettext libbz2-dev libcurl4-gnutls-dev \
        libfreetype6-dev libglu1-mesa-dev libgmp-dev \
        libjpeg-dev libjsoncpp-dev libleveldb-dev libxi-dev \
        libogg-dev libopenal-dev libpng-dev libpq-dev libspatialindex-dev \
        libsqlite3-dev libvorbis-dev libx11-dev libxxf86vm-dev libzstd-dev \
        zlib1g-dev git unzip gtk-update-icon-cache -yq
    apt-get clean
}

build() {
    # Build LuaJIT
    pushd /tmp/work/luajit
    sed -e "s/PREREL=.*/PREREL=-beta4-mercurio/g" -i Makefile
    make PREFIX=/usr &&\
    make install PREFIX=/usr
    popd

    # Build Minetest
    pushd /tmp/work/build
    cmake /tmp/work/minetest \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SERVER=FALSE \
        -DBUILD_CLIENT=TRUE \
        -DBUILD_UNITTESTS=FALSE \
        -DVERSION_EXTRA=ronoaldo
    make -j$(nproc)
    popd
}

bundle_appimage() {
    pushd /tmp/work/build
    make install DESTDIR=AppDir
    ls -l /tmp/work/minetest/AppImageBuilder.yml
    appimage-builder --recipe $WORKSPACE/AppImageBuilder.yml
    mkdir -p $WORKSPACE/build
    mv *.AppImage* $WORKSPACE/build
    chmod a+x $WORKSPACE/build/*.AppImage
    popd
}

myuid=$(id -u)
if [ x"$myuid" != x"0" ]; then
    echo "You need to run this as root"
    exit 1
fi
install_appimage_builder
install_build_dependencies
download_sources
build
bundle_appimage
