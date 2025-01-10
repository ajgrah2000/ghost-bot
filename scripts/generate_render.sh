#!/bin/bash

ROOT_DIR=$(git rev-parse --show-toplevel)
pushd "$ROOT_DIR"

BASE_INPUT=ghost-bot

SOURCE_DIR=$ROOT_DIR/pcb

WRL_FILE=$ROOT_DIR/output/wrl/$BASE_INPUT.wrl

blender --background --python ./scripts/blender-render.py -- $WRL_FILE
blender --background --python ./scripts/blender-render.py -- $WRL_FILE --output_file=$WRL_FILE.180.png --rotation=180.0
