#!/usr/bin/perl -w

my $hostname = `/bin/hostname -s`;
chomp($hostname);
`/usr/sbin/crm_mon -1`;

if ($? == 0) {
	my $msg = "";
	my $isbad = 0;

	my $nodestatus = `/usr/sbin/crm_node -l 2>/dev/null | grep $hostname | awk '{print \$NF}'`;
	chomp($nodestatus);

	$msg .= "$hostname is $nodestatus. ";
	if ($nodestatus ne 'member') {
		$isbad = 1;
	}

	if ($isbad) {
		print "CRITICAL - $msg\n";
		exit (2);
	} else {
		print "OK - $msg\n";
		exit (0);
	}
} else {
	print "CRITICAL - Corosync service is not running\n";
	exit (2);
}
