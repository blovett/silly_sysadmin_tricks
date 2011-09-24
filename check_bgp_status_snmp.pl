#!/usr/bin/perl -w

use strict;
use Getopt::Long;

use lib "/usr/lib/nagios/plugins";
use utils qw/%ERRORS/;

my ($host, $community, $peer, $help);

Getopt::Long::Configure('bundling');
GetOptions("host=s"			=>	\$host,
		   "community=s"	=>	\$community,
		   "peer=s"			=>	\$peer,
		   "help"			=>	\$help);

die usage() if (!$host || !$community || !$peer);

my $ip_match = "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)";

if ($peer !~ /$ip_match/) {
	die "IP address passed for peer does not appear valid";
}

#use Data::Dumper;
#print Dumper(\%opt) . "\n";

my $snmp_command = "snmpget -mALL -v2c -c " . $community . " ";
$snmp_command .= $host . " .1.3.6.1.2.1.15.3.1.2.$peer";
#print "command is \'$snmp_command\'\n";
my $snmp_result = `$snmp_command`;
#my $return = $?;

#print "results are:\n$snmp_result\n\nWith an exit code of $return\n";

# BGP4-MIB::bgpPeerState.198.51.100.254 = INTEGER: established(6)
my ($peer_state, $peer_state_int);
if ($snmp_result =~ /bgpPeerState\.$peer \= INTEGER\: (\w+)\((\d)\)/) {
	$peer_state = $1;
	$peer_state_int = $2;
}

if ($peer_state_int != 6) {
	print "CRITICAL: BGP session to $peer is not established.\n";
	exit $ERRORS{'CRITICAL'};
} else {
	print "OK: BGP session to $peer is established\n";
	exit $ERRORS{'OK'};
}

sub usage {
	return
		"Usage: $0 [--host=router_address] [--community=community] [-peer=peer_ip]\n";
}
