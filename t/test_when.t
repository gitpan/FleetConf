# vim: set ft=perl :

use strict;

use FleetConf;

print "1..8\n";

$FleetConf::fleetconf_root = 't';

my $fleetconf = FleetConf->instance;
$fleetconf->select_agents(
	sub { shift->header('name') eq 'Test-When-Agent' }
);
$fleetconf->run_agents;

my ($agent) = $fleetconf->agents;
print $agent->filename eq 'test_when.agent' ? 'ok' : 'not ok'," 3\n";
print $agent->name eq 'Test-When-Agent' ? 'ok' : 'not ok'," 4\n";
print $agent->description eq 'Simple test for WHEN.' ? 'ok' : 'not ok'," 5\n";
print $agent->version =~ /\$Rev: \d+ \$/ ? 'ok' : 'not ok'," 6\n";
print $agent->mnemonic eq 'test' ? 'ok' : 'not ok'," 7\n";
print $agent->workflow eq 'Null' ? 'ok' : 'not ok'," 8\n";

