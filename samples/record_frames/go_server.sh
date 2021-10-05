#!/bin/bash

# mdeia source can be --src-webcam, --src-ipcam, --src-http, --src-file
# For --src-file changing run_client.sh MEDIA=file:///path/to/media/file, and the path is referenced in container video-analytics-serving-gstreamer

pushd ../..
./samples/record_frames/run_server.sh --frame-store samples/record_frames/frame_store --pipeline samples/record_frames/pipelines/object_detection/record_frames/pipeline.json --src-ipcam --src-scale 1920x1080
popd
