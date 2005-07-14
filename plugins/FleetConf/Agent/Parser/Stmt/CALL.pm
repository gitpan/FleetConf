package FleetConf::Agent::Parser::Stmt::CALL;

use strict;
use warnings;

use FleetConf::Log;

our $VERSION = '0.03';

=head1 NAME

FleetConf::Agent::Parser::Stmt::CALL - CALL command

=head1 SYNOPSIS

  NAME Some-Agent
  MNEMONIC foo
  WORKFLOW Null

  CALL SomeFunction(this.bar, 14)

=head1 DESCRIPTION

This plugin provides the C<CALL> command.

The BNF for the C<CALL> command is:

  agent_command +::= call_command

  call_command ::= "CALL" function_call EOL
 
This command calls a Perl function defined by a plugin in the C<FleetConf::Commands> namespace. This command runs during the run phase.

=cut

my $log = FleetConf::Log->get_logger(__PACKAGE__);

if ($log->would_log('info')) {
	$log->info("Extending Grammar: Adding 'call_command' to 'agent_command' production.");
	$log->info("Extending Grammar: Adding 'call_command' productions.");
}

$FleetConf::Agent::Parser::parser->Extend(q(
agent_command:		call_command

call_command:		/\bCALL\b/ <commit> function_call EOL
					{	$return = bless {
							expr => $item{function_call},
						}, 'FleetConf::Agent::Parser::Stmt::CALL'
					}
|					<error?> <reject>
));

sub run {
	my $self    = shift;
	my $ctx     = shift;

	$log->notice("Calling procedure '$self->{expr}' within namespace 'FleetConf::Commands'.");
	return $self->{expr}->eval($ctx, 'FleetConf::Commands');
}

=head1 AUTHOR

Andrew Sterling Hanenkamp, E<lt>hanenkamp@users.sourceforge.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 Andrew Sterling Hanenkamp. All Rights Reserved.

FleetConf is distributed and licensed under the same terms as Perl itself.

=cut

1
