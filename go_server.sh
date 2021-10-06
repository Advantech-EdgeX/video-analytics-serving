#!/bin/sh

#docker/run.sh --enable-rtsp -v /tmp:/tmp --privileged -v /dev:/dev --pipelines pipelines/gstreamer/
#docker/run.sh --enable-rtsp -v /tmp:/tmp --privileged --pipelines pipelines/gstreamer/

./run_server.sh --pipeline pipelines/gstreamer/object_detection/person_vehicle_bike/pipeline.json --src-webcam --src-scale 1920x1080
