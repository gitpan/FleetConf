# vim: set ft=perl :

use strict;

use FleetConf;
use FleetConf::Conf;
use Test::More tests => 3;

my $expect_conf = {
	agent_include => [ 'agents' ],
	perl_include => [ 'extralib' ],
	plugin_include => [ 'plugins', '../blib/plugins' ],
	safe_path => [ 'scripts' ],
	globals => { foo => 1 },
};

my $parser = FleetConf::Conf->new;
my $conf = $parser->parse_file("t/etc/fleet.conf");

is_deeply($conf, $expect_conf);

$FleetConf::fleetconf_root = 't';

is_deeply(FleetConf->configuration, $expect_conf);
is_deeply(FleetConf->instance->configuration, $expect_conf);
