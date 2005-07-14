package FleetConf::Conf;

use strict;
use warnings;

use Parse::RecDescent;

our $VERSION = '0.02';

=head1 NAME

FleetConf::Conf - Simple configuration file format

=head1 SYNOPSIS

  array_value [
      foo
      bar
      baz 
      quux
      {
          nested: 1
          hash: 2
      }
      [
          nested
          array
      ]
  ]

  hash_value {
      foo: first
      bar: second
      baz: third
      qux: fourth
	  nested_hash {
          a: 1
          b: 2
      }
	  nested_array [
          alpha
          beta
      ]
  }

  scalar_value = This is an example setting.

=head1 DESCRIPTION

This is a very simple configuration file parser. I've invented a custom format because it was convenient for these needs and removed one more dependency.

=cut

my $grammar = q(

FleetConf_configuration: 
		entries EOF
		{	$return = $item{entries} }
	|	<error>

entries:
		entry(s)
		{	$return = +{ map { ($_->[0] => $_->[1]) } grep { $_ } @{ $item{'entry(s)'} } }; }

entry:
		array
	|	hash
	|	scalar
	|	comment

array: 
		NAME ('=')(?) '[' <commit> array_entries ']'
		{	$return = [ $item{NAME} =>  $item{array_entries} ] }
	|	<error?> <reject>

hash:
		NAME ('=')(?) '{' <commit> entries '}'
		{	$return = [ $item{NAME} => $item{entries} ] }
	|	<error?> <reject>

array_entries:
		array_entry(s)
		{	$return = [ grep { $_ } @{ $item{'array_entry(s)'} } ]; }

array_entry: 
		VALUE
	|	'[' <commit> array_entries ']'
		{	$return = $item{array_entries} }
	|	'{' <commit> entries '}'
		{	$return = $item{entries} }
	|	comment
	|	<error?> <reject>

scalar: 
		NAME '=' VALUE
		{	$return = [ $item{NAME} => $item{VALUE} ] }

comment: 
		/#[^\n\r]*/
		{ 	$return = ''; 1 }

NAME:	
		/\w+/
	|	QUOTED_STRING

VALUE:	
		QUOTED_STRING
	|	/[^\]\}\n\r]*/
		{	$item[1] =~ s/^\s+//;
			$item[1] =~ s/\s+$//; 
			$return = $item[1]; 1 }

QUOTED_STRING:
		/"(?:[^"]|\\\\")*"/
		{	$item[1] =~ s/^"//;
			$item[1] =~ s/"$//;
			$item[1] =~ s/\\\\\\\\/\\\\/;
			$item[1] =~ s/\\\\"/"/; 
			$return = $item[1]; 1 }
	|	/'(?:[^']|\\\\')*'/
		{	$item[1] =~ s/^'//;
			$item[1] =~ s/'$//;
			$item[1] =~ s/\\\\\\\\/\\\\/;
			$item[1] =~ s/\\\\'/'/; 
			$return = $item[1]; 1 }

EOF:
		/\Z/
);

my $parser = Parse::RecDescent->new($grammar);

sub new {
	my $class = shift;

	my $self = bless {
		conf => {},
	}, $class;
}

sub configuration {
	return shift->{conf};
}

sub parse_file {
	my $self = shift;
	my $file = shift;

	open CF, $file or die "Cannot open configuration file $file: $!";
	my $data = join '', <CF>;
	close CF;

	return $self->parse_string($data);
}

sub parse_string {
	my $self = shift;
	my $data = shift;

	my $conf = $parser->FleetConf_configuration($data);

	die "Failed to build configuration." unless $conf;

	$self->{conf} = {
		%{ $self->{conf} },
		%{ $conf },
	};

	return $self->{conf};
}

=head1 AUTHOR

Andrew Sterling Hanenkamp, E<lt>hanenkamp@users.sourceforge.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 Andrew Sterling Hanenkamp. All Rights Reserved.

FleetConf is licensed and distributed under the same terms as Perl itself.

=cut

1
