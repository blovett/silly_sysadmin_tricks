#!/usr/bin/perl -w

# Don't use the nagios embedded perl interpreter
# nagios: -epn

use strict;
use LWP::UserAgent;

use lib "/usr/lib/nagios/plugins";
use utils qw(%ERRORS);

use Getopt::Long;
use JSON -support_by_pp;

my ($json_text, $data);
my ($sensor);
my ($temperature);
my ($power_alarm);
my ($exit_code);

my ($message);

my ($opt_sensor, $opt_power, $opt_warn_temp, $opt_crit_temp);

my @tmp = split("/", $0);
my $PROG_NAME = $tmp[-1];

Getopt::Long::Configure('bundling');
GetOptions(
	"s=i"		=> \$opt_sensor,
	"sensor=i"	=> \$opt_sensor,
	"w=i"		=> \$opt_warn_temp,
	"warn=i"	=> \$opt_warn_temp,
	"c=i"		=> \$opt_crit_temp,
	"critical=i"	=> \$opt_crit_temp,
	"p"		=> \$opt_power,
	"power"		=> \$opt_power,
);

#my $high_temp = shift;
#die "Invalid temperature value: $high_temp!\n" if ($high_temp !~ /^\d+/);

sub print_usage {
	print "Usage: $PROG_NAME [OPTIONS]\n";
	print "\t-s, --sensor=ID\tSensor ID to check\n";
	print "\t-w, --warn=tempf\tSensor temperature in fahrenheit to warn on.\n";
	print "\t-c, --critical=tempf\tSensor temperature in fahrenheit to go critical on.\n";
	exit $ERRORS{'UNKNOWN'};
}

sub validate_params {
	#print "opt_sensor = $opt_sensor\n";
	#print "opt_warn_temp = $opt_warn_temp\n";
	#print "opt_crit_temp = $opt_crit_temp\n";

	my $num_params = 3;
	unless ($opt_sensor) {
		print "You must pass a valid sensor id! Either 1 or 2!\n";
		$num_params--;
	} else {
		if ($opt_sensor != 1 && $opt_sensor != 2) {
			$num_params--;
			#print "1num_params=$num_params\n";
		}
	} 

	if (!$opt_power) {
		unless ($opt_warn_temp) {
			$num_params--;
		}

		unless ($opt_crit_temp) {
			$num_params--;
		}
	} else {
		if ($opt_warn_temp || $opt_crit_temp) {
		$num_params--;
		}
	}
	
	if ($num_params < 3) {
		print_usage();
	} else {
		return 1;
	}
}

if (validate_params()) {
	my $ua = LWP::UserAgent->new;
	$ua->timeout(10);
	my $request = HTTP::Request->new("GET", "http://203.0.113.4:8080/getData.htm");
	my $response = $ua->request($request);
	my $code = $response->code();
	#print "response code = $code\n";
	if ($code != 200) {
		$message = "UNKNOWN - Unable to fetch temperature data. Response code was $code.\n";
		$exit_code = $ERRORS{'UNKNOWN'};

		print $message;
		exit $exit_code;
	}

	$json_text = $response->content();
	$data = from_json($json_text, {allow_barekey => 1});

	my $real_sensor = ($opt_sensor - 1);
	
	if ($opt_power) {
		$sensor = $data->{'switch_sen'}[$real_sensor];
		$power_alarm = $sensor->{'alarm'};

		if ($power_alarm == 4) {
			$message = "CRITICAL - Sensor $opt_sensor is showing power offline!";
			$exit_code = $ERRORS{'CRITICAL'};
		} elsif ($power_alarm == 1) {
			$message = "OK - Sensor $opt_sensor is showing power online!";
			$exit_code = $ERRORS{'OK'};
		} else {
			$message = "UNKNOWN - Sensor $opt_sensor is in an unknown state";
			$exit_code = $ERRORS{'UNKNOWN'};
		}
	} else {
		$sensor = $data->{'sensor'}[$real_sensor];
		$temperature = $sensor->{'tempf'};

		# Make sure we've got a valid reading back from the sensor
		if (int($temperature) > 32) {
#		print "first if\n";
			if ( (int($temperature) < $opt_warn_temp) ) {
				$message = "OK - Sensor $opt_sensor is reading $temperature degF";
				$exit_code = $ERRORS{'OK'};
			}

			if ((int($temperature) >= $opt_warn_temp)) {
				$message = "WARNING - Sensor $opt_sensor is reading $temperature degF";
				$exit_code = $ERRORS{'WARNING'};
			}

			if ( (int($temperature) >= $opt_crit_temp) ) {
				$message = "CRITICAL - Sensor $opt_sensor is reading $temperature degF!!";
				$exit_code = $ERRORS{'CRITICAL'};
			} 
		} else {
			$message = "UNKNOWN - Sensor $opt_sensor has a weird reading of $temperature. You should check it out\n";
			$exit_code = $ERRORS{'UNKNOWN'};	
		}
	}

	print "$message\n";
	exit $exit_code;
}
