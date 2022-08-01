#!/bin/bash
set -e
set -o pipefail

LOG=/tmp/make-$$.log
WORK=$(mktemp -d)

docker run --rm \
    -v $PWD:/workspace \
    -v $WORK:/tmp/work \
    -e VERSION=${VERSION:-dev} \
    debian:bullseye /workspace/$1 2>&1 | tee $LOG

echo "Build log: $LOG -> build/build.log"
cp -v $LOG build/build.log
echo "Build work directory: $WORK"