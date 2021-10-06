#!/bin/bash

SERVER_PORT=7878
CONTAINER="video-analytics-serving-gstreamer"
DETACH="--detach"
PIPELINE_TYPE_PATH="pipelines/gstreamer"
PIPELINE_CATA_PATH="object_detection/person_vehicle_bike"
PIPELINE_FILE="pipeline.json"

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
		*)
			;;
	esac
	shift
done

echo ./run_server.sh --pipeline "${PIPELINE_TYPE_PATH}/${PIPELINE_CATA_PATH}/${PIPELINE_FILE}" --src-webcam --src-scale 1920x1080 "$DETACH"
./run_server.sh --pipeline "${PIPELINE_TYPE_PATH}/${PIPELINE_CATA_PATH}/${PIPELINE_FILE}" --src-webcam --src-scale 1920x1080 "$DETACH"

CMD="docker stats --no-stream video-analytics-serving-gstreamer"
eval $CMD >/dev/null 2>&1
while [ $? -ne 0 ]; do
	echo -n .
	sleep 1
	eval $CMD >/dev/null 2>&1
done
# while [ -z `sudo lsof -i:7878` ]; do
#     echo "The server side does not exist on port 7878, waiting for ready..."
#     sleep 1
# done
# echo "Port 7878 has already been in use by the server side."
# echo "Start to run the client side of video-inference."

echo ./run_client.sh --pipeline-cata "$PIPELINE_CATA_PATH" --media "$MEDIA"
./run_client.sh --pipeline-cata "$PIPELINE_CATA_PATH" --media "$MEDIA"
