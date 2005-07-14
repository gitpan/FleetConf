# vim: set ft=perl :

use strict;

use FleetConf;
use Test::More tests => 1;

undef $FleetConf::fleetconf_root;

eval { FleetConf->instance };
ok($@, "Should fail if fleetconf_root is unset.");
