# vim: set ft=perl :

use strict;

use FleetConf;
use Log::Dispatch::Handle;
use Test::More tests => 8;

{
	package MyLogger;

	our $text;

	sub print { shift; $text .= join '', @_ }
}

$FleetConf::fleetconf_root = 't';
$FleetConf::no_warnings    = 1;
$FleetConf::log_stderr     = 0;

my $fleetconf = FleetConf->instance;

$FleetConf::log->add(Log::Dispatch::Handle->new(
	name      => 'test_log',
	min_level => 'notice',
	handle    => bless {}, 'MyLogger',
));

$fleetconf->select_agents(
	sub { shift->header('name') eq 'Test-Check-Agent' }
);
$fleetconf->run_agents;

unlike($MyLogger::text, qr/Check failed, { foo = "1" } does not hold./);
like($MyLogger::text, qr/Check failed, { bar = "2" } does not hold./);

my ($agent) = $fleetconf->agents;
is($agent->filename, 'test_check.agent');
is($agent->name, 'Test-Check-Agent');
is($agent->description, 'Simple test for CHECK.');
like($agent->version, qr/\$Rev: \d+ \$/);
is($agent->mnemonic, 'test');
is($agent->workflow, 'Null');
