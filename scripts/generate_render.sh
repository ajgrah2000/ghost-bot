#!/bin/bash

ROOT_DIR=$(git rev-parse --show-toplevel)
pushd "$ROOT_DIR"

BASE_INPUT=ghost-bot

SOURCE_DIR=$ROOT_DIR/pcb
BASE_BLENDER_SCENE=$ROOT_DIR/mech/empty.blend

WRL_FILE=$ROOT_DIR/output/wrl/$BASE_INPUT.wrl

blender -b $BASE_BLENDER_SCENE --python ./scripts/blender-render.py -- $WRL_FILE
blender -b $BASE_BLENDER_SCENE --python ./scripts/blender-render.py -- $WRL_FILE --output_file=$WRL_FILE.180.png --rotation=180.0
