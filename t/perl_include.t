# vim: set ft=perl :

use strict;

use FleetConf;
use Test::More tests => 2;

$FleetConf::fleetconf_root = 't';

my $instance = FleetConf->instance;
use_ok('Baz');
is($Baz::VERSION, '0.01');
