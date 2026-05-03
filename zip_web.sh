#!/bin/bash

REPO_DIR=$(git rev-parse --show-toplevel)
SRC_DIR="$REPO_DIR/src"
BIN_DIR="$SRC_DIR/bin"

cd "$SRC_DIR"
WEB_ZIP="$BIN_DIR/traversal_web.zip"
if [ -f "$WEB_ZIP" ]; then
    rm "$WEB_ZIP"
fi

zip -r "$WEB_ZIP" bin/web/
if [ $? -ne 0 ]; then
    echo "Zip failed"
    exit 1
fi

echo "Web zip created: $WEB_ZIP"

