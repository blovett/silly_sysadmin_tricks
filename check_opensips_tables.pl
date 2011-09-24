#!/usr/bin/perl -w

use strict;
use DBI;
use Getopt::Long;
use Pod::Usage;

use lib '/usr/lib/nagios/plugins';
use utils qw/%ERRORS $TIMEOUT/;

my ($opt_db_host, $opt_db_user, $opt_db_pass, $opt_table, $opt_help);
my ($opt_count);

Getopt::Long::Configure('bundling');
GetOptions(
	'host=s'		=>	\$opt_db_host,
	'user=s'		=>	\$opt_db_user,
	'pass=s'		=>	\$opt_db_pass,
	'table=s'		=>	\$opt_table,
	'count=i'		=>	\$opt_count,
	'help|?'		=>	\$opt_help,
);

if (defined($opt_help))
{
	pod2usage("You asked for help? Well, here it is!\n");
}

unless (defined($opt_db_user) && defined($opt_db_pass) &&
	defined($opt_db_host) && defined($opt_table) && defined($opt_count))
{
	pod2usage("You must pass *all* the arguments, noob!\n");
}

my $service_name = "COUNT_" . uc($opt_table);

$SIG{ALRM} = sub {
	print "$service_name UNKNOWN: Script timed out\n";
	exit $ERRORS{'UNKNOWN'};
};

alarm($TIMEOUT);

my $dsn = "DBI:mysql:database=opensips;host=$opt_db_host";
my $dbh = DBI->connect($dsn, $opt_db_user, $opt_db_pass);

my $sql = "select count(*) from ";

SWITCH: {
	$opt_table eq 'location' and do {
		$sql .= "location";
	}, last SWITCH;
	$opt_table eq 'dbaliases' and do {
		$sql .= "dbaliases";
	}, last SWITCH;
	$opt_table eq 'subscriber' and do {
		$sql .= "subscriber";
	}, last SWITCH;
	
	die "Unknown table $opt_table";
}

my $sth = $dbh->prepare($sql);
$sth->execute();

my $count;
$count = ($sth->fetchrow_array)[0];

if ($count < $opt_count)
{
	print "$service_name CRITICAL: The count of rows ($count) is less than it should be ($opt_count)\n";
	exit $ERRORS{'CRITICAL'};
}
else
{
	print "$service_name OK: The count ($count) is within range.\n";	
	exit $ERRORS{'OK'};
}

__DATA__

=head1 NAME

check_opensips_tables.pl - Count the number of rows in a table.

=head1 SYNOPSIS

count_opensips_tables.pl [options]

   Options:
      --host=dbserver		database server to connect to
	  --user=user			database user to connect as
	  --pass=pass			password to connect using
	  --table=table			table to take the count from
	  --help				give me help!
