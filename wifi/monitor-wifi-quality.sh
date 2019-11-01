#!/bin/bash

IFACE="wlan0"
HOST=$(hostname)
RRDFILE='/home/pi/wifi-quality.rrd'
PNGPREFIX="/home/pi/${HOST}-wifi-quality"

if [[ ! -e $RRDFILE ]]; then
    # 2 days of 5 min data, 1440 * 1 hr = 60 days, 1825 * 1 day = 5 years, 600 * 1 month = 50 years
    /usr/bin/rrdtool create $RRDFILE \
        --no-overwrite --step 300\
        DS:link:GAUGE:600:U:U \
        DS:rate:GAUGE:600:0:100 \
        DS:signal:GAUGE:600:-256:0 \
        DS:noise:GAUGE:600:-256:0 \
        RRA:AVERAGE:0.5:1:576 \
        RRA:AVERAGE:0.5:12:1440 \
        RRA:AVERAGE:0.5:288:1825 \
        RRA:AVERAGE:0.5:8640:600
fi

iface_stats=$(/sbin/iwconfig $IFACE)
#echo $iface_stats

link=$(echo $iface_stats | /bin/sed -n "s/.*Link Quality=\([0-9]*\).*/\1/p")
total=$(echo $iface_stats | /bin/sed -n "s/.*Link Quality=.*\\/\([0-9]*\).*/\1/p")
rate=$(echo $iface_stats | /bin/sed -n "s/.*Bit Rate=\([0-9\.]*\).*/\1/p")
signal=$(echo $iface_stats | /bin/sed -n "s/.*Signal level=\([-0-9]*\).*/\1/p")
noise=$(echo $iface_stats | /bin/sed -n "s/.*Noise level=\([-0-9]*\).*/\1/p")
if [[ -z $link ]]; then link='NaN'; fi
if [[ -z $rate ]]; then rate='NaN'; fi
if [[ -z $signal ]]; then signal='NaN'; fi
if [[ -z $noise ]]; then noise='NaN'; fi

#echo "Link: $link/$total Rate: $rate Signal: $signal Noise: $noise"

/usr/bin/rrdupdate $RRDFILE N:${link}:${rate}:${signal}:${noise}

for duration in "1d" "1w" "1m"
do
    /usr/bin/rrdtool graph ${PNGPREFIX}-${duration}.png \
        --end now --start -$duration -t "$HOST - $IFACE - $duration" \
        -w 800 -h 200 --lazy \
        DEF:link=$RRDFILE:link:AVERAGE LINE2:link#084887:"Link Quality" \
        GPRINT:link:MIN:"Min\: %4.1lf/$total" \
        GPRINT:link:MAX:"Max\: %4.1lf/$total" \
        GPRINT:link:AVERAGE:"Avg\: %4.1lf/$total" \
        GPRINT:link:LAST:"Current\: %4.1lf/$total\n" \
        DEF:rate=$RRDFILE:rate:AVERAGE LINE2:rate#9BC53D:"Bit Rate" \
        GPRINT:rate:MIN:"Min\: %4.1lf" \
        GPRINT:rate:MAX:"Max\: %4.1lf" \
        GPRINT:rate:AVERAGE:"Avg\: %4.1lf" \
        GPRINT:rate:LAST:"Current\: %4.1lf Mbps\n" \
        DEF:signal=$RRDFILE:signal:AVERAGE LINE2:signal#FA7921:"Signal Level" \
        GPRINT:signal:MIN:"Min\: %4.1lf" \
        GPRINT:signal:MAX:"Max\: %4.1lf" \
        GPRINT:signal:AVERAGE:"Avg\: %4.1lf" \
        GPRINT:signal:LAST:"Current\: %4.1lf dBm\n" > /dev/null
done
