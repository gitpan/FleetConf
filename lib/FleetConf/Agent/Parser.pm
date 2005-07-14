package FleetConf::Agent::Parser;

use strict;
use warnings;

use Parse::RecDescent;

our $VERSION = '0.07';

=head1 NAME

FleetConf::Agent::Parser - The agent language parser for FleetConf

=head1 SYNOPSIS

  NAME Some-Agent
  DESCRIPTION This agent does something.
  VERSION 1.0
  MNEMONIC foo
  WORKFLOW Null

  # Run some commands defined in the plugins

=head1 DESCRIPTION

This parser defines an empty shell of a grammar to be filled by plugin commands. Each plugin defines the most useful bits while this provides the stuff that makes it easy to create the command plugins.

TODO Document the productions available and how to hack in your own command plugins.

=cut

my $grammar = <<'EOGRAMMAR';

agent:				<skip:'[ \t]*(?:#.*)?'>
					prologue agent_body EOF
					{ 	$return = { 
							header   => {
								map { %{ $_ } } @{ $item{prologue} }
							}, 
							commands => $item{agent_body} 
						} 
					}
|					<error>

prologue:			prologue_command(s)
					{	$return = [ map { $_ ? $_ : () } @{ $item[1] } ] }
|					<error>

prologue_command:	prologue_keyword <commit> bare_string EOL
					{	$return = { 
							$item{prologue_keyword} => $item{bare_string} 
						} 
					}
|					EOL 
					{ 	$return = ''; 1 }
|					<error>

prologue_keyword:	"NAME"
|					"DESCRIPTION"
|					"VERSION"
|					"MNEMONIC"
|					"WORKFLOW"

agent_body:			agent_commands

agent_commands:		agent_command(s)
					{	$return = [ map { $_ ? $_ : () } @{ $item[1] } ] }
|					<error>

agent_command:		EOL
					{	$return = ''; 1 }
|					<error>

assignment_operator:
					"="
|					"//="

end_command:		"END" <commit> EOL
|					<error?> <reject>

bare_string:		/[^\r\n]*/

boolean_expression:	"NOT" <commit> boolean_expression
					{	$return = bless {
							expr => $item{boolean_expression},
						}, 'FleetConf::Agent::Parser::NOT'
					}
|					"(" boolean_expression ")"
					{	$return = $item{boolean_expression} }
|					boolean_value boolean_expression_tail
					{	$return = $item{boolean_expression_tail};
						if ($return) {
							$return->{first} = $item{boolean_value};
						} else {
							$return = $item{boolean_value};
						}
					}
|					<error?> <reject>

boolean_expression_tail:
					"OR" <commit> boolean_expression
					{	$return = bless {
							second => $item{boolean_expression},
						}, 'FleetConf::Agent::Parser::OR'
					}
|					"AND" <commit> boolean_expression
					{	$return = bless {
							second => $item{boolean_expression},
						}, 'FleetConf::Agent::Parser::AND'
					}
|					<error?> <reject>
|					{	$return = ''; 1 }

boolean_value:		"TRUE"
					{	$return = bless { 
							value => 1,
						}, 'FleetConf::Agent::Parser::BOOL'
					}
|					"FALSE"
					{	$return = bless {
							value => '',
						}, 'FleetConf::Agent::Parser::BOOL'
					}
|					scalar_expression comparison_operator <commit> scalar_expression
					{	$return = bless {
							first  => $item[1],
							op     => $item[2],
							second => $item[4],
						}, 'FleetConf::Agent::Parser::COMPARISON'
					}
|					scalar_expression in_operator <commit> list_expression
					{	$return = bless {
							first  => $item[1],
							op     => $item[2],
							second => $item[4],
						}, 'FleetConf::Agent::Parser::IN'
					}
|					scalar_expression "MATCHES" <commit> regular_expression
					{	$return = bless {
							first  => $item[1],
							second => $item[4],
						}, 'FleetConf::Agent::Parser::MATCHES'
					}
|					function_call
|					variable
					{	$return = bless {
							var => $item{variable},
						}, 'FleetConf::Agent::Parser::LOOKUP'
					}
|					<error>

comparison_operator: /=|<>|>=|<=|>|</

in_operator:		"IN" | "NOT" "IN" { $return = "NOT IN" }

variable:			/[a-zA-Z_][a-zA-Z0-9_\.]*/

function_call:		variable "(" general_expression(s? /,/) ")"
					{	$return = bless {
							func => $item{variable},
							args => $item[3],
						}, 'FleetConf::Agent::Parser::CALL'
					}

