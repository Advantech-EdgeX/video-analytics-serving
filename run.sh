#!/bin/bash

source run.conf

run_client() {
	local ret
	local cmd

	ret=$(sudo lsof -i:$VAS_SERVER_PORT)
	while [ -z "$ret" ]; do
		echo "The server does not exist on port $SERVER_PORT, waiting for ready..."
		sleep 1
		ret=$(lsof -i:$VAS_SERVER_PORT)
	done
	echo "Port $VAS_SERVER_PORT has already been in use by server"
	echo "To run video-inference client"

	[ "$SOURCE_TYPE" = "--src-webcam" ] && MEDIA="uri://webcam"
	if [ -n "$SAMPLE" ] && [ "$SAMPLE" -eq 1 ]; then
		cmd="./${SAMPLE_DIR}/run_client.sh --mqtt-addr ${MQTT_ADDR} --mqtt-port ${MQTT_PORT} --frame-store ${SAMPLE_DIR}/frame_store --pipeline-kind $PIPELINE_KIND --media $MEDIA --device $DEVICE"
	else
		cmd="./run_client.sh --mqtt-addr ${MQTT_ADDR} --mqtt-port ${MQTT_PORT} --pipeline-kind $PIPELINE_KIND --media $MEDIA --device $DEVICE"
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
				eval "curl localhost:${VAS_SERVER_PORT}/pipelines/${PIPELINE_KIND}/$2/status -X GET"
			else
				eval "curl localhost:${VAS_SERVER_PORT}/pipelines/${PIPELINE_KIND} -X GET"
			fi
			exit 1
			;;
		kill)
			if [ "$2" ]; then
				eval "curl localhost:${VAS_SERVER_PORT}/pipelines/${PIPELINE_KIND}/$2 -X DELETE"
			else
				echo "kill expects a value"
			fi
			exit 1
			;;
		record_frames)
			SAMPLE=1
			SAMPLE_DIR="samples/record_frames"
			PIPELINE_KIND="object_detection/record_frames"
			MODEL_TYPE="object_detection"
			MODEL_NAME="person_vehicle_bike_1016"
			;;
		server)
			FLAG_SERVER=1
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
</dev/tcp/${MQTT_ADDR}/${MQTT_PORT}
while [ "$?" -ne 0 ]; do
	echo "Connection to mqtt broker on ${MQTT_ADDR}:${MQTT_PORT} failed."
	sleep 3
	</dev/tcp/${MQTT_ADDR}/${MQTT_PORT}
done
echo "Connection to mqtt broker on ${MQTT_ADDR}:${MQTT_PORT} succeeded."
echo "To run video-inference server."

if [ -n "$SAMPLE" ] && [ "$SAMPLE" -eq 1 ]; then
	CMD="${SAMPLE_DIR}/run_server.sh --frame-store ${SAMPLE_DIR}/frame_store --pipeline ${SAMPLE_DIR}/pipelines/${PIPELINE_KIND}/pipeline.json ${SOURCE_TYPE} ${SOURCE_SCALE} --model-type $MODEL_TYPE --model-name $MODEL_NAME ${DETACH}"
else
	CMD="./run_server.sh --pipeline ${PIPELINE_TYPE}/${PIPELINE_KIND}/pipeline.json ${SOURCE_TYPE} ${SOURCE_SCALE} --model-type $MODEL_TYPE --model-name $MODEL_NAME ${DETACH}"
fi
echo $CMD
eval $CMD

if [ -z "$FLAG_SERVER" ]; then
	run_client
fi
