package FleetConf::Workflow::RT;

use strict;
use warnings;

use Carp;
use FleetConf::Log;
use SOAP::Lite;

our $VERSION = '0.06';

=head1 NAME

FleetConf::Workflow::RT - Workflow for contacting RT via custom SOAP server

=head1 SYNOPSIS

  # in fleet.conf
  workflows {
    RT {
      class = FleetConf::Workflow::RT
      args {
        proxy = http://www.example.com/cgi-bin/rt-soap-server.pl
        query = Queue = 'Jobs' AND (Status = 'new' OR Status = 'open')
        ssl_client_certificate = $FleetConf::globals{conf_root}/ssl/my.crt
        ssl_client_key = $FleetConf::globals{conf_root}/ssl/my.key
      }
    }
  }

=head1 DESCRIPTION

This workflow uses a customized RT SOAP server based upon the original C<rt-soap-server.pl> originally published by Best Practical, LLC. You can find the custom SOAP server in the F<contrib/> directory of the FleetConf distribution.

This system uses SSL client authentication to authenticate with the SOAP server and perform actions against the server.

=cut

my $log = FleetConf::Log->get_logger(__PACKAGE__);

sub new {
	my $class = shift;
	my $args  = shift;

	defined $args->{proxy}
		or croak "Missing required parameter 'proxy'.";

	defined $args->{ssl_client_certificate}
		or croak "Missing required parameter 'ssl_client_certificate'.";

	defined $args->{ssl_client_key}
		or croak "Missing required parameter 'ssl_client_key'.";

	$args->{ssl_client_certificate} = 
		eval qq("$args->{ssl_client_certificate}");
	$args->{ssl_client_key} =
		eval qq("$args->{ssl_client_key}");

	my $self = bless {
		ssl_client_certificate => $args->{ssl_client_certificate},
		ssl_client_key         => $args->{ssl_client_key},
		query                  => $args->{query},
		service                => SOAP::Lite
			-> uri('urn:/NETRT')
			-> proxy($args->{proxy}),
	}, $class;
}

sub list {
	my $self = shift;

	$ENV{HTTPS_CERT_FILE} = $self->{ssl_client_certificate};
	$ENV{HTTPS_KEY_FILE}  = $self->{ssl_client_key};
	
	my $results = $self->{service}->getTickets($self->{query})->result;

	unless ($results) {
		return ();
	} else {
		return map 
			{ FleetConf::Workflow::RT::Ticket->new($self, $_) }
			@$results;
	}
}

package FleetConf::Workflow::RT::Ticket;

sub new {
	my $class    = shift;
	my $workflow = shift;
	my $ticket   = shift;

	bless {
		workflow => $workflow,
		ticket   => $ticket,
		changes  => {},
		log      => [],
	}, $class;
}

sub _check_lock {
	my $self = shift;

	my ($package, $filename, $line, $sub) = caller(1);

	$self->{locked}
		or die "Cannot perform operation '$sub' without a lock.";
}

sub get {
	my $self = shift;
	my $key  = shift;

	if (exists $self->{ticket}{$key}) {
		my $value = exists $self->{changes}{$key} ?
			$self->{changes}{$key} :
			$self->{ticket}{$key};
		return $value;
	} else {
		my $cf = $self->{ticket}{CustomFields}{$key};
		if ($cf && $cf->{id}) {
            my $value;
            if (exists $self->{changes}{$key}) {
                $value = $self->{changes}{$key};
            } elsif ($self->{ticket}{CustomFieldValues}) {
                $value = $self->{ticket}{CustomFieldValues}{$key};
            } else {
                $value = undef;
            }

			if ($cf->{MaxValues} == 0) {
				return $value;
			} else {
				$value ||= [];
				return @$value ? $value->[0] : undef;
			}
		} else {
			return undef;
		}
	}
}

sub set {
	my $self  = shift;
	my $key   = shift;
	my $value = shift;

	$self->_check_lock;

	if (defined $self->{ticket}{CustomFields}{$key}) {
		if (ref($value) eq 'ARRAY') {
			$self->{changes}{$key} = $value;
		} else {
			$self->{changes}{$key} = [ $value ];
		} 
	} else {
		$self->{changes}{$key} = $value;
	}
}