general_expression:	boolean_expression
|					scalar_expression
|					list_expression

scalar_expression:	function_call
|					variable
					{	$return = bless {
							var => $item{variable},
						}, 'FleetConf::Agent::Parser::LOOKUP'
					}
|					string
					{	$return = bless {
							value => $item{string},
						}, 'FleetConf::Agent::Parser::SCALAR'
					}
|					number
					{	$return = bless {
							value => $item{number},
						}, 'FleetConf::Agent::Parser::SCALAR'
					}
|					"(" scalar_expression ")"
					{	$return = $item{scalar_expression} }

list_expression:	variable
					{	$return = bless {
							var => $item{variable},
						}, 'FleetConf::Agent::Parser::LOOKUP'
					}
|					function_call
|					"[" scalar_expression(s? /,/) "]"
					{	$return = bless {
							value => $item[2],
						}, 'FleetConf::Agent::Parser::LIST'
					}

string:				/"((?:[^"]|\\")*)"/ { $return = $1; 1 }

number:				/[+-]?[0-9]+/

regular_expression:	/\/((?:[^\/]|\\\/)*)\/([ims]*)/
					{	$return = bless {
							pattern   => $1,
							modifiers => $2,
						}, 'FleetConf::Agent::Parser::REGEX'
					}

EOL:				/[\r\n]+/

EOF:				/\Z/
EOGRAMMAR

my $log = FleetConf::Log->get_logger(__PACKAGE__);

if ($FleetConf::verbose > 3) {
	$::RD_TRACE = 1;
}
our $parser = Parse::RecDescent->new($grammar);

our $file;

no warnings 'redefine';
sub Parse::RecDescent::_error ($;$) {
	my $error = shift;
	my $line = shift;

	my $message = "Compile Error in $file";

	if ($line) {
		$message .= ", $line: ";
	} else {
		$message .= ": ";
	}

	$message .= $error;

	$log->error($message);
}
use warnings 'redefine';

package FleetConf::Agent::Parser::expression;

use overload 'bool' => sub { ref shift };

package FleetConf::Agent::Parser::LOOKUP;

use base 'FleetConf::Agent::Parser::expression';

use overload '""' => sub { 
	my $self = shift; 
	$self->{var} 
};

sub eval {
	my $self    = shift;
	my $ctx     = shift;

	return $ctx->get($self->{var});
}

package FleetConf::Agent::Parser::SCALAR;

use base 'FleetConf::Agent::Parser::expression';

use overload '""' => sub { 
	my $self = shift;
	'"'.$self->{value}.'"' 
};

sub eval {
	my $self    = shift;
	my $ctx     = shift;

	return $ctx->interpolate($self->{value});
}

package FleetConf::Agent::Parser::COMPARISON;

use base 'FleetConf::Agent::Parser::expression';

use Scalar::Util qw/ looks_like_number /;

use overload '""' => sub { 
	my $self = shift;
	"$self->{first} $self->{op} $self->{second}" };

sub eval {
	my $self    = shift;
	my $ctx     = shift;

	my $first  = $self->{first}->eval($ctx);
	my $second = $self->{second}->eval($ctx);

	return '' unless defined $first && defined $second;

	my $num = looks_like_number($first) && looks_like_number($second);

	if ($self->{op} eq '=') {
		return $num ? $first == $second : $first eq $second;
	} elsif ($self->{op} eq '<>') {
		return $num ? $first != $second : $first ne $second;
	} elsif ($self->{op} eq '>') {
		return $num ? $first > $second : $first gt $second;
	} elsif ($self->{op} eq '<') {
		return $num ? $first < $second : $first lt $second;
	} elsif ($self->{op} eq '>=') {
		return $num ? $first >= $second : $first le $second;
	} else {#$self->{op} eq '<=') {
		return $num ? $first <= $second : $first ge $second;
	}
}

package FleetConf::Agent::Parser::CALL;

use base 'FleetConf::Agent::Parser::expression';

use overload '""' => sub { 
	my $self = shift;
	"$self->{func}(".join(', ', map { "$_" } @{ $self->{args} }).")" };

sub eval {
	my $self      = shift;
	my $ctx       = shift;
	my $namespace = (shift() || 'FleetConf::Functions');

	no strict 'refs';
	my $real_func = "$namespace\::$self->{func}";
	return $real_func->(map { $_->eval($ctx) } @{ $self->{args} });
}

package FleetConf::Agent::Parser::OR;

use base 'FleetConf::Agent::Parser::expression';

