package FleetConf::Agent::Parser::Stmt::REQUIRE;

use strict;
use warnings;

use FleetConf::Log;

our $VERSION = '0.05';

=head1 NAME

FleetConf::Agent::Parser::Stmt::REQUIRE - REQUIRE command

=head1 SYNOPSIS

  NAME Some-Agent
  MNEMONIC foo
  WORKFLOW Null

  REQUIRE this.bar = 10

=head1 DESCRIPTION

This command adds the ability to check that certain invariants hold before taking a lock on a record. C<REQUIRE> statements have access to the current workflow record C<this>.

The BNF for C<REQUIRE> statments is:

  agent_command +::= require_command

  require_command ::= "REQUIRE" boolean_expression EOL

These statements are only evaluated during the requirements phase.

=cut

my $log = FleetConf::Log->get_logger(__PACKAGE__);

if ($log->would_log('info')) {
	$log->info("Extending Grammar: Adding 'require_command' to 'agent_command' production.");
	$log->info("Extending Grammar: Adding 'require_command' productions.");
}

$FleetConf::Agent::Parser::parser->Extend(q(
agent_command:		require_command

require_command:	/\bREQUIRE\b/ <commit> boolean_expression EOL
					{	$return = bless {
							expr => $item{boolean_expression},
						}, 'FleetConf::Agent::Parser::Stmt::REQUIRE'
					}
|					<error?> <reject>
));

sub requirements {
	my $self    = shift;
	my $ctx     = shift;

	$log->would_log('info') &&
		$log->info("Testing requirement { ",
			$ctx->interpolate($self->{expr}),
			" }");

	unless ($self->{expr}->eval($ctx)) {
		$log->notice("Quitting. Requirement { ",
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
