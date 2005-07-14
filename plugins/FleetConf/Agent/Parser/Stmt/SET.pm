package FleetConf::Agent::Parser::Stmt::SET;

use strict;
use warnings;

use FleetConf::Log;

our $VERSION = '0.07';

=head1 NAME

FleetConf::Agent::Parser::Stmt::SET - SET commands

=head1 SYNOPSIS

  NAME Some-Agent
  MNEMONIC foo
  WORKFLOW Null

  PREREQUISITE_SET foo = 1
  REQUIRE_SET bar = 2
  CHECK_SET baz = 3
  SET quux = 4

=head1 DESCRIPTION

This command declares and sets variables in the current context.

The BNF for the C<SET> commands is:

  agent_command +::= set_command

  set_command ::=
      "PREREQUISITE_SET" variable assignment_operator scalar_expression
  |   "REQUIRE_SET" variable assignment_operator scalar_expression
  |   "CHECK_SET" variable assignment_operator scalar_expression
  |   "SET" variable assignment_operator scalar_expression

The C<PREREQUISITE_SET> command is run during the initialization phase. The C<REQUIRE_SET> command is run during the requirements phase. The C<CHECK_SET> command is run during the check phase. The C<SET> command is run during the run phase.

=cut

my $log = FleetConf::Log->get_logger(__PACKAGE__);

if ($log->would_log('info')) {
	$log->info("Extending Grammar: Adding 'set_command' to 'agent_command' production.");
	$log->info("Extending Grammar: Adding 'set_command' productions.");
}

$FleetConf::Agent::Parser::parser->Extend(q(
agent_command:		set_command

set_command:		/\bPREREQUISITE_SET\b/ <commit> variable assignment_operator scalar_expression EOL
					{	$return = bless { 
							var   => $item{variable},
							op    => $item{assignment_operator},
							expr  => $item{scalar_expression},
							phase => 'initialize',
						}, 'FleetConf::Agent::Parser::Stmt::SET' 
					}
|					/\bREQUIRE_SET\b/ <commit> variable assignment_operator scalar_expression EOL
					{	$return = bless { 
							var   => $item{variable},
							op    => $item{assignment_operator},
							expr  => $item{scalar_expression},
							phase => 'requirements',
						}, 'FleetConf::Agent::Parser::Stmt::SET' 
					}
|					/\bCHECK_SET\b/ <commit> variable assignment_operator scalar_expression EOL
					{	$return = bless { 
							var   => $item{variable},
							op    => $item{assignment_operator},
							expr  => $item{scalar_expression},
							phase => 'check',
						}, 'FleetConf::Agent::Parser::Stmt::SET' 
					}
|					/\bSET\b/ <commit> variable assignment_operator scalar_expression EOL
					{	$return = bless { 
							var   => $item{variable},
							op    => $item{assignment_operator},
							expr  => $item{scalar_expression},
							phase => 'run',
						}, 'FleetConf::Agent::Parser::Stmt::SET' 
					}
|					<error?> <reject>
));

sub initialize {
	my $self = shift;
	my $ctx  = shift;

	return 1 unless $self->{phase} eq 'initialize';

	return $self->_run_it($ctx);
}

sub requirements {
	my $self = shift;
	my $ctx  = shift;

	return 1 unless $self->{phase} eq 'requirements';

	return $self->_run_it($ctx);
}

sub check {
	my $self = shift;
	my $ctx  = shift;

	return 1 unless $self->{phase} eq 'check';

	return $self->_run_it($ctx);
}

sub run {
	my $self    = shift;
	my $ctx     = shift;

	return 1 unless $self->{phase} eq 'run';

	return $self->_run_it($ctx);
}

sub _run_it {
	my $self = shift;
	my $ctx  = shift;

	if ($self->{op} eq '//=' && defined $ctx->get($self->{var})) {
		return 1;
	}

	my $value = $self->{expr}->eval($ctx);
	$ctx->set($self->{var}, $value);

	$log->info("Set $self->{var} = ",
		(UNIVERSAL::isa($value, 'ARRAY')
			? '[ '.join(', ',@$value).' ]'
			: $value));

	return 1;
}

=head1 AUTHOR

Andrew Sterling Hanenkamp, E<lt>hanenkamp@users.sourceforge.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 Andrew Sterling Hanenkamp. All Rights Reserved.

FleetConf is distributed and licensed under the same terms as Perl itself.

=cut

1
