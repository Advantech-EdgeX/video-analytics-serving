#!/bin/bash

SERVER_PORT=7878
MQTT_PORT=1883
CONTAINER="video-analytics-serving-gstreamer"
DETACH="--detach"
PIPELINE_TYPE_PATH="pipelines/gstreamer"
PIPELINE_CATA_PATH="object_detection/person_vehicle_bike"
SOURCE_TYPE="--src-webcam"
SOURCE_SCALE="--src-scale 1920x1080"

MEDIA=rtsp://admin:admin@172.22.24.162/multimedia/video2
#MEDIA=file:///tmp/person-bicycle-car-detection.mp4
#MEDIA=https://github.com/intel-iot-devkit/sample-videos/blob/master/car-detection.mp4?raw=true

run_client() {
	local ret
	local cmd

	ret=$(sudo lsof -i:$SERVER_PORT)
	while [ -z "$ret" ]; do
		echo "The server does not exist on port $SERVER_PORT, waiting for ready..."
		sleep 1
		ret=$(lsof -i:$SERVER_PORT)
	done
	echo "Port $SERVER_PORT has already been in use by server"
	echo "To run video-inference client"

	if [ -n "$SAMPLE" ] && [ "$SAMPLE" -eq 1 ]; then
		cmd="./${SAMPLE_DIR}/run_client.sh --frame-store ${SAMPLE_DIR}/frame_store --pipeline-cata $PIPELINE_CATA_PATH --media $MEDIA"
	else
		cmd="./run_client.sh --pipeline-cata $PIPELINE_CATA_PATH --media $MEDIA"
	fi

	echo $cmd
	eval $cmd
}

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
		client)
			FLAG_CLIENT=1
			;;
		*)
			echo "illeagle parameter"
			exit 1
			;;
	esac
	shift
done

if [ -n "$FLAG_CLIENT" ] && [ "$FLAG_CLIENT" -eq 1 ]; then
	run_client
	exit 0
fi

# check if mqtt broker running
ret=$(sudo lsof -i:$MQTT_PORT)
while [ -z "$ret" ]; do
	echo "The mqtt broker does not exist on port $MQTT_PORT, waiting for ready..."
	sleep 3
	ret=$(lsof -i:$MQTT_PORT)
done
echo "Port $MQTT_PORT has already been in use by mqtt broker"
echo "To run video-inference server."

if [ -n "$SAMPLE" ] && [ "$SAMPLE" -eq 1 ]; then
	CMD="${SAMPLE_DIR}/run_server.sh --frame-store ${SAMPLE_DIR}/frame_store --pipeline ${SAMPLE_DIR}/pipelines/${PIPELINE_CATA_PATH}/pipeline.json ${SOURCE_TYPE} ${SOURCE_SCALE} ${DETACH}"
else
	CMD="./run_server.sh --pipeline ${PIPELINE_TYPE_PATH}/${PIPELINE_CATA_PATH}/pipeline.json ${SOURCE_TYPE} ${SOURCE_SCALE} ${DETACH}"
fi
echo $CMD
eval $CMD

run_client
