#!/bin/bash
set -e
set -o pipefail

mkdir -p build/
LOG=build/build.log
WORK="$(mktemp -d -t luantibuild.XXXXXX)"

docker run --rm \
    -v "$PWD:/workspace" \
    -v "$WORK:/tmp/work" \
    -e VERSION=${VERSION:-dev} \
    debian:bullseye /workspace/$1 2>&1 | tee $LOG

echo "Build log: $LOG"
echo "Build work directory: $WORK"
