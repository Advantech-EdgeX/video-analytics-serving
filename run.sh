#!/bin/bash

SERVER_PORT=7878
CONTAINER="video-analytics-serving-gstreamer"
DETACH="--detach"
PIPELINE_TYPE_PATH="pipelines/gstreamer"
PIPELINE_CATA_PATH="object_detection/person_vehicle_bike"
SOURCE_TYPE="--src-webcam"
SOURCE_SCALE="--src-scale 1920x1080"

MEDIA=rtsp://admin:admin@172.22.24.162/multimedia/video2
#MEDIA=file:///tmp/person-bicycle-car-detection.mp4
#MEDIA=https://github.com/intel-iot-devkit/sample-videos/blob/master/car-detection.mp4?raw=true

while [[ "$#" -gt 0 ]]; do
	case $1 in
		stop)
			echo docker stop "$CONTAINER"
			docker stop "$CONTAINER"
			exit 0
			;;
		status)
			if [ "$2" ]; then
				eval "curl localhost:${SERVER_PORT}/pipelines/${PIPELINE_CATA_PATH}/$2/status -X GET"
			else
				eval "curl localhost:${SERVER_PORT}/pipelines/${PIPELINE_CATA_PATH} -X GET"
			fi
			exit 1
			;;
		kill)
			if [ "$2" ]; then
				eval "curl localhost:${SERVER_PORT}/pipelines/${PIPELINE_CATA_PATH}/$2 -X DELETE"
			else
				echo "kill expects a value"
			fi
			exit 1
			;;
		record_frames)
			SAMPLE=1
			SAMPLE_DIR="samples/record_frames"
			PIPELINE_CATA_PATH="object_detection/record_frames"
			;;
		*)
			echo "illeagle parameter"
			exit 1
			;;
	esac
	shift
done

if [ "$SAMPLE" -eq 1 ]; then
	CMD="${SAMPLE_DIR}/run_server.sh --frame-store ${SAMPLE_DIR}/frame_store --pipeline ${SAMPLE_DIR}/pipelines/${PIPELINE_CATA_PATH}/pipeline.json ${SOURCE_TYPE} ${SOURCE_SCALE} ${DETACH}"
else
	CMD="./run_server.sh --pipeline ${PIPELINE_TYPE_PATH}/${PIPELINE_CATA_PATH}/pipeline.json ${SOURCE_TYPE} ${SOURCE_SCALE} ${DETACH}"
fi
echo $CMD
eval $CMD

ret=$(lsof -i:7878)
while [ -z "$ret" ]; do
    echo "The server side does not exist on port 7878, waiting for ready..."
    sleep 1
    ret=$(lsof -i:7878)
done
echo "Port 7878 has already been in use by the server side."
echo "Start to run the client side of video-inference."

if [ "$SAMPLE" -eq 1 ]; then
	CMD="./${SAMPLE_DIR}/run_client.sh --frame-store ${SAMPLE_DIR}/frame_store --pipeline-cata $PIPELINE_CATA_PATH --media $MEDIA"
else
	CMD="./run_client.sh --pipeline-cata $PIPELINE_CATA_PATH --media $MEDIA"
fi

echo $CMD
eval $CMD
