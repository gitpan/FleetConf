# vim: set ft=perl :

use strict;

use FleetConf;

print "1..11\n";

$FleetConf::fleetconf_root = 't';

my $fleetconf = FleetConf->instance;
$fleetconf->select_agents(
	sub { shift->header('name') eq 'Test-Foreach-Agent' }
);
$fleetconf->run_agents;

my ($agent) = $fleetconf->agents;
print $agent->filename eq 'test_foreach.agent' ? 'ok' : 'not ok'," 6\n";
print $agent->name eq 'Test-Foreach-Agent' ? 'ok' : 'not ok'," 7\n";
print $agent->description eq 'Simple test for FOREACH.' ? 'ok' : 'not ok'," 8\n";
print $agent->version =~ /\$Rev: \d+ \$/ ? 'ok' : 'not ok'," 9\n";
print $agent->mnemonic eq 'test' ? 'ok' : 'not ok'," 10\n";
print $agent->workflow eq 'Null' ? 'ok' : 'not ok'," 11\n";

