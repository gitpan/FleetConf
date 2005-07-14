package FleetConf::Agent::Parser::Stmt::FOREACH;

use strict;
use warnings;

use FleetConf::Log;

our $VERSION = '0.07';

=head1 NAME

FleetConf::Agent::Parser::Stmt::FOREACH - FOREACH command

=head1 SYNOPSIS

  NAME Some-Agent
  MNEMONIC foo
  WORKFLOW Null

  FOREACH thing IN this.things DO
    # Do something with thing
  END

=head1 DESCRIPTION

This command adds the ability to loop over a list of items.

The BNF for the C<FOREACH> command is:

  agent_command +::= foreach_section

  foreach_section ::= foreach_command agent_command(s) end_command

  foreach_command ::= "FOREACH" variable "IN" list_expression "DO" EOL

These statements are evaluated during I<every> phase of agent execution.

=cut

my $log = FleetConf::Log->get_logger(__PACKAGE__);

if ($log->would_log('info')) {
	$log->info("Extending Grammar: Adding 'foreach_section' to 'agent_command' production.");
	$log->info("Extending Grammar: Adding 'foreach_section' production.");
	$log->info("Extending Grammar: Adding 'foreach_command' productions.");
}

$FleetConf::Agent::Parser::parser->Extend(q(
agent_command:		foreach_section

foreach_section:	foreach_command agent_commands end_command
					{	$return = $item{foreach_command};
						$return->{commands} = $item[2];
					}

foreach_command:	/\bFOREACH\b/ variable /\bIN\b/ <commit> list_expression /\bDO\b/ EOL
					{	$return = bless {
							var  => $item{variable},
							expr => $item{list_expression},
						}, 'FleetConf::Agent::Parser::Stmt::FOREACH'
					}
|					<error?> <reject>
));

sub _run {
	my $self    = shift;
	my $phase   = shift;
	my $ctx     = shift;

	my $list = $self->{expr}->eval($ctx);
	for my $value (@$list) {
		$ctx->push_scope;
		
		$ctx->set($self->{var}, $value);
		for my $command (@{ $self->{commands} }) {
			$log->debug("FOREACH checking to see if we can run '$phase' on '$command'.");
			if ($command->can($phase)) {
				my $result = $command->$phase($ctx);
				return 0 unless $result;
			}
		}
		
		$ctx->pop_scope;
	}

	return 1;
}

sub initializate { shift->_run('initialize', @_) }
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