sub _save {
	my $self = shift;

	my %changes;
	while (my ($key, $value) = each %{ $self->{changes} }) {
		if (grep { $key eq $_ } keys %{ $self->{ticket}{CustomFields} }) {
			my $cf = $self->{ticket}{CustomFields}{$key};
			if ($cf && $cf->{id}) {
				$changes{"CustomField-".$cf->{id}."-Values"} = $value;
			} else {
				warn "Unknown field '$key' set on ticket $self->{ticket}{id}. Ignoring it.";
			}
		} else {
			$changes{$key} = $value;
		}
	}

	$self->{workflow}{service}->modifyTicket(
		id => $self->{ticket}{id},
		%changes,
	);

	$self->{changes} = {};
}

sub begin {
	my $self     = shift;
	my $mnemonic = shift;
	my $force    = shift;

	my $id = $self->{ticket}{id};

	# We require a custom, multi-valued field named 'locks'
	if ($self->{workflow}{service}->lockTicket($id, 'locks', 'commits', $mnemonic)->result) {
		$self->{locked} = $mnemonic;
		return 1;
	} elsif ($force) {
		# DANGER!!! We're assuming the lock is ours without actually taking
		# it. This could be useful if a process locked it, but never let
		# go. We're going to whine, but pretent to take the lock.
		warn "Lock '$mnemonic' is taken on #$self->{ticket}{id} despite failed lock attempt.";
		$self->{locked} = $mnemonic;
		return 1;
	} else {
		# Lock's taken, we'll whine (quietly since this might be just that it's
		# committed) and quit and tell them to go no further
		$log->notice("Failed to take lock '$mnemonic' on #$self->{ticket}{id}.");
		return '';
	}
}

sub commit {
	my $self     = shift;
	
	$self->_check_lock;
	
	my $mnemonic = $self->{locked};
	my $erred    = $self->{erred};

	$self->log('error', "Error '$mnemonic'.") if $self->{erred};
	$self->_flush_logs;
	$self->_save;

	my $id = $self->{ticket}{id};

	$self->{workflow}{service}->unlockTicket($id, 'locks', 'commits', 'errors', $mnemonic, $self->{erred})->result
		or warn "Failed to release lock '$mnemonic'.";

	delete $self->{locked};
}

sub rollback {
	my $self     = shift;

	my $mnemonic = $self->{locked};
	
	$self->_check_lock;

	$self->log('warn', "Rollback '$self->{locked}'. Changes not committed.");
	$self->_flush_logs;
	$self->{changes} = {};
	
	my $id = $self->{ticket}{id};

	$self->{workflow}{service}->unlockTicket($id, 'locks', 'commits', 'errors', $mnemonic, 0)->result
		or warn "Failed to release lock '$mnemonic'.";

	delete $self->{locked};
}

sub log {
	my $self    = shift;
	my $level   = uc(shift);

	if ($level =~ /^err(?:or)?$/i) {
		$self->{erred}++;
	}

	my $msg;
	$msg .= "(lock=$self->{locked}) " if $self->{locked};
	$msg .= join '', @_;

	push @{ $self->{log} }, 
		sprintf("%s [%s] %s", scalar(localtime), $level, $msg);
}

sub _flush_logs {
	my $self = shift;

	if (@{ $self->{log} }) {
		$self->{workflow}{service}->updateTicket(
			id          => $self->{ticket}{id},
			UpdateType  => 'comment',
			MimeMessage => 
				"Subject: Agent Log\n\n".
				join "", @{ $self->{log} },
		);
	}

	delete $self->{erred};
	$self->{log} = [];
}

=head1 AUTHOR

Andrew Sterling Hanenkamp, E<lt>hanenkamp@users.sourceforge.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 Andrew Sterling Hanenkamp. All Rights Reserved.

FleetConf is distributed and licensed under the same terms as Perl itself.

=cut

1
