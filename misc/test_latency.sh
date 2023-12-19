#!/usr/bin/env bash

# https://daniel.haxx.se/blog/2010/12/14/add-latency-to-localhost/

if [ "$1" = "on" ]; then
    echo "Adding $2 latency and $3 loss to device lo..."
    sudo tc qdisc add dev lo root handle 1:0 netem delay $2 loss $3
elif [ "$1" = "off" ]; then
    echo "Resetting device lo..."
    sudo tc qdisc del dev lo root
else
    echo "Usage:"
    echo "    $0 on [delay] [loss]"
    echo "    $0 off"
fi
