#!/bin/sh

#set -x

PEER=$1

if [ -z "${PEER}" ]; then
	echo "usage: $0 <peer address>"
	exit 1
fi

PEER_STATUS=$(/usr/bin/sudo /usr/sbin/bgpctl show summary terse | grep $PEER | awk '{print $3}')

if [ ${PEER_STATUS} != "Established" ]; then
	echo "CRTICIAL: BGP session to ${PEER} is not established."
	exit 2;
else
	echo "OK: BGP session to ${PEER} is established."
	exit 0
fi
