package FleetConf::Agent::Parser::Stmt::COMMAND;

use strict;
use warnings;

use File::Spec;
use FleetConf::Log;

our $VERSION = '0.08';

=head1 NAME

FleetConf::Agent::Parser::Stmt::COMMAND - COMMAND command

=head1 SYNOPSIS

  NAME Some-Agent
  MNEMONIC foo
  WORKFLOW Null

  COMMAND run-something -option1
  OPTION -option2
  EXEC

  EXEC_COMMAND IGNORE_FAILURE cmd.exe /?

  COMMAND foobar
  OPTION_IF (FALSE) --some-option
  EXEC_IF_OPTION

=head1 DESCRIPTION

THis commands adds the ability to execute external system commands.

The BNF for the C<COMMAND> commands is:

  agent_command +::= command_command | option_command | exec_command

  command_command ::= "COMMAND" bare_string EOL
  |                   "EXEC_COMMAND" ("IGNORE_FAILURE")(?) bare_string EOL

  option_command ::= "OPTION" bare_string EOL
  |                  "OPTION_IF" "(" boolean_expression ")" bare_string EOL

  exec_command ::= "EXEC" ("IGNORE_FAILURE")(?) EOL
  |                "EXEC_IF_OPTION" ("IGNORE_FAILURE")(?) EOL

These statements are evaluted only during the run phase.

=head1 EXPLANATION

The proper use of these commands may not be immediately obvious, but they can be used in interesting combinations to produce flexible results.

The simplest command is C<EXEC_COMMAND>. This command always stands on it's own. It immediately executes the given command-line (see L</"COMMAND-LINE EXECUTION"> below).

Otherwise, all commands start with the C<COMMAND> command. This should be followed by the name of the command to execute. The command is not executed unless (and until) a C<EXEC> or C<EXEC_IF_OPTION> command is executed. The command-line can be further modified through the use of C<OPTION> or C<OPTION_IF> commands.

The C<OPTION> command appends any text following it to the command-line specified by the most recent C<COMMAND> command. Each option appends to the end. Thus,

  COMMAND a
  OPTION b
  OPTION c
  OPTION d
  EXEC

would attempt to execute the command-line "C<a b c d>".

The C<OPTION_IF> command is a short-cut for appending items that should only be conditionally added. That is:

  OPTION_IF (expr) string

is short-hand for:

  WHEN expr DO
    OPTION string
  END

The C<EXEC> command causes the command to be immediately executed according to the plan outlined in L</"COMMAND-LINE EXECUTION">. The C<EXEC_IF_OPTION> command also causes the command to be executed immediately, but only if one or more C<OPTION> or C<OPTION_IF> commands was processed since the last C<COMMAND> command. Thus, the following would never execute:

  COMMAND foo
  WHEN FALSE DO
    OPTION bar
  END
  OPTION_IF (FALSE) baz
  EXEC_IF_OPTION

=head1 COMMAND-LINE EXECUTION

Once the command-line has been constructed via the C<COMMAND> and C<OPTION> or C<OPTION_IF> commands and then execution has been requested through C<EXEC> or C<EXEC_IF_OPTION>, the following processing is done:

=over

=item 1.

The first non-whitespace string or first quoted-string found in the command-line is checked to see if it is a relative path or not. (This determination is performed using the C<file_name_is_absolute()> method of L<File::Spec> as determining this is non-trivial and platform dependent.) 

If the path is relative, then the "C<safe_path>" option in the FleetConf configuration is checked to see if an executable can be found in the relative path. If not, then an error occurs and no further processing is performed. If so, the full path to that command is quoted and used to replace the original command name.

If the path is absolute, then the path is quoted and put back into the original command-line.

=item 2.

The command-line is executed and all output from the command is captured and logged.

If C<IGNORE_FAILURE> is specified (either in C<EXEC_COMMAND>, C<EXEC>, or C<EXEC_IF_OPTION>), then the return value of the program is ignored and success is recorded.

Otherwise, a non-zero return from the command-line indicates a failure and the return value is logged as an error and an error is returned by the command.

=back

=cut

my $log = FleetConf::Log->get_logger(__PACKAGE__);

if ($log->would_log('info')) {
	$log->info("Extending Grammar: Adding 'command_command' to 'agent_command' production.");
	$log->info("Extending Grammar: Adding 'option_command' to 'agent_command' production.");
	$log->info("Extending Grammar: Adding 'exec_command' to 'agent_command' production.");
	$log->info("Extending Grammar: Adding 'command_command' productions.");
	$log->info("Extending Gramamr: Adding 'option_command' productions.");
	$log->info("Extending Grammar: Adding 'exec_command' productions.");
}

