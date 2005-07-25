package FleetConf::Commands;

use File::Spec;

our $VERSION = '0.03';

sub ReplyToTicket {
	my $rt   = shift;
	my $this = shift;
	my $text = shift;

	my $id = $this->get('id');

	my $log = FleetConf::Log->get_logger("FleetConf::Commands::ReplyToTicket");

	if (ref($text)) {
		$text = $$text;
	} else {
		my $file = $text;

		unless (File::Spec->file_name_is_absolute) {
			$file = File::Spec->catfile(
				$FleetConf::fleetconf_root, $file
			);
		}

		unless (open TMPL, $file) {
			$log->error("Cannot open $file for correspondance with ticket #$id: $!");
			return 0;
		}

		$text = join '', <TMPL>;
		close TMPL;
	}

	$text =~ s/(?<!\%)\%([^%]+)\%/$this->get($1)||''/ge;

	if ($FleetConf::pretend) {
		$log->notice("Would Reply to #$id: \n$message");
		return 1;
	}

	my $result = $rt->updateTicket(
		id          => $id,
		UpdateType  => 'reply',
		MimeMessage => $text,
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

	my @results = $rt->modifyTicket(
		id => $id,
		Status => 'resolved',
	)->result;

	if ($result[0]{status}) {
		$log->notice("Status Message from Resolve of #$id: $result[0]{message}");
	} else {
		$log->error("Error during Resolve of #$id: $result[0]{message}");
	}

	return $result[0]{status};
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
