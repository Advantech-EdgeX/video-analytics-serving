#!/bin/bash -e
#
# Copyright (C) 2019-2020 Intel Corporation.
#
# SPDX-License-Identifier: BSD-3-Clause
#

#!/bin/bash

SCRIPT_DIR=$(dirname $(readlink -f "$0"))
ROOT_DIR=$(readlink -f "$SCRIPT_DIR/../..")

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --pipeline)
      if [ "$2" ]; then
        PIPELINE_FILE=$(readlink -f "$2")
        shift
      else
        echo "--pipeline expects a value"
        exit 1
      fi
      ;;
    --src-webcam)
      if [ -f "$PIPELINE_FILE" ]; then
        sed -i 's/.*\"template\":.*/\"template\": [\"v4l2src name=source ! videoconvert name=videoconvert\",/g' $PIPELINE_FILE
      else
        echo "--src-webcam expects pipeline file given first"
        exit 1
      fi
      ;;
    --src-ipcam | --src-file | --src-http)
      if [ -f "$PIPELINE_FILE" ]; then
        sed -i 's/.*\"template\":.*/\"template\": [\"uridecodebin name=source\",/g' $PIPELINE_FILE
      else
        echo "$1 expects pipeline file given first"
        exit 1
      fi
      ;;
    --src-scale)
      if [ -n "$2" ] && [ -f "$PIPELINE_FILE" ]; then
        string=$2
        array=(`echo $string | tr 'x' ' '`)
        sed -i "s/\".*videoscale.*/\" ! videoscale ! video\/x-raw,width=${array[0]},height=${array[1]}\",/g" $PIPELINE_FILE
        shift
      else
        echo "--src-scale expects pipeline file path and pipeline file should given first"
        exit 1
      fi
      ;;
    *)
      ARGS+="$1 "
      ;;
  esac

  shift
done

VOLUME_MOUNT+="-v /tmp:/tmp "
ARGS=$(echo "$ARGS" | xargs)
echo "$SCRIPT_DIR/docker/run.sh" --network host --privileged -v /dev:/dev --models models --pipelines $SCRIPT_DIR/pipelines/gstreamer $VOLUME_MOUNT --enable-rtsp "$ARGS"
"$SCRIPT_DIR/docker/run.sh" --network host --privileged -v /dev:/dev --models models --pipelines $SCRIPT_DIR/pipelines/gstreamer $VOLUME_MOUNT --enable-rtsp "$ARGS"
