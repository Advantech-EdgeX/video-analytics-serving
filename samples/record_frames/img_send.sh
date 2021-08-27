#!/bin/sh

PROTOCOL="http://"
IP_ADDRESS="172.17.0.1"
PORT=49986
URL_PATH="api/v1/resource/sample-json/json"
LOG="/tmp/img_send.log"

if [ ! -z "$1" ]; then
	# /usr/bin/curl --location --request POST 'http://172.17.0.1:49986/api/v1/resource/sample-json/json' --header 'Content-Type: application/json' --data-raw `cat $1`
	/usr/bin/curl --location --request POST "${PROTOCOL}${IP_ADDRESS}:${PORT}/${URL_PATH}" --header 'Content-Type: application/json' --data-raw `cat $1`
fi
