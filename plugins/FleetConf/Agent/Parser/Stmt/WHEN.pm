package FleetConf::Agent::Parser::Stmt::WHEN;

use strict;
use warnings;

use FleetConf::Log;

our $VERSION = '0.07';

=head1 NAME

FleetConf::Agent::Parser::Stmt::WHEN - WHEN command

=head1 SYNOPSIS

  NAME Some-Agent
  MNEMONIC foo
  WORKFLOW Null

  WHEN something = something_else DO
    # something!
  END

=head1 DESCRIPTION

This command adds the ability to execute a piece of code conditionally.

The BNF for the C<WHEN> command is:

  agent_command +::= when_section

  when_section ::= when_command agent_command(s) end_command

  when_command ::= "WHEN" boolean_expression "DO"

These statements are evaluated during I<every> phase of agent execution.

=cut

my $log = FleetConf::Log->get_logger(__PACKAGE__);

if ($log->would_log('info')) {
	$log->info("Extending Grammar: Adding 'when_section' to 'agent_command' production.");
	$log->info("Extending Grammar: Adding 'when_section' production.");
	$log->info("Extending Grammar: Adding 'when_command' productions.");
}

$FleetConf::Agent::Parser::parser->Extend(q(
agent_command:		when_section

when_section:		when_command agent_commands end_command
					{	$return = $item{when_command};
						$return->{commands} = $item[2];
					}

when_command:		"WHEN" <commit> boolean_expression "DO" EOL
					{	$return = bless {
							expr => $item{boolean_expression},
						}, 'FleetConf::Agent::Parser::Stmt::WHEN'
					}
|					<error?> <reject>
));


sub _run {
	my $self    = shift;
	my $phase   = shift;
	my $ctx     = shift;

	$ctx->push_scope;
	if ($self->{expr}->eval($ctx)) {
		for my $command (@{ $self->{commands} }) {
			$log->debug("WHEN checking to see if we can run '$phase' on '$command'.");
			if ($command->can($phase)) {
				my $result = $command->$phase($ctx);
				return 0 unless $result;
			}
		}
	}
	$ctx->pop_scope;

	return 1;
}

sub initialize   { shift->_run('initialize', @_) }
sub requirements { shift->_run('requirements', @_) }
sub check        { shift->_run('check', @_) }
sub run          { shift->_run('run', @_) }
sub cleanup      { shift->_run('cleanup', @_) }
sub shutdown     { shift->_run('shutdown', @_) }

=head1 AUTHOR

Andrew Sterling Hanenkamp, E<lt>hanenkamp@users.sourceforge.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 Andrew Sterling Hanenkamp. All Rights Reserved.

FleetConf is distributed and licensed under the same terms as Perl itself.

=cut

1
