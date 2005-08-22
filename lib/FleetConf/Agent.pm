package FleetConf::Agent;

use strict;
use warnings;

use Data::Dumper;
use File::Basename;
use FleetConf::Agent::Context;
use FleetConf::Agent::Parser;
use FleetConf::Log;

our $VERSION = '0.08';

=head1 NAME

FleetConf::Agent - Agent object class for FleetConf

=head1 DESCRIPTION

This object should not generally be used directly. This documentation is intended to be a reference on how agent execution works. For information on writing agents, see L<FleetConf::Agent::Parser>. For information on using agents, see L<FleetConf>.

TODO Add documentation on agent runtime semantics.

=cut

my $log = FleetConf::Log->get_logger(__PACKAGE__);

sub load_file {
	my $class = shift;
	my $file  = shift;

	open FH, $file or die "Cannot read $file: $!";
	my $source = join '', <FH>;
	close FH;

	$FleetConf::Agent::Parser::file = basename($file);
	my $program = $FleetConf::Agent::Parser::parser->agent($source);
	$program->{header}{FILENAME} = basename($file);

	if ($program) {
		return bless {
			program => $program,
		}, $class;
	} else {
		return undef;
	}
}

sub filename	{ return shift->{program}{header}{FILENAME} }
sub name        { return shift->{program}{header}{NAME} }
sub description { return shift->{program}{header}{DESCRIPTION} }
sub version     { return shift->{program}{header}{VERSION} }
sub mnemonic    { return shift->{program}{header}{MNEMONIC} }
sub workflow    { return shift->{program}{header}{WORKFLOW} }

sub header {
	my $self = shift;
	my $var  = uc(shift);
	return $self->{program}{header}{$var};
}

sub run_foreach {
	my $self     = shift;
	my $workflow = shift;
	
	my $tree    = $self->{program};

	$log->notice("Running agent named '".$self->name."'.");

	if ($log->would_log('info')) {
		while (my ($key, $val) = each %{ $tree->{header} }) {
			$log->info(sprintf "%-12s: %s", $key, $val);
		}
	}

	# Initialize Phase
	#
	# Before we contact the workflow, we check to make sure the
	# agent is able to initialize. This can be used to acquire any
	# resources required for basic agent operation or can be used
	# to check non-workflow related prerequisites (e.g., some agents
	# might only run on certain hosts).
	my $result = eval {
		my $ctx = FleetConf::Agent::Context->new(
			FleetConf::Workflow::Null->new
		);
		$self->_run_phase('initialize', $tree, $ctx)
	};

	return unless $result;

	my @wflist = eval { $workflow->list };

	if ($@) {
		warn "Error while listing records from workflow '".$self->workflow."': $@";
		next;
	}

	for my $wfr (@wflist) {
		$log->notice("Running agent named '".$self->name."' with workflow '".$self->workflow."'");
		eval { $self->run($wfr) };

		if ($@) {
			warn "Error running agent '".$self->name."' for record '".$wfr->get('id')."': $@";
		}
	}
}

sub run {
	my $self = shift;
	my $this = shift;

	my $ctx = FleetConf::Agent::Context->new($this);

	my $result = $self->_interpret($ctx);

	return $result;
}

sub _interpret {
	my $self    = shift;
	my $ctx     = shift;

	my $tree    = $self->{program};

	# Requirements Phase
	#
	# Return of zero means that this particular record isn't
	# applicable to this agent. No note will be made to the
	# record.
	my $result = eval {
		$self->_run_phase('requirements', $tree, $ctx)
	};

	warn $@ if $@;

	$result or return;
	
	# Enter Critical Section
	#
	# Since we passed all the requirements, this agent needs to
	# do something with this entry.
	#
	# At this point, the record will be altered to note that a
	# lock has been taken. The workflow may log this as well.
	#
	# If we fail to take the lock, we still do Shutdown Phase.
	my $rollback = 0;
	if ($FleetConf::pretend || $ctx->begin($tree->{header}{MNEMONIC})) {

		unless ($FleetConf::pretend) {
			my $level = $FleetConf::verbose <= 2 ? 'info' : 'debug';
			$FleetConf::log->add(
				FleetConf::Log::Workflow->new(
					name      => 'workflow',
					min_level => $level,
					workflow  => $ctx,
				)
			);
		}

		eval {
			# Check Phase
			#
			# We don't care if checks fail, we keep on truckin'.
			$self->_run_phase('check', $tree, $ctx);

			# Run Phase
			#
			# If the runs fail, this is an error that we will log,
			# but otherwise we keep going.
			unless ($self->_run_phase('run', $tree, $ctx)) {
				$log->error("Agent '",$self->name,"' failed during Run Phase.")
					unless $FleetConf::pretend;
			}

			# Cleanup Phase
			#
			# If the cleanup phase fails, we rollback our work and
			# continue.
			unless ($self->_run_phase('cleanup', $tree, $ctx)) {
				$rollback++;
				$ctx->rollback unless $FleetConf::pretend;
			}
		};

		warn $@ if $@;

		# If we haven't performed a rollback, release the lock by
		# performing a commit.
		$ctx->commit unless $rollback || $FleetConf::pretend;

		$FleetConf::log->remove('workflow');
	}

	eval {
		# Shutdown Phase
		#
		# If the shutdown phase fails, we drop a warning, but
		# otherwise do nothing.
		$self->_run_phase('shutdown', $tree, $ctx)
			or warn "Agent failed during Shutdown Phase.";
	};

	warn $@ if $@;
}

sub _run_phase {
	my $self  = shift;
	my $phase = shift;
	my $tree  = shift;
	my $ctx   = shift;

	my $result = 1;

	for my $command (@{ $tree->{commands} }) {
		if ($command->can($phase)) {
			my $ret = eval { $command->$phase($ctx); };

			if ($@) {
				$log->error("Error running $phase: $@");
				$result = 0;
			} else {
				$result &= $ret;
			}
		}
	}

	return $result;
}

=head1 BUGS

This module has very little documentation yet because it doesn't work very well yet. Much more work needs to be done to solidify this into a more robust solution.

Basically, there are six phases: initialize, requirements, check, run, cleanup, and shutdown. They run in that order. Initialize runs before the workflow is contacted and no other phase continues if any command in that phase (i.e., C<PREREQUISITE>) says not to. The requirements phase runs prior to taking a lock and check, run, and cleanup are skipped if any command in that phase (i.e., C<REQUIRE>) says not to. The check phase runs after acquiring a lock and causes an error if any part fails. The run phase runs after that and causes an error-commit if any part fails. The cleanup phase runs after that and causes a rollback if any part fails. Finally, the shutdown phase runs.

The actual semantics of each phase are poorly defined and will be redefined as soon as I can formalize the nature of "better semantics".

=head1 AUTHOR

Andrew Sterling Hanenkamp, E<lt>hanenkamp@users.sourceforge.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 Andrew Sterling Hanenkamp. All Rights Reserved.

FleetConf is distributed and licensed under the same terms as Perl itself.

=cut

1
