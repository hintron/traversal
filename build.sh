#!/bin/bash

REPO_DIR=$(git rev-parse --show-toplevel)
SRC_DIR="$REPO_DIR/src"

cd "$SRC_DIR"

DEBUG_FLAG=""
MEM_LEAK_FLAG=""
SHUTDOWN_SECS=""
for arg in "$@"; do
    case "$arg" in
        --debug)
            shift
            DEBUG_FLAG="-debug"
            ;;
        --mem-leaks)
            shift
            MEM_LEAK_FLAG="-define:MEM_LEAKS=true"
            ;;
        --shutdown-secs)
            shift
            if [ "$1" == "" ]; then
                SHUTDOWN_SECS="-define:SHUTDOWN_SECS=3"
            else
                SHUTDOWN_SECS="-define:SHUTDOWN_SECS=$1"
                shift
            fi
            ;;
        *)
            echo "Unknown argument: $arg"
            exit 1
            ;;
    esac
done

BIN_DIR="$SRC_DIR/bin"
mkdir -p "$BIN_DIR"

TRAVERSAL_BIN="$BIN_DIR/traversal"

if [ -f "$TRAVERSAL_BIN" ]; then
    rm "$TRAVERSAL_BIN"
fi

odin build . -out:"$TRAVERSAL_BIN" $DEBUG_FLAG $MEM_LEAK_FLAG $SHUTDOWN_SECS
if [ $? -ne 0 ]; then
    echo "Build failed"
    exit 1
fi

odin run odyn_deps/karl2d/build_web -- . -o:size $DEBUG_FLAG $MEM_LEAK_FLAG $SHUTDOWN_SECS
if [ $? -ne 0 ]; then
    echo "Web build failed"
    exit 1
fi

