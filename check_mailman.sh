#!/bin/sh

# Makes sure Mailman is running .. Try and restart (once) if it isn't .. Page if it doesn't restart.

check_mailman() {
	PS_OUTFILE=`mktemp`
	/bin/ps ax | /bin/grep mailman > $PS_OUTFILE

	ArchRunner_Exists=$(awk '/ArchRunner/{print 1}' $PS_OUTFILE)
	BounceRunner_Exists=$(awk '/BounceRunner/{print 1}' $PS_OUTFILE)
	CommandRunner_Exists=$(awk '/CommandRunner/{print 1}' $PS_OUTFILE)
	IncomingRunner_Exists=$(awk '/IncomingRunner/{print 1}' $PS_OUTFILE)
	NewsRunner_Exists=$(awk '/NewsRunner/{print 1}' $PS_OUTFILE)
	OutgoingRunner_Exists=$(awk '/OutgoingRunner/{print 1}' $PS_OUTFILE)
	VirginRunner_Exists=$(awk '/VirginRunner/{print 1}' $PS_OUTFILE)
	RetryRunner_Exists=$(awk '/RetryRunner/{print 1}' $PS_OUTFILE)

	rm -f $PS_OUTFILE

	TotalCount=$(expr $ArchRunner_Exists + $BounceRunner_Exists + $CommandRunner_Exists + $IncomingRunner_Exists + $NewsRunner_Exists + $OutgoingRunner_Exists + $VirginRunner_Exists + $RetryRunner_Exists)

	return $TotalCount
}

restart_mailman() {
	/usr/local/mailman/bin/mailmanctl stop && \
	sleep 10 && \
	/usr/local/mailman/bin/mailmanctl -s start && \
	sleep 10
}

send_message() {
	_type="$1"

	if [ $_type == "OK" ]; then
		message="Mailman is running!"
		code=0
	elif [ $_type == "CRITICAL" ]; then
		message="One or more Mailman processes aren't running!"
		code=2
	else
		message="We received an unknown response.. Check mailman!"
	fi
	

	echo "$HOSTNAME	MAILMAN_STATUS	$code	$message" | \
		/usr/local/sbin/send_nsca -H 192.0.2.5 -c /etc/send_nsca.cfg
}

check_mailman
if [ $? != 8 ]; then
	# One of the Mailman processes must not be running.. Try restarting, and check again..
	restart_mailman

	# And check ..
	check_mailman

	if [ $? == 8 ]; then
		# Things are cool. Say it!
		send_message "OK"
	else
		# Something must be terribly wrong.. Throw an error
		send_message "CRITICAL"
	fi
else
	# Things are cool .. Say it loud!
	send_message "OK"
fi
