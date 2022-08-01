#!/bin/bash
set -e
# Check if the build / package steps are correct and that the required libraries
# where provided in the recipe.

app="$(readlink -f $1)"
prog="$2"
work=$(mktemp -d)
cd $work

$app --appimage-extract > /dev/null

cd squashfs-root
if [ ! -f $prog ] ; then
    echo "Program not found inside squashfs-root: $prog"
    exit 1
fi

ldd $prog | while read lib arrow path extra ; do
    echo -n "$lib: "
    if [ -z `find . -iname "*${lib}*" -print -quit` ]; then 
        echo "missing"
    else
        echo "found"
    fi
done