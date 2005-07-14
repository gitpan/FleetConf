package FleetConf::Agent::Context;

use strict;
use warnings;

use Data::Dumper;

our $VERSION = '0.05';

=head1 NAME

FleetConf::Agent::Context - Agent context

=head1 DESCRIPTION

This is the API that grants access to the runtime context of an agent. This context provides for a simple way of accessing the current workflow record, declaring, fetching, and storing values in lexically scoped variables, allocating record locks, performing commits and rollbacks, and logging to the workflow record (though, these latter features should not be used directly in most instances).

This class defines the following methods:

=over

=item $ctx = FleetConf::Agent::Context-E<gt>new($this)

Creates a new workflow record context. The C<$this> argument is used as the current workflow record and must be a reference to a hash (an empty anonymous reference is fine). 

A new context object is returned.

=cut

sub new {
	my $class = shift;
	my $this  = shift;

#	$FleetConf::log->would_log('debug') &&
#		$FleetConf::log->debug("Setting up context with: ",
#			Data::Dumper->Dump(
#				[$this,\%FleetConf::globals],
#				['this', 'FleetConf::globals'],
#			));

	return bless {
		this    => $this,
		changes => { },
		sym     => [ \%FleetConf::globals ],
	}, $class;
}

=item $value = $ctx-E<gt>get($key)

Fetches the value C<$value> from the context variable C<$key> or returns C<undef> if no such value is found. The returned value will always be a scalar value (i.e., possibly a reference to something, but still a single scalar).

=cut

sub get {
	my ($self, $key) = @_;

	if ($key eq 'this') {
		return $self->{this};
	} elsif ($key =~ s/^this\.//) {
		return $self->{this}->get($key);
	} else {
		for my $tab (@{ $self->{sym} }) {
			if (exists $tab->{$key}) { return $tab->{$key} }
		}
		return undef;
	}
}

=item $ctx-E<gt>set($key, $value)

Sets the value for context variable named C<$key> to the value given in C<$value>. The given value must be a scalar and will overwrite any current value.

=cut

sub set {
	my ($self, $key, $value) = @_;

	if ($key =~ s/^this\.//) {
		return $self->{this}->set($key, $value);
	} else {
		for my $tab (@{ $self->{sym} }) {
			if (exists $tab->{$key}) { return $tab->{$key} = $value }
		}
		return $self->{sym}[0]{$key} = $value;
	}
}

=item $ctx-E<gt>push_scope

This method pushes a frame onto the lexical stack within the current context. Variables declared in a nested scope are deallocated when the C<pop_scope> method pops that scope off the lexical stack.

=cut

sub push_scope { 
	my $self = shift;
	unshift @{ $self->{sym} }, { };
}

=item $ctx-E<gt>pop_scope

This method pops the top frame from the lexical stack within the current context. Any variables held within that frame are deallocated and lose their value.

=cut

sub pop_scope {
	my $self = shift;
	shift @{ $self->{sym} };
}

=item $success = $ctx-E<gt>begin($mnemonic)

B<Do not use this unless you know exactly what you're doing.>

This attempts to acquire the named (C<$mnemonic>) lock on the current workflow record and returns whether or not the lock succeeded.

=cut

sub begin {
	my $self = shift;

	return $self->{this}->begin(@_);
}

=item $ctx-E<gt>commit

B<Do not use this unless you know exactly what you're doing.>

This tells the current workflow record to commit any changes made back to the workflow. If an error has occurred (i.e., a log message with level "error" was recorded), then this commit should be noted to have been performed with an error (which may require some sort of intervention). The lock will be released after this call is made.

=cut

sub commit {
	my $self = shift;

	return $self->{this}->commit(@_);
}

=item $ctx-E<gt>rollback

B<Do not use this unless you know exactly what you're doing.>

This tells the current workflow record to rollback any changes made to the workflow. Thus, nothing should be recorded with the workflow and the lock on the workflow record should be released. This can be done if an error occurred and any intermediate changes made by this agent can be undone.

