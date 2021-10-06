#!/bin/bash -e
#
# Copyright (C) 2019-2020 Intel Corporation.
#
# SPDX-License-Identifier: BSD-3-Clause
#

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

PIPELINE=object_detection/person_vehicle_bike
#MEDIA=rtsp://admin:admin@172.22.24.162/multimedia/video2
#MEDIA=file:///home/video-analytics-serving/pipelines/person-bicycle-car-detection.mp4
MEDIA=https://github.com/intel-iot-devkit/sample-videos/blob/master/car-detection.mp4?raw=true
BROKER_ADDR=localhost
BROKER_PORT=1883
TOPIC=vaserving

while [[ "$#" -gt 0 ]]; do
  case $1 in
    *)
      ;;
  esac

  shift
done

$SCRIPT_DIR/vaclient/vaclient.sh start $PIPELINE $MEDIA \
   --rtsp-path vaserving \
   --destination type mqtt --destination host $BROKER_ADDR:$BROKER_PORT --destination topic $TOPIC
