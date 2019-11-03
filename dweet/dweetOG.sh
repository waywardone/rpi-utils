#!/bin/bash

DEBUG=0
PREFIX='XX'
OG_IP='x.x.x.x' # Update with IP address
CID='xxxxxxx'

RETVAL=`curl -s http://${OG_IP}/jc`
# Sample response
# {"dist":141,"door":0,"vehicle":1,"rcnt":6,"fwv":110,"name":"ABC","mac":"xx:xx:xx:xx:xx:xx","cid":xxxxxxx,"rssi":-75}

# curl exits with 7 if it failed to connect to host

if [[ -z "$RETVAL" ]]; then
    #Failure to communicate
    D=0
    N=0
    W=0
    S=0
else
    CID=$(echo $RETVAL | /usr/bin/jq '.cid')
    D=$(echo $RETVAL | /usr/bin/jq '.dist')
    N=$(echo $RETVAL | /usr/bin/jq '.rcnt')
    W=$(echo $RETVAL | /usr/bin/jq '.rssi')
    S=$(echo $RETVAL | /usr/bin/jq '.door')
    V=$(echo $RETVAL | /usr/bin/jq '.vehicle')

    if [[ $S == 0 ]]; then
        S='Closed'
    else
        S='Open'
    fi

    if [[ $V == 1 ]]; then
        V='In'
    elif [[ $V == 0 ]]; then
        V='Out'
    else
        V='Unknown'
    fi
fi

DWEET_ID="${PREFIX}-${CID}"
TS=$(date +%Y%m%d-%H%M%S)
if [[ $DEBUG != 0 ]]; then
    echo "$DWEET_ID $D $I $W $S"
fi

wget -q --post-data="TS=${TS}&State=${S}&Veh=${V}&Number=${N}&Distance=${D}&WiFi=${W}" https://dweet.io/dweet/for/${DWEET_ID} -O /dev/null

