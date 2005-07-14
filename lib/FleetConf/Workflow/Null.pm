package FleetConf::Workflow::Null;

use strict;
use warnings;

use Carp;

our $VERSION = '0.03';

=head1 NAME

FleetConf::Workflow::Null - Ubiquitous workflow for FleetConf

=head1 DESCRIPTION

This workflow will always be available as "Null" for any agent. It always contains a single, empty "this" record. All the locking and other functionality does nothing.

=cut

sub new {
	my $class = shift;
	bless {}, $class;
}

sub list {
	my $self = shift;
	return ($self);
}

sub get { return undef }
sub set { return undef }
sub begin { return 1 }
sub commit { }
sub rollback { }
sub log { }

=head1 AUTHOR

Andrew Sterling Hanenkamp, E<lt>hanenkamp@users.sourceforge.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 Andrew Sterling Hanenkamp. All Rights Reserved.

FleetConf is distributed and licensed under the same terms as Perl itself.

=cut

1
