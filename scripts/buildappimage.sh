#!/bin/bash
set -e
set -x

# Base build directory
WORKSPACE="$(readlink -f "$(dirname "$0")/..")"
export WORKSPACE

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
export MINETEST_IRRLICHT_VERSION="none"
# TODO(ronoaldo) detect from Github Release
case ${BRANCH} in
    5.5.0) export MINETEST_IRRLICHT_VERSION=1.9.0mt4  ;;
    5.5.1) export MINETEST_IRRLICHT_VERSION=1.9.0mt5  ;;
    5.6.0) export MINETEST_IRRLICHT_VERSION=1.9.0mt7  ;;
    5.6.1) export MINETEST_IRRLICHT_VERSION=1.9.0mt8  ;;
    5.7.0) export MINETEST_IRRLICHT_VERSION=1.9.0mt10 ;;
    5.8.0) export MINETEST_IRRLICHT_VERSION=1.9.0mt13 MINETEST_GAME_VERSION=5.7.0 ;;
    # 5.9.0+ has bundled irrlicht and we now have rolling release of minetest_game
    5.9.0) export MINETEST_GAME_VERSION=master ;;
    5.9.1) export MINETEST_GAME_VERSION=master ;;
    master|main) ;;
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

git_clone() {
	git clone "$1" "$2"
	git -C "$2" checkout "$3"
	rm -rf "${2}/.git"
}

download_sources() {
    mkdir -p /tmp/work/build
    
    pushd /tmp/work
    git_clone https://github.com/minetest/minetest.git      ./minetest                     "${MINETEST_VERSION}"
    git_clone https://github.com/minetest/minetest_game.git ./minetest/games/minetest_game "${MINETEST_GAME_VERSION}"
    if [ "${MINETEST_IRRLICHT_VERSION}" != "none" ]; then
        git_clone https://github.com/minetest/irrlicht      ./minetest/lib/irrlichtmt      "${MINETEST_IRRLICHT_VERSION}"
    fi
    popd
}

install_build_dependencies() {
    apt-get update
    # appimage requirements
    apt-get install gpg gtk-update-icon-cache git -yq
    # minetest requirements
    apt-get install \
        g++ make libc6-dev cmake libpng-dev libjpeg-dev libgl1-mesa-dev \
        libsqlite3-dev libogg-dev libvorbis-dev libopenal-dev \
        libcurl4-gnutls-dev libfreetype6-dev zlib1g-dev libgmp-dev libjsoncpp-dev \
        libzstd-dev libluajit-5.1-dev gettext libsdl2-dev -yq
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
    #shellcheck disable=2046
    make -j$(nproc)
    popd
}

bundle_appimage() {
    pushd /tmp/work/build
    make install DESTDIR=AppDir
    mkdir -p AppDir/usr/share/minetest/games/minetest_game/
    cp -r ../minetest/games/minetest_game/* AppDir/usr/share/minetest/games/minetest_game/
    appimage-builder --recipe "$WORKSPACE/AppImageBuilder.yml"
    mkdir -p "$WORKSPACE/build"
    mv ./*.AppImage* "$WORKSPACE/build"
    chmod a+x "$WORKSPACE"/build/*.AppImage
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
