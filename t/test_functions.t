# vim: set ft=perl :

use strict;

use FleetConf;

print "1..19\n";

$FleetConf::fleetconf_root = 't';

my $fleetconf = FleetConf->instance;
$fleetconf->select_agents(
	sub { shift->header('name') eq 'Test-Functions-Agent' }
);
$fleetconf->run_agents;