$FleetConf::Agent::Parser::parser->Extend(q(
agent_command:		command_command
|					option_command
|					exec_command

command_command:	/\bCOMMAND\b/ <commit>  bare_string EOL
					{	$return = bless {
							command => $item{bare_string},
							exec    => 0,
						}, 'FleetConf::Agent::Parser::Stmt::COMMAND'
					}
|					/\bEXEC_COMMAND\b/ <commit> (/\bIGNORE_FAILURE\b/)(?) bare_string EOL
					{	$return = bless {
							command => $item{bare_string},
							ignore  => $item[3],
							exec    => 1,
						}, 'FleetConf::Agent::Parser::Stmt::COMMAND'
					}
|					<error?> <reject>

option_command:		/\bOPTION\b/ <commit> bare_string EOL
					{	$return = bless {
							option => $item{bare_string},
						}, 'FleetConf::Agent::Parser::Stmt::OPTION'
					}
|					/\bOPTION_IF\b/ <commit> '(' boolean_expression ')' bare_string
					{	$return = bless {
							option => $item{bare_string},
							expr   => $item{boolean_expression},
						}, 'FleetConf::Agent::Parser::Stmt::OPTION'
					}
|					<error?> <reject>

exec_command:		/\bEXEC_IF_OPTION\b/ <commit> (/\bIGNORE_FAILURE\b/)(?) EOL
					{	$return = bless {
							conditional => 1,
							ignore  => $item[3],
						}, 'FleetConf::Agent::Parser::Stmt::EXEC'
					}
|					/\bEXEC\b/ <commit> (/\bIGNORE_FAILURE\b/)(?) EOL
					{	$return = bless {
							conditional => 0,
							ignore  => $item[3],
						}, 'FleetConf::Agent::Parser::Stmt::EXEC'
					}
));

sub _run_it {
	my $ctx  = shift;
	my $command_line = shift;
	my $ignore = shift;

	my $command;
	if ($command_line =~ s/([^"]\S*|"(?:[^"]|\\")")//) {
		$command = $1;
	} else {
		$log->error("Cannot find the command to use from command-line '$command_line'.");
		return 0;
	}

	$command =~ s/^"//;
	$command =~ s/"$//;

	unless (File::Spec->file_name_is_absolute($command)) {
		my $safe_path = FleetConf->configuration->{safe_path};
		unless (defined $safe_path && ref($safe_path) eq 'ARRAY') {
			$log->error("No 'safe_path' setting found in the configuration file. Cannot run relative path command '$command'.");
			return 0;
		}

		my $found = 0;
		my @path = @$safe_path;
		for my $path (@path) {
			File::Spec->file_name_is_absolute($path)
				or $path = File::Spec->catfile($FleetConf::fleetconf_root, $path);

			my $command_path = File::Spec->catfile($path, $command);

			$log->notice("Testing for executable named '$command_path'.");
			if (-f $command_path) {
				$log->notice("Found executable named '$command_path'.");
				$command_line = qq("$command_path" $command_line);
				$found++;
				last;
			}
		}

		unless ($found) {
			$log->error("Could not find '$command' in safe path ( ",join(' ', @path)," )");
			return 0;
		}
	}

	$log->notice("$command_line 2>&1");

	my $output = `$command_line 2>&1`;
	my $retval = $?;

	unless ($ignore) {
		$retval == 0
			or $log->error("Program closed with error ",($retval/256),": '$command_line'");
	}

	$log->notice("Program output: ", $output);

	return $retval == 0;
}

sub run {
	my $self = shift;
	my $ctx  = shift;

	my $command_line = $ctx->interpolate($self->{command});

	if ($self->{exec}) {
		my $result = _run_it($ctx, $command_line, $self->{ignore});

		return $self->{ignore} ? 1 : $result;
	} else {
		$ctx->set(__COMMAND__ => $command_line);
		$ctx->set(__OPTIONS__ => 0);

		return 1;
	}
}

sub FleetConf::Agent::Parser::Stmt::OPTION::run {
	my $self = shift;
	my $ctx  = shift;

	if (!defined($self->{expr}) || $self->{expr}->eval($ctx)) {
		my $command_line = $ctx->interpolate($self->{option});

		$ctx->set(__COMMAND__ => $ctx->get('__COMMAND__')." $command_line");
		$ctx->set(__OPTIONS__ => 1);

		return 1;
	} else {
		return 1;
	}
}

sub FleetConf::Agent::Parser::Stmt::EXEC::run {
	my $self = shift;
	my $ctx  = shift;

	if (!$self->{conditional} || $ctx->get('__OPTIONS__')) {
		!$self->{conditional}
			and $log->info("Unconditional EXEC executing '",$ctx->get('__COMMAND__'),"'");
		($self->{conditional} && $ctx->get('__OPTIONS__'))
			and $log->info("Conditional EXEC executing '",$ctx->get('__COMMAND__'),"'");

		my $result = _run_it($ctx, $ctx->get('__COMMAND__'), $self->{ignore});

		return $self->{ignore} ? 1 : $result;
	} else {
		$log->info("No options for Conditional EXEC, skipping command '",$ctx->get('__COMMAND__'),"'");
		return 1;
	}
}

=head1 AUTHOR

Andrew Sterling Hanenkamp, E<lt>hanenkamp@users.sourceforge.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 Andrew Sterling Hanenkamp. All Rights Reserved.

FleetConf is distributed and licensed under the same terms as Perl itself.

=cut

1
