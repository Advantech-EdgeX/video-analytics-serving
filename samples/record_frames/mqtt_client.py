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
# import pathlib
from urllib.parse import urlparse
import socket

# person-vehicle-bike-detection-crossroad-1016 inference output example
#{'detection':
# {'bounding_box':
#   {'x_max': 0.49997948110103607,
#    'x_min': 0.22809933125972748,
#    'y_max': 0.6331898421049118,
#    'y_min': 0.24341611564159393},
#    'confidence': 0.53 11868786811829,
#    'label_id': 2},
#  'h': 421, 'w': 522, 'x': 438, 'y': 263}
#
# Outputs
# label_id - predicted class ID (0 - non-vehicle, 1 - vehicle, 2 - person)

vas_mqtt_topic = "vaserving"
file_location = "host-file-location"
object_type = 2
scale = 0.3
intrude_ts = 0
intrude_ti_us = 5000000000
debug = 1
wait_sec_record_frame = (100000/1000000.0)
confidence_threshold_default=0.530
send_image_script_name = "img_send.sh"
run_conf = "run.conf"

def get_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.settimeout(0)
    try:
        # doesn't even have to be reachable
        s.connect(('10.255.255.255', 1))
        IP = s.getsockname()[0]
    except Exception:
        IP = '127.0.0.1'
    finally:
        s.close()
    return IP

def parse_run_conf():
    global source_type, media, camip, camport
    source_type = ""
    media = ""
    camip = "127.0.0.1"
    camport = 80
    myvars = {}
    # print("current path {}".format(pathlib.Path().resolve()))
    with open(run_conf) as myfile:
        for line in myfile:
            name, var = line.partition("=")[::2]
            # myvars[name.strip()] = var.strip()
            if "SOURCE_TYPE" == name.strip():
                source_type = var.strip().strip('\"')[6:]
            elif "MEDIA" == name.strip():
                media = var.strip().strip('\"')
        if media == "" or source_type != "ipcam":
            camip = get_ip()
            camport = 7880
        elif source_type == "ipcam":
            o = urlparse(media)
            camip = o.hostname
            if o.port:
                camport = o.port
            else:
                camport = 80

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
    if debug > 99:
        print("on_message() called")
    result = json.loads(msg.payload)
    if not "frame_id" in result:
        print("NO frame_id found in result")
        return
    objects = result.get("objects", [])
    for obj in objects:
        if debug > 4:
            print("{}".format(obj))
        if obj["detection"]["label_id"] == object_type:
            args = user_data
            if obj["detection"]["confidence"] > args.confidence_threshold:
                frame_path = args.frame_store_template % result["frame_id"]
                if debug > 4:
                    print("timestamp={}, ts={}, diff={}, intrude_ti_us={}".format(result["timestamp"], intrude_ts, (result["timestamp"] - intrude_ts), intrude_ti_us))
                if intrude_ts == 0 or result["timestamp"] - intrude_ts > intrude_ti_us:
                    time.sleep(wait_sec_record_frame)
                    if os.path.isfile(frame_path):
                        print("frame_id={:<8d}, timestamp={:<13d}, confidence={:.3f}, label_id {}".format(result["frame_id"], result["timestamp"], obj["detection"]["confidence"], object_type))
                        print("Frame path: {}".format(frame_path))
                        img_process(frame_path, frame_path + ".txt")

                        client_pub = mqtt.Client("P1")
                        client_pub.connect(args.broker_address, args.broker_port)
                        result['camtype'] = source_type
                        result['camurl'] = 'http://' + camip + ':' + str(camport)
                        result['reason'] = 'detect ' + obj["detection"]["label"]
                        # args.topic = AnalyticsData
                        # print("args.topic {}".format(args.topic))
                        client_pub.publish(args.topic, json.dumps(result))

                        img_send(frame_path + ".txt")
                    elif debug > 0:
                        print("frame_path not exist {}".format(frame_path))
                elif debug > 1:
                    print("frame_id={:<8d}, timestamp={:<13d}, confidence={:.3f}, label_id={}, intrude_ts={}, timestamp={}".format(result["frame_id"], result["timestamp"], obj["detection"]["confidence"], obj["detection"]["label_id"], intrude_ts, result["timestamp"]))
                if debug > 4:
                    print("timestamp={}, ts={}".format(result["timestamp"], intrude_ts))
                # record frame successfully, then update intrude timestamp
                intrude_ts = result["timestamp"]
            elif debug > 2:
                print("frame_id={:<8d}, timestamp={:<13d}, confidence={:.3f}, label_id={}".format(result["frame_id"], result["timestamp"], obj["detection"]["confidence"], obj["detection"]["label_id"]))
        elif debug > 3:
            print("frame_id={:<8d}, timestamp={:<13d}, confidence={:.3f}, label_id={}".format(result["frame_id"], result["timestamp"], obj["detection"]["confidence"], obj["detection"]["label_id"]))

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
    parser.add_argument('--confidence-threshold',
                        action='store',
                        type=float,
                        default=confidence_threshold_default,
                        help='inference confidence threshold')
    return parser.parse_args()

if __name__ == "__main__":
    args = get_arguments()
    parse_run_conf()
    print("source_type {}".format(source_type))
    print("camip:port {}:{}".format(camip, camport))
    client = mqtt.Client("VA Serving Frame Retrieval", userdata=args)
    client.on_connect = on_connect
    client.on_message = on_message
    client.connect(args.broker_address, args.broker_port)
    client.loop_forever()
