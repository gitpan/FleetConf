package FleetConf::Agent::Parser::Stmt::PREREQUISITE;

use strict;
use warnings;

use FleetConf::Log;

our $VERSION = '0.04';

=head1 NAME

FleetConf::Agent::Parser::Stmt::PREREQUISITE - PREREQUISITE command

=head1 SYNOPSIS

  NAME Some-Agent
  MNEMONIC foo
  WORKFLOW Null

  PREREQUISITE hostname() = "onlyhere"

=head1 DESCRIPTION

The C<PREREQUISITE> command runs during the initialize phase and can be used to determine whether or not the workflow should be contacted at all. If any prerequisite fails, then all other phases are skipped.

The BNF for this command is:

  agent_command +::= prerequisite_command

  prerequisite_command ::= "PREREQUISITE" boolean_expression EOL

=cut

my $log = FleetConf::Log->get_logger(__PACKAGE__);

if ($log->would_log('info')) {
	$log->info("Extending Grammar: Adding 'prereq_command' to 'agent_command' production.");
	$log->info("Extending Grammar: Adding 'prereq_command' productions.");
}

$FleetConf::Agent::Parser::parser->Extend(q(
agent_command:		prereq_command

prereq_command:		/\bPREREQUISITE\b/ <commit> boolean_expression EOL
					{	$return = bless {
							expr => $item{boolean_expression},
						}, 'FleetConf::Agent::Parser::Stmt::PREREQUISITE'
					}
|					<error?> <reject>
));

sub initialize {
	my $self = shift;
	my $ctx  = shift;

	$log->would_log('info') &&
		$log->info("Testing prerequisite { ",
			$ctx->interpolate($self->{expr}),
			" }");

	unless ($self->{expr}->eval($ctx)) {
		$log->notice("Quitting. Prerequisite { ",
			$ctx->interpolate($self->{expr}),
			" } does not hold.");
		return 0;
	}

	return 1;
}

=head1 AUTHOR

Andrew Sterling Hanenkamp, E<lt>hanenkamp@users.sourceforge.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 Andrew Sterling Hanenkamp. All Rights Reserved.

FleetConf is distributed and licensed under the same terms as Perl itself.

=cut

1
