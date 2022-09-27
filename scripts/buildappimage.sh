#!/bin/bash
set -e
set -x

# Base build directory
export WORKSPACE="$(readlink -f $(dirname $0)/..)"

# Version -> branch calculation
export VERSION=${VERSION:dev}
export BRANCH=master
case $VERSION in
    [0-9].[0-9].[0-9]-[0-9]|[0-9].[0-9][0-9].[0-9]-[0-9]|[0-9].[0-9].[0-9][0-9]-[0-9]|[0-9].[0-9][0-9].[0-9][0-9]-[0-9])
        export BRANCH=${VERSION%%-*}
        echo "Version ${VERSION} detected as stable build, with increment. Using tag ${BRANCH}."
    ;;
    [0-9].[0-9].[0-9]|[0-9].[0-9][0-9].[0-9]|[0-9].[0-9].[0-9][0-9]|[0-9].[0-9][0-9].[0-9][0-9])
        export BRANCH=${VERSION}
        echo "Version ${VERSION} detected as stable build. Using tag ${BRANCH}."
    ;;
    *rc*|*beta*)
        echo "Version ${VERSION} detected as release candidate build. Using branch master."
    ;;
    *)
        echo "Version detected as a development build. Using branch master."
    ;;
esac

export MINETEST_VERSION="${BRANCH}"
export MINETEST_GAME_VERSION="${BRANCH}"
export MINETEST_IRRLICHT_VERSION="master"
# TODO(ronoaldo) detect from Github Release
case ${BRANCH} in
    5.5.0) export MINETEST_IRRLICHT_VERSION=1.9.0mt4 ;;
    5.5.1) export MINETEST_IRRLICHT_VERSION=1.9.0mt5 ;;
    5.6.0) export MINETEST_IRRLICHT_VERSION=1.9.0mt7 ;;
    5.6.1) export MINETEST_IRRLICHT_VERSION=1.9.0mt8 ;;
esac

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

git_clone() { git clone "$1" "$2" && git -C "$2" checkout "$3" ; }

download_sources() {
    mkdir -p /tmp/work/build
    
    pushd /tmp/work
    git_clone https://github.com/minetest/minetest.git      ./minetest                     ${MINETEST_VERSION} 
    git_clone https://github.com/minetest/minetest_game.git ./minetest/games/minetest_game ${MINETEST_GAME_VERSION} 
    git_clone https://github.com/minetest/irrlicht          ./minetest/lib/irrlichtmt      ${MINETEST_IRRLICHT_VERSION}
    popd
}

install_build_dependencies() {
    apt-get update
    apt-get install build-essential cmake git \
        gettext libbz2-dev libcurl4-gnutls-dev \
        libfreetype6-dev libglu1-mesa-dev libgmp-dev libluajit-5.1-dev \
        libjpeg-dev libjsoncpp-dev libleveldb-dev libxi-dev \
        libogg-dev libopenal-dev libpng-dev libspatialindex-dev \
        libsqlite3-dev libvorbis-dev libx11-dev libxxf86vm-dev libzstd-dev \
        zlib1g-dev git unzip gtk-update-icon-cache -yq
    apt-get clean
}

build() {
    # Build Minetest
    pushd /tmp/work/build
    cmake /tmp/work/minetest \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DBUILD_SERVER=FALSE \
        -DBUILD_CLIENT=TRUE \
        -DBUILD_UNITTESTS=FALSE \
        -DVERSION_EXTRA=unofficial
    make -j$(nproc)
    popd
}

bundle_appimage() {
    pushd /tmp/work/build
    make install DESTDIR=AppDir
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
