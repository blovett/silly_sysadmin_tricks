#!/usr/bin/perl -w

use strict;
use JSON -support_by_pp;
use Getopt::Long;
use IO::Socket;
use Pod::Usage;
use Data::Dumper;

use lib '/usr/lib/nagios/plugins';
use utils qw/%ERRORS/;

my ($opt_min_count, $opt_testing, $opt_help);
my $sock;

Getopt::Long::Configure('bundling');
GetOptions(
	'count|c=i'	=>	\$opt_min_count,
	'test'		=>	\$opt_testing,
	'help|?'	=>	\$opt_help,
);

if (defined($opt_help)) {
	pod2usage(1);
}

unless (defined($opt_min_count)) {
	$opt_min_count = 2;
}

unless (defined($opt_testing))
{
	$sock = IO::Socket::INET->new(
									PeerAddr	=>	'localhost',
									PeerPort	=>	'25061',
									Proto		=>	'tcp',
	);
	die "Could not create socket: $!\n" unless $sock;
}

my $json_text = '';
unless (defined($opt_testing))
{
	print $sock "summary\r\n";
	$json_text = <$sock>;
	close($sock);
}
else
{
	# both relays connected
	$json_text = '[{"status": "active", "uptime": 169510, "stream_count": {}, "ip": "203.0.113.85", "session_count": 0, "version": "2.4.2", "bps_relayed": 0}, {"status": "active", "uptime": 144, "stream_count": {}, "ip": "203.0.113.86", "session_count": 0, "version": "2.4.2", "bps_relayed": 0}]';
	# one relay connected
#	$json_text = '[{"status": "active", "uptime": 144, "stream_count": {}, "ip": "203.0.113.86", "session_count": 0, "version": "2.4.2", "bps_relayed": 0}]';
	# no relays connected
	#$json_text = '[]';
}

my $data = from_json($json_text);
#print Dumper($data)."\n";
#die();

my $count = @$data;
my @fails;
my $critical = 0;

foreach my $proxy (@$data) 
{
	if ( $proxy->{status} ne 'active' )
	{
		push @fails, "Media proxy $proxy->{ip} is not active";
		$count --;
	}
}

if ( $count < 1 )
{
	push @fails, "No media proxies available";
	$critical = 1;
}
elsif ($count < $opt_min_count)
{
	push @fails, "Minimum relay count ($opt_min_count) is not met.";
}

if ( @fails )
{
	print "" . ( $critical ? "CRITICAL " : "WARNING " ) . join ("/",@fails) . "\n";
	exit ($critical ? $ERRORS{'CRITICAL'} : $ERRORS{'WARNING'});
}
else
{
	print "OK MediaProxy has enough relays connected\n";
	exit $ERRORS{'OK'};
}

__END__

=head1 NAME

check_mediaproxy.pl -- Checks that the correct number of MediaProxy relays are connected to the dispatcher.

=head1 SYNOPSIS

check_mediaproxy.pl [options]

	Options:
		--count, -c NUM		Minimum number of relays before a warning is thrown.
		--test			Put into testing / debugging mode. Don't try and connect to the management interface.
		--help, -?		This help.

