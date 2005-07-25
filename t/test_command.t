# vim: set ft=perl :

use strict;

use FleetConf;
use Log::Dispatch::Handle;
use Test::More tests => 18;

-x 't/scripts/echo.pl' or chmod 0755, 't/scripts/echo.pl';

{
	package MyLogger;

	our $text;

	sub print { shift; $text .= join '', @_ }
}

$FleetConf::fleetconf_root = 't';

my $fleetconf = FleetConf->instance;

$FleetConf::log->add(Log::Dispatch::Handle->new(
	name      => 'test_log',
	min_level => 'info',
	handle    => bless {}, 'MyLogger',
));

$fleetconf->select_agents(
	sub { shift->header('name') eq 'Test-Command-Agent' }
);
$fleetconf->run_agents;

like($MyLogger::text, qr{\[notice\] "t/scripts/echo\.pl"\s+foo 2>&1});
like($MyLogger::text, qr{\[notice\] Program output: foo});
like($MyLogger::text, qr{\[notice\] "t/scripts/echo\.pl"\s+bar 2>&1});
like($MyLogger::text, qr{\[notice\] Program output: bar});
like($MyLogger::text, qr{\[notice\] "t/scripts/echo\.pl"\s+baz 2>&1});
like($MyLogger::text, qr{\[notice\] Program output: baz});
like($MyLogger::text, qr{\[notice\] "t/scripts/echo\.pl"\s+quux 2>&1});
like($MyLogger::text, qr{\[notice\] Program output: quux});
unlike($MyLogger::text, qr{\[notice\] "t/scripts/echo\.pl"\s+quuux 2>&1});
unlike($MyLogger::text, qr{\[notice\] Program output: quuux});
like($MyLogger::text, qr{\[notice\] "t/scripts/echo\.pl"\s+quuuux 2>&1});
like($MyLogger::text, qr{\[notice\] Program output: quuuux});

my ($agent) = $fleetconf->agents;
is($agent->filename, 'test_command.agent');
is($agent->name, 'Test-Command-Agent');
is($agent->description, 'Simple test for COMMAND and relatives.');
like($agent->version, qr/\$Rev: \d+ \$/);
is($agent->mnemonic, 'test');
is($agent->workflow, 'Null');
