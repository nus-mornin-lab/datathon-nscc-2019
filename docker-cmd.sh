#!/bin/sh

cd "$HOME"
SHELL=/bin/bash jupyter lab \
    --no-browser \
    --ip="0.0.0.0" \
    --port=8888 \
    --notebook-dir="$HOME" \
    --allow-root
