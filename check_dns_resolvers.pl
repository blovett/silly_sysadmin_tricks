#!/usr/bin/perl -w

use strict;

use lib '/usr/lib/nagios/plugins';
use utils qw/%ERRORS/;

my %resolvers;

open(R, "/etc/resolv.conf");
while(<R>) {
	chomp;
	if ($_ =~ /^nameserver\s*(\d+.\d+\.\d+\.\d+)/) {
		$resolvers{$1} = 0;
	}
}
close(R);

my $count = keys(%resolvers);
my @domains = qw/
	www.flickr.com
	www.facebook.com
	www.google.com
	bbc.co.uk
	www.cnn.com
/;

srand();

foreach my $resolver (keys(%resolvers)) {
	my $host = $domains[int(rand(scalar(@domains)))];
	my $ret = system("/usr/lib/nagios/plugins/check_dns -H $host -s $resolver >/dev/null 2>&1");
	
	if ($ret != 0) {
		$count--;
	}
}

my $message;
my $exit_code;

my @fails;
my $critical = 0;

if ($count < keys(%resolvers)) {
	if ($count < 1) {
		push (@fails, "No resolvers are avilable!");
		$critical = 1;
	} elsif ($count == 1) {
		push (@fails, "Only one resolver is available!");
	}
}


if (@fails) {
	print "RESOLVER " . ($critical ? "CRITICAL" : "WARNING") . ":" . join(" ", @fails) . "\n";
	exit ($critical ? $ERRORS{'CRITICAL'} : $ERRORS{'WARNING'});
} else {
	print "RESOLVER OK: Everything is fine!\n";
	exit $ERRORS{'OK'};
}
