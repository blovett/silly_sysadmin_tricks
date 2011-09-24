#!/bin/sh

IP="$1"

BAD_MAC=0

if [ -z "$IP" ]; then
	echo "You must specify an IP address to check!"
	exit 3
fi

if [ $IP == "10.10.10.11" ]; then
	HOST="igw1"
	SERVICE="IGW1_IP"
	MAC_ADDR="DE:AD:BE:EF:CA:FE"
elif [ $IP == "10.10.10.12" ]; then
	HOST="igw2"
	SERVICE="IGW2_IP"
	MAC_ADDR="DE:CA:FB:AD:00:FF"
else
	echo "You specified an invalid IP address to check."
	exit 255
fi

LOG=`mktemp`

/sbin/arping -I eth1 -c 2 $IP 2>&1 >$LOG

NUM_RESP=$(awk '/Received/{print $2}' $LOG)
MAC_GOT_TMP=$(awk '/Unicast reply/{print $5}' $LOG)
echo "$MAC_GOT_TMP" | grep -q $MAC_ADDR

if [ $? != 0 ]; then
	BAD_MAC=1
fi

if [ $BAD_MAC != 0 ]; then
	echo "$HOST	$SERVICE	2	Possible invalid host broadcasting ownership of IP address ($IP)" | /usr/local/sbin/send_nsca -H 192.0.2.5 -c /etc/send_nsca.cfg
else
	echo "$HOST	$SERVICE	0	Correct host has ownership of IP address $IP" | /usr/local/sbin/send_nsca -H 192.168.2.5 -c /etc/send_nsca.cfg
fi

/bin/rm $LOG
