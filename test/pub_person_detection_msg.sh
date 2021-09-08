#!/bin/sh

mosquitto_pub -h 172.17.0.1 -t AnalyticsData -m '{
    "objects": [
        {
            "detection": {
                "bounding_box": {
                    "x_max": 0.38773128390312195,
                    "x_min": 0.34196576476097107,
                    "y_max": 0.7224166393280029,
                    "y_min": 0.44836363196372986
                },
                "confidence": 0.9989022016525269,
                "label_id": 0
            },
            "h": 296,
            "w": 88,
            "x": 657,
            "y": 484
        },
        {
            "detection": {
                "bounding_box": {
                    "x_max": 0.3294890522956848,
                    "x_min": 0.26992881298065186,
                    "y_max": 0.7818905115127563,
                    "y_min": 0.4415630102157593
                },
                "confidence": 0.9906069040298462,
                "label_id": 0
            },
            "h": 368,
            "w": 114,
            "x": 518,
            "y": 477
        },
        {
            "detection": {
                "bounding_box": {
                    "x_max": 0.34684106707572937,
                    "x_min": 0.3133629858493805,
                    "y_max": 0.6751165986061096,
                    "y_min": 0.4645377993583679
                },
                "confidence": 0.9545181393623352,
                "label_id": 0
            },
            "h": 227,
            "w": 64,
            "x": 602,
            "y": 502
        }
    ],
    "resolution": {
        "height": 1080,
        "width": 1920
    },
    "timestamp": 113546040578
}'