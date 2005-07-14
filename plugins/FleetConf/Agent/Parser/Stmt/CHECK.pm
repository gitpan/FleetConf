package FleetConf::Agent::Parser::Stmt::CHECK;

use strict;
use warnings;

use FleetConf::Log;

our $VERSION = '0.07';

=head1 NAME

FleetConf::Agent::Parser::Stmt::CHECK - CHECK command

=head1 SYNOPSIS

  NAME Some-Agent
  MNEMONIC foo
  WORKFLOW Null

  CHECK this.answer = 42

=head1 DESCRIPTION

This plugin provides the C<CHECK> command, which is used to verify that something is true during the check phase or err before the run phase if not.

The BNF for this command is:

  agent_command +::= check_command

  check_command ::= "CHECK" boolean_expression EOL

=cut

my $log = FleetConf::Log->get_logger(__PACKAGE__);

if ($log->would_log('info')) {
	$log->info("Extending Grammar: Adding 'check_command' to 'agent_command' production.");
	$log->info("Extending Grammar: Adding 'check_command' productions.");
}

$FleetConf::Agent::Parser::parser->Extend(q(
agent_command:		check_command

check_command:		/\bCHECK\b/ <commit> boolean_expression EOL
					{	$return = bless {
							expr => $item{boolean_expression},
						}, 'FleetConf::Agent::Parser::Stmt::CHECK'
					}
|					<error?> <reject>
));

sub check {
	my $self    = shift;
	my $ctx     = shift;

	$log->would_log('info') &&
		$log->info("Testing check { ",
			$ctx->interpolate($self->{expr}),
			" }");

	unless ($self->{expr}->eval($ctx)) {
		$log->error("Check failed, { ",
			$ctx->interpolate($self->{expr}),
			" } does not hold.");
	}

	return 1;
}

=head1 AUTHOR

Andrew Sterling Hanenkamp, E<lt>hanenkamp@users.sourceforge.netE<gt>

=head1 COPYRIGHT AND AUTHOR

Copyright 2005 Andrew Sterling Hanenkamp. All Rights Reserved.

FleetConf is distributed and licensed under the same terms as Perl itself.

=cut

1
