#!/bin/bash

LOG=/tmp/make-$$.log
WORK=$(mktemp -d)

docker run --rm -it \
    -v $PWD:/workspace \
    -v $WORK:/tmp/work \
    debian:bullseye /workspace/scripts/$1 2>&1 | tee $LOG

echo "Build log: $LOG"
echo "Build output: $WORK"