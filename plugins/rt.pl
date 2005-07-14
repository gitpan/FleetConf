package FleetConf::Commands;

use File::Spec;

our $VERSION = '0.03';

sub ReplyToTicket {
	my $rt = shift;
	my $id = shift;
	my $file = shift;
	my $vars = shift;

	my $log = FleetConf::Log->get_logger("FleetConf::Commands::ReplyToTicket");

	unless (File::Spec->file_name_is_absolute) {
		$file = File::Spec->catfile(
			$FleetConf::fleetconf_root, $file
		);
	}

	unless (open TMPL, $file) {
		$log->error("Cannot open $file for correspondance with ticket #$id: $!");
		return 0;
	}

	my $message = join '', <TMPL>;
	close TMPL;

	if (defined $vars) {
		for my $key (keys %$vars) {
			my $escaped = $vars->{$key};
			$escaped =~ s/%/%%/g;
			$message =~ s/(?<!\%)\%$key\%/$escaped/g;
		}
		$message =~ s/%%/%/g;
	}

	if ($FleetConf::pretend) {
		$log->notice("Would Reply to #$id: \n$message");
		return 1;
	}

	my $result = $rt->updateTicket(
		id          => $id,
		UpdateType  => 'reply',
		MimeMessage => $message,
	)->result;

	if ($result->{status}) {
		$log->notice("Status Message from Reply to #$id: $result->{message}");
	} else {
		$log->error("Error during Reply to #$id: $result->{message}");
	}

	return $result->{status};
}

sub ResolveTicket {
	my $rt = shift;
	my $id = shift;

	my $log = FleetConf::Log->get_logger("FleetConf::Commands::ResolveTicket");

	if ($FleetConf::pretend) {
		$log->notice("Would Resolve Ticket #$id");
		return 1;
	}

	my $result = $rt->modifyTicket(
		id => $id,
		Status => 'resolved',
	)->result;

	if ($result->{status}) {
		$log->notice("Status Message from Resolve of #$id: $result->{message}");
	} else {
		$log->error("Error during Resolve of #$id: $result->{message}");
	}

	return $result->{status};
}

sub ApproveTicket {
	my $rt = shift;
	my $id = shift;

	my $log = FleetConf::Log->get_logger("FleetConf::Commands::ApproveTicket");

	my $tickets = $rt->getTickets(
		"Type = 'Approval' AND DependedOnBy = '$id'"
	)->result;

	$log->notice("Found ",scalar(@$tickets)||0," approvals to resolve.");

	for my $ticket (@$tickets) {
		$log->notice("Resolving approval #$ticket->{id}");
		next if $FleetConf::pretend;

		my $result = $rt->modifyTicket(
			id => $ticket->{id},
			Status => 'resolved',
		);

		if ($result->{status}) {
			$log->notice("Resolved approval #$ticket->{id}: $result->{message}");
		} else {
			$log->notice("Error resolving approval #$ticket->{id}: $result->{message}");
			return 0;
		}
	}

	return 1;
}

1
