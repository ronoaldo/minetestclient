#!/bin/bash
set -e
set -o pipefail

LOG=/tmp/make-$$.log
WORK=$(mktemp -d)

docker run --rm \
    -v $PWD:/workspace \
    -v $WORK:/tmp/work \
    debian:bullseye /workspace/$1 2>&1 | tee $LOG

echo "Build log: $LOG"
echo "Build output: $WORK"