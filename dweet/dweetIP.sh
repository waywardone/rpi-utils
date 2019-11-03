#!/bin/bash

DEBUG=0
PREFIX="XX"
HOST=$(hostname)
MACHINE_ID=$(cat /etc/machine-id  | head -c 8)
DWEET_ID="${PREFIX}-${HOST}-${MACHINE_ID}"
IP=$(hostname -I | awk '{print $1}')
TS=$(date +%Y%m%d-%H%M%S)

if [[ $DEBUG != 0 ]]; then
    echo "$DWEET_ID $IP"
fi

wget -q --post-data="TS=${TS}&IP=${IP}" https://dweet.io/dweet/for/${DWEET_ID} -O /dev/null

