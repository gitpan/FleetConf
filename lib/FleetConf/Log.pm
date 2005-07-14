package FleetConf::Log;

use strict;
use warnings;

our $VERSION = '0.02';

=head1 NAME

FleetConf::Log - A simple logger for FleetConf

=head1 SYNOPSIS

  use FleetConf::Log;

  $log = FleetConf::Log->get_logger(__PACKAGE__);

  $log->debug("Debug it");
  $log->info("Give some info");
  $log->notice("Notice this");
  $log->warning("I'm warning you");
  $log->error("Uh-oh, an error");
  $log->alert("Alert: very bad stuff");
  $log->emergency("This is an emergency");

  $log->would_log("info") &&
      $log->info("A really big dump: ", Dumper($foo));

  $level = "info";
  $log->log($level, "Another way to log");

=head1 DESCRIPTION

This provides a convenient logging API that won't change even if FleetConf changes underlying logger APIs.

This API provides the following methods:

=over

=item $log = FleetConf::Log-E<gt>get_logger($namespace)

This factory method must be called prior to any other to get an instance of the logger. The C<$namespace> argument is optional, but it is helpful as a quick reference to logging information.

=cut

sub get_logger {
	my $class = shift;
	my $namespace = shift || '';

	return bless {
		log => $FleetConf::log,
		ns  => $namespace,
	}, $class;
}

=item $log-E<gt>log($level, @msg)

This method is the main log method. You can pick your level with one of the following scalar strings:

=over

=item debug4

=item debug3

=item debug2

=item debug1

=item debug

=item info

=item notice

=item warning

=item error

=item alert

=item emergency

=back

Out of these "debug1" is the same as "debug".

The message is passed as one or more scalars in a list that is then joined together using the output field separator, C<$,> (a.k.a. C<$OUTPUT_FIELD_SEPARATOR> or C<$OFS>, if you C<use L<English>>).

=cut

sub log {
	my $self = shift;
	my $level = shift;
	my $message = join $, || '', @_;

	if ($level =~ /^debug\d$/) {
		return unless $self->would_log($level);
		$level = 'debug';
	}

	$self->{log}->log(
		level   => $level,
		message => $message,
	);
}

=item @log-E<gt>debug4(@msg)

=item $log-E<gt>debug3(@msg)

=item $log-E<gt>debug2(@msg)

=item $log-E<gt>debug1(@msg)

=item $log-E<gt>debug(@msg)

=item $log-E<gt>info(@msg)

=item $log-E<gt>notice(@msg)

=item $log-E<gt>warning(@msg)

=item $log-E<gt>error(@msg)

=item $log-E<gt>alert(@msg)

=item $log-E<gt>emergency(@msg)

These are shortcuts for the C<log()> method. That is, this code snippet:

  $log = FleetConf::Log->get_logger;
  for $level (qw( debug info notice warning error alert emergency) ) {
      $log->$level("Output something!");
  }

has the same effect as:

  $log = FleetConf::Log->get_logger;
  for $level (qw( debug info notice warning error alert emergency) ) {
      $log->log($level, "Output something!");
  }

The C<@msg> is concatenated together using the same process as C<log()>.

=cut

sub debug4    { my $self = shift; $self->log("debug4", @_) }
sub debug3    { my $self = shift; $self->log("debug3", @_) }
sub debug2    { my $self = shift; $self->log("debug2", @_) }
sub debug1    { my $self = shift; $self->log("debug1", @_) }
sub debug     { my $self = shift; $self->log("debug", @_) }
sub info      { my $self = shift; $self->log("info", @_) }
sub notice    { my $self = shift; $self->log("notice", @_) }
sub warning   { my $self = shift; $self->log("warning", @_) }
sub error     { my $self = shift; $self->log("error", @_) }
sub alert     { my $self = shift; $self->log("alert", @_) }
sub emergency { my $self = shift; $self->log("emergency", @_) }

=item $test = $log-E<gt>would_log($level)

This allows the module using the logger to determine if logging at the given level will have any output or effect. This method can be used to keep the program from doing complicated or time/processor-consuming work.

=cut

sub would_log {
	my $self = shift;
	my $level = shift;

	if ($level eq "debug1") {
		return $self->{log}->would_log("debug");
	} elsif ($level eq "debug2") {
		return $self->{log}->would_log("debug")
			&& $FleetConf::verbose > 3;
	} elsif ($level eq "debug3") {
		return $self->{log}->would_log("debug")
			&& $FleetConf::verbose > 4;
	} elsif ($level eq "debug4") {
		return $self->{log}->would_log("debug")
			&& $FleetConf::verbose > 5;
	} else {
		return $self->{log}->would_log($level);
	}
}

package FleetConf::Log::Workflow;

use strict;
use warnings;

# This is a helper class to be used with Log::Dispatch
use base 'Log::Dispatch::Output';

sub new {
	my $proto = shift;
	my $class = ref $proto || $proto;

	my %p = @_;

	my $self = bless {}, $class;

	$self->_basic_init(%p);

	$self->{workflow} = $p{workflow};

	return $self;
}

sub log_message {
	my $self = shift;
	my %p = @_;

	$self->{workflow}->log($p{level}, $p{message});
}

=back

=head1 AUTHOR

Andrew Sterling Hanenkamp, E<lt>hanenkamp@users.sourceforge.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 Andrew Sterling Hanenkamp. All Rights Reserved.

FleetConf is distributed and licensed under the same terms as Perl itself.

=cut

1
