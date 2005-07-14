package FleetConf::Agent::Parser::Stmt::LOG;

use strict;
use warnings;

use FleetConf::Log;

our $VERSION = '0.04';

=head1 NAME

FleetConf::Agent::Parser::Stmt::LOG - LOG command

=head1 SYNOPSIS

  NAME Some-Agent
  MNEMONIC foo
  WORKFLOW Null

  LOG DEBUG4 Debug4 message.
  LOG DEBUG3 Debug3 message.
  LOG DEBUG2 Debug2 message.
  LOG DEBUG1 Debug1 message.
  LOG DEBUG Debug message.
  LOG INFO Info message.
  LOG NOTICE Notice message.
  LOG WARNING Warning message.
  LOG ERROR Error message.
  LOG ALERT Alert message.
  LOG EMERGENCY Emergency message.

=head1 DESCRIPTION

The C<LOG> command allows the agent to log messages to the workflow (and possibly to standard error) during the run phase.

The BNF for the C<LOG> command is as follows:

  agent_command +::= log_command

  log_command ::= "LOG" log_level bare_string EOL

  log_level ::= "DEBUG1" | "DEBUG2" | "DEBUG3" | "DEBUG4" | "DEBUG"
              | "INFO" | "NOTICE" | "WARNING" | "ERROR" | "ALERT" | "EMERGENCY"

=cut

my $log = FleetConf::Log->get_logger(__PACKAGE__);

if ($log->would_log('info')) {
	$log->info("Extending Grammar: Adding 'log_command' to 'agent_command' production.");
	$log->info("Extending Grammar: Adding 'log_command' productions.");
	$log->info("Extending Grammar: Adding 'log_level' productions.");
}

$FleetConf::Agent::Parser::parser->Extend(q(
agent_command:		log_command

log_command:		/\bLOG\b/ <commit> log_level bare_string EOL
					{	$return = bless {
							level   => $item{log_level},
							message => $item{bare_string},
						}, 'FleetConf::Agent::Parser::Stmt::LOG'
					}
|					<error?> <reject>

log_level:			/\bDEBUG1\b/	{ $return = 'debug1' }
|					/\bDEBUG2\b/	{ $return = 'debug2' }
|					/\bDEBUG3\b/	{ $return = 'debug3' }
|					/\bDEBUG4\b/	{ $return = 'debug4' }
|					/\bDEBUG\b/		{ $return = 'debug' }
|					/\bINFO\b/		{ $return = 'info' }
|					/\bNOTICE\b/	{ $return = 'notice' }
|					/\bWARNING\b/	{ $return = 'warning' }
|					/\bERROR\b/		{ $return = 'error' }
|					/\bCRITICAL\b/	{ $return = 'critical' }
|					/\bALERT\b/		{ $return = 'alert' }
|					/\bEMERGENCY\b/	{ $return = 'emergency' }
));

sub run {
	my $self = shift;
	my $ctx  = shift;

	my $message = $ctx->interpolate($self->{message});

	$FleetConf::log->log(
		level => $self->{level},
		message => $message,
	);

	return 1;
}

=head1 AUTHOR

Andrew Sterling Hanenkamp, E<lt>hanenkamp@users.sourceforge.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 Andrew Sterling Hanenkamp. All Rights Reserved.

FleetConf is distributed and licensed under the same terms as Perl itself.

=cut

1
