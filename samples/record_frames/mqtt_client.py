'''
* Copyright (C) 2019-2020 Intel Corporation.
*
* SPDX-License-Identifier: BSD-3-Clause
'''

import sys
import argparse
import json
import paho.mqtt.client as mqtt
import cv2
from PIL import Image
import base64,io
import os
import time
import subprocess
# import shlex

vas_mqtt_topic = "vaserving"
file_location = "host-file-location"
object_type = "person"
scale = 0.3
intrude_ts = 0
intrude_ti_us = 5000000000
debug = 1
wait_sec_record_frame = (100000/1000000.0)
confidence_threshold_default=0.530
send_image_script_name = "img_send.sh"

def to_base64(img):
    return base64.b64encode(img).decode('ascii')

def img_resize(img, scale=1):
    height, width = img.size
    return img.resize((int(height*scale), int(width*scale)), Image.BILINEAR)

def img_process(img_file, txt_file):
    im = Image.open(img_file)
    rs_im = img_resize(im, scale)

    imgByteArr = io.BytesIO()
    rs_im.save(imgByteArr, format='JPEG')

    encode = to_base64(imgByteArr.getvalue())

    f = open(txt_file, "w")
    f.write(encode);
    return

def img_send(txt_file):
    # print('getcwd:      ', os.getcwd())
    # print('__file__:    ', __file__)
    # print('basename:    ', os.path.basename(__file__))
    # print('dirname:     ', os.path.dirname(__file__))
    ret = subprocess.call(['sh', os.path.dirname(__file__)+'/'+send_image_script_name, str(txt_file)])
    # subprocess.call(shlex.split('/home/ei52/img_send.sh txt_file'))
    print('Send image return code:   ', ret)
    return

def on_connect(client, user_data, _unused_flags, return_code):
    if return_code == 0:
        args = user_data
        print("Connected to broker at {}:{}".format(args.broker_address, args.broker_port))
        print("Subscribing to topic {}".format(vas_mqtt_topic))
        print("intruder confidence threshold {}".format(args.confidence_threshold))
        print("intruder event skip interval in sec {}".format(intrude_ti_us/1000000000.0))
        print("debug message level {}".format(debug))
        client.subscribe(vas_mqtt_topic)
    else:
        print("Error {} connecting to broker".format(return_code))
        sys.exit(1)

def on_message(_unused_client, user_data, msg):
    global intrude_ts
    if debug > 4:
        print("on_message() called")
    result = json.loads(msg.payload)
    if not "frame_id" in result:
        print("NO frame_id found in result")
        return
    objects = result.get("objects", [])
    for obj in objects:
        if obj["roi_type"] == object_type:
            args = user_data
            if obj["detection"]["confidence"] > args.confidence_threshold:
                frame_path = args.frame_store_template % result["frame_id"]
                if debug > 4:
                    print("timestamp={}, ts={}, diff={}, intrude_ti_us={}".format(result["timestamp"], intrude_ts, (result["timestamp"] - intrude_ts), intrude_ti_us))
                if intrude_ts == 0 or result["timestamp"] - intrude_ts > intrude_ti_us:
                    time.sleep(wait_sec_record_frame)
                    if os.path.isfile(frame_path):
                        print("frame_id={:<8d}, timestamp={:<13d}, confidence={:.3f}, detected {}".format(result["frame_id"], result["timestamp"], obj["detection"]["confidence"], object_type))
                        print("Frame path: {}".format(frame_path))
                        img_process(frame_path, frame_path + ".txt")

                        client_pub = mqtt.Client("P1")
                        client_pub.connect(args.broker_address, args.broker_port)
                        client_pub.publish(args.topic, msg.payload)

                        img_send(frame_path + ".txt")
                    elif debug > 0:
                        print("frame_path not exist {}".format(frame_path))
                elif debug > 1:
                    print("frame_id={:<8d}, timestamp={:<13d}, confidence={:.3f}, roi_type={}, intrude_ts={}, timestamp={}".format(result["frame_id"], result["timestamp"], obj["detection"]["confidence"], obj["roi_type"], intrude_ts, result["timestamp"]))
                if debug > 4:
                    print("timestamp={}, ts={}".format(result["timestamp"], intrude_ts))
                # record frame successfully, then update intrude timestamp
                intrude_ts = result["timestamp"]
            elif debug > 2:
                print("frame_id={:<8d}, timestamp={:<13d}, confidence={:.3f}, roi_type={}".format(result["frame_id"], result["timestamp"], obj["detection"]["confidence"], obj["roi_type"]))
        elif debug > 3:
            print("frame_id={:<8d}, timestamp={:<13d}, confidence={:.3f}, roi_type={}".format(result["frame_id"], result["timestamp"], obj["detection"]["confidence"], obj["roi_type"]))

def get_arguments():
    """Process command line options"""
    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--topic',
                        action='store',
                        type=str,
                        default='AnalyticsData',
                        help='Set EdgeX MQTT topic')
    parser.add_argument('--broker-address',
                        action='store',
                        type=str,
                        default='localhost',
                        help='Set MQTT broker address')
    parser.add_argument('--broker-port',
                        action='store',
                        type=int,
                        default=1883,
                        help='Set MQTT broker port')
    parser.add_argument('--frame-store-template',
                        action='store',
                        type=str,
                        required=True,
                        help='Frame store file name template')
    parser.add_argument('--confidence_threshold',
                        action='store',
                        type=float,
                        default=confidence_threshold_default,
                        help='inference confidence threshold')
    return parser.parse_args()

if __name__ == "__main__":
    args = get_arguments()
    client = mqtt.Client("VA Serving Frame Retrieval", userdata=args)
    client.on_connect = on_connect
    client.on_message = on_message
    client.connect(args.broker_address, args.broker_port)
    client.loop_forever()
