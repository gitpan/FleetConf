# vim: set ft=perl :

use strict;

use FleetConf;
use FleetConf::Log;
use Test::More tests => 77;

$FleetConf::fleetconf_root = 't';
$FleetConf::log_stderr = 0;
$FleetConf::log_file = 'log_test.log';

sub fetch_log {
	open FH, 'log_test.log' or die "Cannot open log_test.log: $!";
	my @lines = <FH>;
	close FH;
	return join '', @lines;
}

my $log = FleetConf::Log->get_logger("t/log.t");

unlink 'log_test.log';

$FleetConf::verbose = 0;
my $fleetconf = FleetConf->instance('I_WANT_A_CLEAN_INSTANCE');
$log->debug4("test debug4");
$log->debug3("test debug3");
$log->debug2("test debug2");
$log->debug1("test debug1");
$log->debug("test debug");
$log->info("test info");
$log->notice("test notice");
$log->warning("test warning");
$log->error("test error");
$log->alert("test alert");
$log->emergency("test emergency");

my $lines = fetch_log;
unlike($lines, qr/test debug4/);
unlike($lines, qr/test debug3/);
unlike($lines, qr/test debug2/);
unlike($lines, qr/test debug1/);
unlike($lines, qr/test debug/);
unlike($lines, qr/test info/);
unlike($lines, qr/test notice/);
like($lines, qr/test warning/);
like($lines, qr/test error/);
like($lines, qr/test alert/);
like($lines, qr/test emergency/);

unlink 'log_test.log';

$FleetConf::verbose = 1;
$fleetconf = FleetConf->instance('I_WANT_A_CLEAN_INSTANCE');
$log->debug4("test debug4");
$log->debug3("test debug3");
$log->debug2("test debug2");
$log->debug1("test debug1");
$log->debug("test debug");
$log->info("test info");
$log->notice("test notice");
$log->warning("test warning");
$log->error("test error");
$log->alert("test alert");
$log->emergency("test emergency");

$lines = fetch_log;
unlike($lines, qr/test debug4/);
unlike($lines, qr/test debug3/);
unlike($lines, qr/test debug2/);
unlike($lines, qr/test debug1/);
unlike($lines, qr/test debug/);
unlike($lines, qr/test info/);
like($lines, qr/test notice/);
like($lines, qr/test warning/);
like($lines, qr/test error/);
like($lines, qr/test alert/);
like($lines, qr/test emergency/);

unlink 'log_test.log';

$FleetConf::verbose = 2;
$fleetconf = FleetConf->instance('I_WANT_A_CLEAN_INSTANCE');
$log->debug4("test debug4");
$log->debug3("test debug3");
$log->debug2("test debug2");
$log->debug1("test debug1");
$log->debug("test debug");
$log->info("test info");
$log->notice("test notice");
$log->warning("test warning");
$log->error("test error");
$log->alert("test alert");
$log->emergency("test emergency");

$lines = fetch_log;
unlike($lines, qr/test debug4/);
unlike($lines, qr/test debug3/);
unlike($lines, qr/test debug2/);
unlike($lines, qr/test debug1/);
unlike($lines, qr/test debug/);
like($lines, qr/test info/);
like($lines, qr/test notice/);
like($lines, qr/test warning/);
like($lines, qr/test error/);
like($lines, qr/test alert/);
like($lines, qr/test emergency/);

unlink 'log_test.log';

$FleetConf::verbose = 3;
$fleetconf = FleetConf->instance('I_WANT_A_CLEAN_INSTANCE');
$log->debug4("test debug4");
$log->debug3("test debug3");
$log->debug2("test debug2");
$log->debug1("test debug1");
$log->debug("test debug");
$log->info("test info");
$log->notice("test notice");
$log->warning("test warning");
$log->error("test error");
$log->alert("test alert");
$log->emergency("test emergency");

$lines = fetch_log;
unlike($lines, qr/test debug4/);
unlike($lines, qr/test debug3/);
unlike($lines, qr/test debug2/);
like($lines, qr/test debug1/);
like($lines, qr/test debug/);
like($lines, qr/test info/);
like($lines, qr/test notice/);
like($lines, qr/test warning/);
like($lines, qr/test error/);
like($lines, qr/test alert/);
like($lines, qr/test emergency/);

unlink 'log_test.log';

$FleetConf::verbose = 4;
$fleetconf = FleetConf->instance('I_WANT_A_CLEAN_INSTANCE');
$log->debug4("test debug4");
$log->debug3("test debug3");
$log->debug2("test debug2");
$log->debug1("test debug1");
$log->debug("test debug");
$log->info("test info");
$log->notice("test notice");
$log->warning("test warning");
$log->error("test error");
$log->alert("test alert");
$log->emergency("test emergency");

$lines = fetch_log;
unlike($lines, qr/test debug4/);
unlike($lines, qr/test debug3/);
like($lines, qr/test debug2/);
like($lines, qr/test debug1/);
like($lines, qr/test debug/);
like($lines, qr/test info/);
like($lines, qr/test notice/);
like($lines, qr/test warning/);
like($lines, qr/test error/);
like($lines, qr/test alert/);
like($lines, qr/test emergency/);

unlink 'log_test.log';

$FleetConf::verbose = 5;
$fleetconf = FleetConf->instance('I_WANT_A_CLEAN_INSTANCE');
$log->debug4("test debug4");
$log->debug3("test debug3");
$log->debug2("test debug2");
$log->debug1("test debug1");
$log->debug("test debug");
$log->info("test info");
$log->notice("test notice");
$log->warning("test warning");
$log->error("test error");
$log->alert("test alert");
$log->emergency("test emergency");

$lines = fetch_log;
unlike($lines, qr/test debug4/);
like($lines, qr/test debug3/);
like($lines, qr/test debug2/);
like($lines, qr/test debug1/);
like($lines, qr/test debug/);
like($lines, qr/test info/);
like($lines, qr/test notice/);
like($lines, qr/test warning/);
like($lines, qr/test error/);
like($lines, qr/test alert/);
like($lines, qr/test emergency/);

unlink 'log_test.log';

$FleetConf::verbose = 6;
$fleetconf = FleetConf->instance('I_WANT_A_CLEAN_INSTANCE');
$log->debug4("test debug4");
$log->debug3("test debug3");
$log->debug2("test debug2");
$log->debug1("test debug1");
$log->debug("test debug");
$log->info("test info");
$log->notice("test notice");
$log->warning("test warning");
$log->error("test error");
$log->alert("test alert");
$log->emergency("test emergency");

$lines = fetch_log;
like($lines, qr/test debug4/);
like($lines, qr/test debug3/);
like($lines, qr/test debug2/);
like($lines, qr/test debug1/);
like($lines, qr/test debug/);
like($lines, qr/test info/);
like($lines, qr/test notice/);
like($lines, qr/test warning/);
like($lines, qr/test error/);
like($lines, qr/test alert/);
like($lines, qr/test emergency/);

unlink 'log_test.log';
