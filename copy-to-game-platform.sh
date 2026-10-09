#!/bin/bash

REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
WEB_DIR="$REPO_DIR/src/bin/web"
DEST_DIR="$HOME/code/trigonometry-sprint/assets/public/traversal/web"

if [ ! -d "$WEB_DIR" ]; then
    echo "Web directory not found: $WEB_DIR" >&2
    exit 1
fi

if ! mkdir -p "$DEST_DIR"; then
    echo "Could not create destination: $DEST_DIR" >&2
    exit 1
fi

if ! cp -a "$WEB_DIR/." "$DEST_DIR/"; then
    echo "Could not copy web files to: $DEST_DIR" >&2
    exit 1
fi

echo "Web files copied to: $DEST_DIR"

