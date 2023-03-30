#!/bin/bash

TEMPLATE='
    {
    "destination": "127.0.0.1:21813",
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

# Start radius2elasticsearch
pushd $HOME/radius2elasticsearch > /dev/null
./radius2elasticsearch -elasticurl http://localhost:9200 > /dev/null &
popd > /dev/null

# Start http2radius
pushd $HOME/http2radius > /dev/null
./http2radius > /dev/null &
popd > /dev/null

# Wait for server started
sleep 5

for i in $(seq 1 5)
do
    request=$(echo $TEMPLATE | sed -e "s/%NUMBER%/$i/g")
    echo "request >>"
    echo $request
# Send request that will be replied echoing all attributes
    echo "response <<"
    echo "$request" | curl -s http://localhost:18080/routeRadiusRequest -X POST --data-binary @-
    echo
    echo 
done

sleep 5

# Find one session
[[ `curl -s http://localhost:9200/_all/_search?q=IPAddress:10.0.0.1|jq '.hits.total.value'` == "1" ]] || ( echo "[FAILED] entry not found" && exit )

# Get the number of written sessions with the first IP address
[[ `curl -s http://localhost:9200/_all/_search|jq '.hits.total.value'` == "5" ]] || ( echo "[FAILED] bad number of entries" && exit )

# Name of process must be cut down
echo [OK]
pkill radius2elastics
pkill http2radius