use overload '""' => sub { 
	my $self = shift;
	"$self->{first} OR $self->{second}" 
};

sub eval {
	my $self    = shift;
	my $ctx     = shift;

	return $self->{first}->eval($ctx) || $self->{second}->eval($ctx);
}

package FleetConf::Agent::Parser::AND;

use base 'FleetConf::Agent::Parser::expression';

use overload '""' => sub { 
	my $self = shift;
	"$self->{first} AND $self->{second}" 
};

sub eval {
	my $self    = shift;
	my $ctx     = shift;

	return $self->{first}->eval($ctx) && $self->{second}->eval($ctx);
}

package FleetConf::Agent::Parser::NOT;

use base 'FleetConf::Agent::Parser::expression';

use overload '""' => sub { 
	my $self = shift;
	"NOT $self->{expr}" 
};

sub eval {
	my $self    = shift;
	my $ctx     = shift;

	return !$self->{expr}->eval($ctx);
}

package FleetConf::Agent::Parser::IN;

use base 'FleetConf::Agent::Parser::expression';

use Scalar::Util qw/ looks_like_number /;

use overload '""' => sub { 
	my $self = shift;
	"$self->{first} $self->{op} $self->{second}" };

sub eval {
	my $self    = shift;
	my $ctx     = shift;

	my $find = $self->{first}->eval($ctx);
	my $num  = looks_like_number($find);
	my $list = $self->{second}->eval($ctx);

	return '' unless defined $find;

	if ($self->{op} eq 'IN') {
		return grep { 
			$num && looks_like_number($_) ?
				defined $_ && $find == $_ :
				defined $_ && $find eq $_ } @$list;
	} else {
		return grep {
			$num && looks_like_number($_) ?
				defined $_ && $find != $_ :
				defined $_ && $find ne $_ } @$list;
	}
}

package FleetConf::Agent::Parser::LIST;

use base 'FleetConf::Agent::Parser::expression';

use overload '""' => sub { 
	my $self = shift;
	"[ ".join(', ', map { "$_" } @{ $self->{value} })." ]" };

sub FleetConf::Agent::Parser::LIST::eval {
	my $self    = shift;
	my $ctx     = shift;

	return [ map { $_->eval($ctx) } @{ $self->{value} } ];
}

package FleetConf::Agent::Parser::MATCHES;

use base 'FleetConf::Agent::Parser::expression';

use overload '""' => sub {
	my $self = shift;
	"$self->{first} MATCHES $self->{second}"
};

sub eval {
	my $self    = shift;
	my $ctx     = shift;

	my $first  = $self->{first}->eval($ctx);
	my $second = $self->{second}->eval($ctx);

	if (my @matches = $first =~ $second) {
		for my $i (0 .. $#matches) {
			my $var = $i + 1;
			$ctx->set($var => $matches[$i]);
		}

		return 1;
	} else {
		return '';
	}
}

package FleetConf::Agent::Parser::REGEX;

use base 'FleetConf::Agent::Parser::expression';

use overload '""' => sub {
	my $self = shift;
	"/$self->{pattern}/$self->{modifiers}"
};

sub eval {
	my $self    = shift;
	my $ctx     = shift;

	return qr/(?$self->{modifiers})$self->{pattern}/;
}

package FleetConf::Agent::Parser::BOOL;

use base 'FleetConf::Agent::Parser::expression';

use overload '""' => sub {
	my $self = shift;
	return $self->{value} ? 'TRUE' : 'FALSE';
};

sub eval {
	my $self = shift;
	my $ctx  = shift;

	return $self->{value};
}

=head1 SEE ALSO

L<FleetConf::Agent::Parser::Stmt::CALL>, 
L<FleetConf::Agent::Parser::Stmt::CHECK>,
L<FleetConf::Agent::Parser::Stmt::COMMAND>,
L<FleetConf::Agent::Parser::Stmt::ECHO>,
L<FleetConf::Agent::Parser::Stmt::FOREACH>,
L<FleetConf::Agent::Parser::Stmt::LOG>,
L<FleetConf::Agent::Parser::Stmt::PREREQUISITE>,
L<FleetConf::Agent::Parser::Stmt::REQUIRE>,
L<FleetConf::Agent::Parser::Stmt::SET>,
L<FleetConf::Agent::Parser::Stmt::WHEN>

=head1 AUTHOR

Andrew Sterling Hanenkamp, E<lt>hanenkamp@users.sourceforge.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 Andrew Sterling Hanenkamp. All Rights Reserved.

FleetConf is distributed and licensed under the same terms as Perl itself.

=cut

1
