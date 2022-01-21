#!/bin/bash -e
#
# Copyright (C) 2019-2020 Intel Corporation.
#
# SPDX-License-Identifier: BSD-3-Clause
#

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
SAMPLES_DIR=$(dirname $SCRIPT_DIR)
ROOT_DIR=$(dirname $SAMPLES_DIR)
MQTT_ADDR=127.0.0.1
MQTT_PORT=1883
TOPIC=vaserving
SPECIFIER="%08d"
DEVICE=CPU

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --frame-store)
      if [ "$2" ]; then
        FRAME_STORE=$(readlink -f "$2")
        shift
      else
        echo "--frame-store expects a value"
        exit 1
      fi
      ;;
    --pipeline-kind)
      if [ "$2" ]; then
        PIPELINE_KIND=$2
        shift
      else
        echo "--pipeline-kind expects a value"
        exit 1
      fi
      ;;
    --media)
      if [ "$2" ]; then
        MEDIA=$2
        shift
      else
        echo "--media expects a value"
        exit 1
      fi
      ;;
    --mqtt-addr)
      if [ "$2" ]; then
        MQTT_ADDR=$2
        shift
      else
        echo "--mqtt-addr expects a value"
        exit 1
      fi
      ;;
    --mqtt-port)
      if [ "$2" ]; then
        MQTT_PORT=$2
        shift
      else
        echo "--mqtt-port expects a value"
         exit 1
      fi
      ;;
    --device)
      if [ "$2" ]; then
        DEVICE=$2
        shift
      else
        echo "--device expects a value"
        exit 1
      fi
      ;;
    --confidence-threshold)
      if [ "$2" ]; then
        CONF_THRE="--confidence-threshold $2"
        shift
      else
        echo "$0 --confidence-threshold expects a value!!!"
      fi
      ;;
    *)
      ;;
  esac

  shift
done

if [ -z $FRAME_STORE ]; then
   echo Frame store path not specified
   exit 1
fi

FILE_LOCATION=$FRAME_STORE/$SPECIFIER.jpg
$ROOT_DIR/vaclient/vaclient.sh start $PIPELINE_KIND $MEDIA \
   --rtsp-path vaserving \
   --parameter detection-device $DEVICE \
   --parameter file-location $FILE_LOCATION \
   --destination type mqtt --destination host ${MQTT_ADDR}:${MQTT_PORT} --destination topic $TOPIC
echo Frame store file location = $FILE_LOCATION
echo Starting mqtt client
python3 $SCRIPT_DIR/mqtt_client.py --broker-address $MQTT_ADDR --broker-port $MQTT_PORT --frame-store-template $FILE_LOCATION $CONF_THRE
