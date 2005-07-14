# vim: set ft=perl :

use strict;

use FleetConf;

print "1..7\n";

$FleetConf::fleetconf_root = 't';

my $fleetconf = FleetConf->instance;
$fleetconf->select_agents(
	sub { shift->header('name') eq 'Test-Call-Agent' }
);
$fleetconf->run_agents;

my ($agent) = $fleetconf->agents;
print $agent->filename eq 'test_call.agent' ? 'ok' : 'not ok'," 2\n";
print $agent->name eq 'Test-Call-Agent' ? 'ok' : 'not ok'," 3\n";
print $agent->description eq 'Simple test for CALL.' ? 'ok' : 'not ok'," 4\n";
print $agent->version =~ /\$Rev: \d+ \$/ ? 'ok' : 'not ok'," 5\n";
print $agent->mnemonic eq 'test' ? 'ok' : 'not ok'," 6\n";
print $agent->workflow eq 'Null' ? 'ok' : 'not ok'," 7\n";

