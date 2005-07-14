# vim: set ft=perl :

use strict;

use FleetConf;
use Log::Dispatch::Handle;
use Test::More tests => 14;

{
	package MyLogger;

	our $text;

	sub print { shift; $text .= join '', @_ }
}

$FleetConf::fleetconf_root = 't';

my $fleetconf = FleetConf->instance;

$FleetConf::log->remove('screen');

$FleetConf::log->add(Log::Dispatch::Handle->new(
	name      => 'test_log',
	min_level => 'debug',
	handle    => bless {}, 'MyLogger',
));

$fleetconf->select_agents(
	sub { shift->header('name') eq 'Test-Log-Agent' }
);
$fleetconf->run_agents;

like($MyLogger::text, qr{\[debug\] ok 1});
like($MyLogger::text, qr{\[info\] ok 2});
like($MyLogger::text, qr{\[notice\] ok 3});
like($MyLogger::text, qr{\[warning\] ok 4});
like($MyLogger::text, qr{\[error\] ok 5});
like($MyLogger::text, qr{\[critical\] ok 6});
like($MyLogger::text, qr{\[alert\] ok 7});
like($MyLogger::text, qr{\[emergency\] ok 8});

my ($agent) = $fleetconf->agents;
is($agent->filename, 'test_log.agent');
is($agent->name, 'Test-Log-Agent');
is($agent->description, 'Simple test for LOG.');
like($agent->version, qr/\$Rev: \d+ \$/);
is($agent->mnemonic, 'test');
is($agent->workflow, 'Null');
