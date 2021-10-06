#!/bin/bash -e
#
# Copyright (C) 2019-2020 Intel Corporation.
#
# SPDX-License-Identifier: BSD-3-Clause
#

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
BROKER_ADDR=localhost
BROKER_PORT=1883
TOPIC=vaserving

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --pipeline-cata)
      if [ "$2" ]; then
        PIPELINE_CATA=$2
        shift
      else
        echo "--pipeline_cata expects a value"
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
    *)
      ;;
  esac

  shift
done

$SCRIPT_DIR/vaclient/vaclient.sh start $PIPELINE_CATA $MEDIA \
   --rtsp-path vaserving \
   --destination type mqtt --destination host $BROKER_ADDR:$BROKER_PORT --destination topic $TOPIC
