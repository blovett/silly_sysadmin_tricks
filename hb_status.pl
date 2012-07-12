#!/usr/bin/perl -w

my $hostname = `/bin/hostname`;
chomp($hostname);
my $hbstatus = `/usr/bin/cl_status hbstatus`;
chomp($hbstatus);

if ($hbstatus =~ m/Heartbeat is running/) {
	my $msg = "";
	my $isbad = 0;

	my $nodestatus = `/usr/bin/cl_status nodestatus $hostname 2>/dev/null`;
	chomp($nodestatus);
	$msg .= "$hostname is $nodestatus. ";
	if ($nodestatus ne 'active') {
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
	print "CRITICAL - Heartbeat service is not running - $hbstatus\n";
	exit (2);
}
