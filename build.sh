#!/bin/bash

REPO_DIR=$(git rev-parse --show-toplevel)
SRC_DIR="$REPO_DIR/src"

cd "$SRC_DIR"

BIN_DIR="$SRC_DIR/bin"
mkdir -p "$BIN_DIR"

TRAVERSAL_BIN="$BIN_DIR/traversal"

if [ -f "$TRAVERSAL_BIN" ]; then
    rm "$TRAVERSAL_BIN"
fi

odin build . -out:"$TRAVERSAL_BIN"
if [ $? -ne 0 ]; then
    echo "Build failed"
    exit 1
fi

odin run odyn_deps/karl2d/build_web -- . -o:size
if [ $? -ne 0 ]; then
    echo "Web build failed"
    exit 1
fi

