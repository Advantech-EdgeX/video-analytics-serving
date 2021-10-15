#!/bin/bash -e
#
# Copyright (C) 2019-2020 Intel Corporation.
#
# SPDX-License-Identifier: BSD-3-Clause
#

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
MQTT_ADDR=127.0.0.1
MQTT_PORT=1883
TOPIC=vaserving
DEVICE=CPU

while [[ "$#" -gt 0 ]]; do
  case $1 in
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
    *)
      ;;
  esac

  shift
done

$SCRIPT_DIR/vaclient/vaclient.sh start $PIPELINE_KIND $MEDIA \
   --rtsp-path vaserving \
   --parameter detection-device $DEVICE \
   --destination type mqtt --destination host ${MQTT_ADDR}:${MQTT_PORT} --destination topic $TOPIC

