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

my $fleetconf = FleetConf->instance;

$FleetConf::log->add(Log::Dispatch::Handle->new(
	name      => 'test_log',
	min_level => 'notice',
	handle    => bless {}, 'MyLogger',
));

$fleetconf->select_agents(
	sub { shift->header('name') eq 'Test-Require-Agent' }
);
$fleetconf->run_agents;

unlike($MyLogger::text, qr/Quitting. Requirement { foo = "1" } does not hold./);
like($MyLogger::text, qr/Quitting. Requirement { bar = "2" } does not hold./);

my ($agent) = $fleetconf->agents;
is($agent->filename, 'test_require.agent');
is($agent->name, 'Test-Require-Agent');
is($agent->description, 'Simple test for REQUIRE.');
like($agent->version, qr/\$Rev: \d+ \$/);
is($agent->mnemonic, 'test');
is($agent->workflow, 'Null');