=cut

sub rollback {
	my $self = shift;

	return $self->{this}->rollback(@_);
}

=item $ctx-E<gt>log($level, @message)

B<Do not use this unless you know exactly what you're doing.>

This method logs a message on the current workflow record. Acceptable levels should be:

  debug
  info
  notice
  warning
  error
  alert
  emergency

This method will be called automatically via the regular logging API exposed via C<$FleetConf::log>, so this shouldn't be called directly under nearly any circumstance.

=cut

sub log {
	my $self = shift;

	return $self->{this}->log(@_);
}

=item $out_str = $ctx-E<gt>interpolate($in_str)

Given a string C<$in_str>, this method returns a string C<$out_str> with all instances of "C<${variable_name}>" found in the input string replaced with the value that would be returned if that variable name were passed to the C<get> method.

=cut

sub interpolate {
	my $self = shift;
	my $str  = shift;

	$str =~ s/\$\{\s*([a-zA-Z_][a-zA-Z0-9_\.]*)\s*\}/$self->get($1) || ''/eg;

	return $str;
}

=back

=head1 BUGS

=head2 LEXICAL SCOPING BUG

Currently, the context is really kind of pathetic. For example, this is a valid construct in the agent language (using the standard commands):

  WHEN TRUE DO
    PREREQUISITE_SET foo = 1
	SET foo //= 2
    ECHO foo = ${foo}
  END

The output here is:

  foo = 2

The output should be (intuitively):

  foo = 1

It might not be obvious from this example that this is the intuitive answer, but if we dropped the C<SET> command, you should see why (i.e., it seems natural to expect a C<PREREQUISITE_SET> to last through all the rest of the phases). 

The reason for this bug is that each phase cases the lexical scope to start-over from the root. That is, we push to get into the C<WHEN> during initialization phase and then pop to get out of it. Later, during run phase, we push again and pop, but the C<PREREQUISITE_SET> is not run again. I suppose I could fix this by having C<PREREQUISITE_SET> run during the initialize, requirements, check, and run phases, but this puts the onus on the plugin designer to make the design intuitive.

The better solution is to associate the lexical frame with the parse tree object that pushes and pops it. Then, when the same parse tree object pushes again during a later phase, the old lexicals are restored. I think I can do this with either no work or very little work on the part of the plugin designer.

=head2 MULTIPLE FRAME STACKS

Currently, there is only a single lexical frame stack. However, there needs to be at least one more currently and I think it likely that multiple stacks will be needed in the future.

Here's an example the current context handles fine,

  COMMAND foo.exe
  OPTION -option1
  WHEN something_is_true() DO
    OPTION -option2
  END
  EXEC

Here we have a C<COMMAND>/C<OPTION>/C<EXEC> and a nested C<WHEN>/C<END>. The context is currently able to handle this situation just fine.

However, if we make a slightly different situation:

  WHEN something_is_true() DO
    COMMAND foo.exe
  END

  WHEN NOT something_is_true() DO
    COMMAND bar.exe
  END

  OPTION -option1
  OPTION -option2
  EXEC

This situation won't function in the current system. (Though, there is a hack that would make it work.) At this time, there is only a single frame stack, which I would call the control stack. The second example illustrates the need for a secondary stack I would call the command stack. With the command stack we would even be able to nest commands (something that is currently impossible).

Anyway, it's likely that other special purpose commands will want their own lexical frame stack, so I think C<get>, C<set>, C<push_scope>, and C<pop_scope> need to be modified to handle the other cases and to allow for different kinds of stack frames.

=head1 AUTHOR

Andrew Sterling Hanenkamp, E<lt>hanenkamp@users.sourceforge.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 Andrew Sterling Hanenkamp. All Rights Reserved.

FleetConf is distributed and licensed under the same terms as Perl itself.

=cut

1
