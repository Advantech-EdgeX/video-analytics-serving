#!/bin/bash

sudo ./samples/record_frames/run_server.sh --frame-store samples/record_frames/frame_store

while [ -z `sudo lsof -i:7878` ]; do
    echo "The server side does not exist on port 7878, waiting for ready..."
    sleep 1
done

echo "Port 7878 has already been in use by the server side."
echo "Start to run the client side of video-inference."

sudo ./samples/record_frames/run_client.sh --frame-store samples/record_frames/frame_store