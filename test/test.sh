#!/bin/bash

TEMPLATE='
    {
    "destination": "127.0.0.1:21812",
    "packet": {
    "Code": 4,
    "AVPs":[
        {"User-Name":"629629769-%NUMBER%"},
        {"Framed-IP-Address": "10.0.0.%NUMBER%"},
        {"Acct-Status-Type": "Interim-Update"},
        {"Acct-Session-Id": "Session-%NUMBER%"},
        {"NAS-IP-Address": "200.0.0.%NUMBER%"},
        {"Acct-Session-Time": 3600},
        {"Event-Timestamp": "2023-01-26T03:34:08 UTC"}
    ]
    },
    "secret": "secret",
    "perRequestTimeoutSpec": "3s",
    "tries": 1,
    "serverTries": 1
    }
    '

# Start http2radius
#$HOME/http2radius/http2radius &

# Start radius2elasticsearch
$HOME/radius2elasticsearch/radius2elasticsearch -elasticurl http://localhost:9200 &

# Wait for server started
sleep 1

for i in $(seq 1 1)
do
    request=$(echo $TEMPLATE | sed -e "s/%NUMBER%/$i/g")
    echo $request
# Send request that will be replied echoing all attributes
    echo "$request" | curl -s http://localhost:18080/routeRadiusRequest -X POST --data-binary @-
done

# Name must be cut down
sleep 5
pkill radius2elastics