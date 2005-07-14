package FleetConf::Agent::Parser::Stmt::ECHO;

use strict;
use warnings;

use FleetConf::Log;

our $VERSION = '0.05';

=head1 NAME

FleetConf::Agent::Parser::Stmt::ECHO - ECHO command

=head1 SYNOPSIS

  NAME Some-Agent
  MNEMONIC foo
  WORKFLOW Null

  ECHO Say something!

=head1 DESCRIPTION

During the run phase, this simply prints some output to STDOUT. This probably isn't useful very often. The C<LOG> command provides a lot more control for debugging (see L<FleetConf::Agent::Parser::Stmt::LOG>).

The BNF for this command is:

  agent_command +::= echo_command

  echo_command ::= "ECHO" bare_string EOL

=cut

my $log = FleetConf::Log->get_logger(__PACKAGE__);

if ($log->would_log('info')) {
	$log->info("Extending Grammar: Adding 'echo_command' to 'agent_command' production.");
	$log->info("Extending Grammar: Adding 'echo_command' productions.");
}

$FleetConf::Agent::Parser::parser->Extend(q(
agent_command:		echo_command

echo_command:		/\bECHO\b/ <commit> bare_string EOL
					{	$return = bless {
							str => $item{bare_string},
						}, 'FleetConf::Agent::Parser::Stmt::ECHO'
					}
|					<error?> <reject>
));

sub run {
	my $self    = shift;
	my $ctx     = shift;

	my $interp = $ctx->interpolate($self->{str});

	$log->debug("Echoing: $interp");
	print "$interp\n";

	return 1;
}

=head1 AUTHOR

Andrew Sterling Hanenkamp, E<lt>hanenkamp@users.sourceforge.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 Andrew Sterling Hanenkamp. All Rights Reserved.

FleetConf is distributed and licensed under the same terms as Perl itself.

=cut

1
