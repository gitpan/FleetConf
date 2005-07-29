package FleetConf;

use strict;
use warnings;

use Carp;
use Cwd ();
use Data::Dumper;
use File::Basename;
use File::Find;
use File::Spec;
use FleetConf::Conf;
use FleetConf::Log;
use FleetConf::Workflow::Null;
use Log::Dispatch;
use Log::Dispatch::File;
use Log::Dispatch::Screen;

our $VERSION = '0.01_015';

=head1 NAME

FleetConf - An multi-agent, configuration management tool

=head1 SYNOPSIS

  perl Build.PL install_base=/master/install/dir/FleetConf
  ./Build
  ./Build test
  ./Build install

  vim /master/install/dir/FleetConf/etc/fleet.conf

  /master/install/dir/FleetConf/bin/fleetconf -v
  /usr/local/Fleetconf/bin/fleetconf

=head1 DESCRIPTION

This is a highly configurable, Perl-based, multi-agent, configuration management tool. It was originally designed by the author to handle the account management tasks for a mixed platform environment. In order to create accounts, he needed to create directory users on a Microsoft Windows Server 2003, create home directories and establish quotas on a Linux file server, add the user to mailing lists on another Linux mail server, monitor the process, and notify the user when the operations were complete.

This system has been further generalized to perform nearly any common configuration task needed to be performed across multiple systems. It's meant to perform actions similar to (and is being used by the author to replace) cfengine.

=head2 HOW DOES IT WORK?

The front-end for the tool is L<fleetconf>. Though, the real work is all started within the Perl module named L<FleetConf> and through another set of Perl modules used by L<FleetConf::Agent>. (Therefore, if FleetConf doesn't quite do it right for your needs, it should be a simple matter to modify L<fleetconf> or create a new similar script to perform the same purpose.) For details on how to use L<fleetconf> see it's documentation.

Essentially, the FleetConf system starts by determining the root directory of FleetConf. Using L<fleetconf>, this is determined by moving upward to the parent directory that script is being run from. Within this root, the system opens and reads the contents of F<etc/fleet.conf>, which contains some initial settings (see L</"CONFIGURATION"> below). 

Then, one or more plugin directories are loaded. Each plugin is a Perl file with the suffix ".pl" or ".pm" and may do whatever it likes to modify the internals of the system. Usually, this involves defining new agent language commands or defining helper functions (in the C<FleetConf::Functions> namespace) or helper commands (in the C<FleetConf::Commands> namespace). However, these can be used to modify any aspect of the published API they want.

Following this, a series of "workflows" are loaded, as defined in the configuration file (and possibly plugins). Agents use the workflows to determine what to do and also to record their progress in doing it.

Next, one or more agent directories are loaded. All files ending in ".agent" are read using the agent parser. The agent parser compiles every agent script found. Each agent is defined in a fairly simple command-based language that can be extended using plugins. For a full definition of the language see L<FleetConf::Agent::Parser>, and any plugins you have loaded (the included plugins are linked from L<FleetConf::Agent::Parser>).

Finally, each agent is run. Each agent runs over each record found in the given workflow system and may perform an action permitted by the agent language. Each iteration involves running the agent in 5 phases (plus a phase before iteration begins). It is likely that future versions will feature an additional phase at the end and perhaps other phases. For a full description of running and the phases see L<FleetConf::Agent>. For a description of which commands run in which phases, you'll need to see the L<FleetConf::Agent::Parser> and command plugin documentation.

=head2 HOW DO I USE IT?

The first step, of course, is to install it. Then, you will need to configure it and write some useful agents. Then, you need to run it all over the place to copy it locally.

For information on installation, see L</"INSTALLATION">. For information on configuration, see L</"CONFIGURATION">. For information to get started with agents, see L<FleetConf::Agent>.

=head1 FleetConf API

The public API is documented to allow contributors to learn about the system, for users to create plugins that take full advantage of the API, and to keep the author from forgetting what something is supposed to do.

In generally, I try to keep the documentation up to date with the actual program, but there will be lapses. Please let me know about them by filing a bug at L<http://rt.cpan.org/> if you discover such a lapse.

=head2 API OVERVIEW

The L<FleetConf> object exists as a singleton created sometime after startup. (For those who may not know, a "singleton" is approximately what it sounds like: it is an object for which there can be only one for each Perl process. That means that there should only ever be one of these objects-per-run of L<fleetconf>.) This singleton is accessed (and, during the first call, created) by calling the C<instance> method of L<FleetConf>.

Prior to calling the C<instance> method you will probably want to configure the global variables, which are used to determine certain parts of the configuration.

=head2 GLOBAL VARIABLES

B<NOTE:> Please be aware that these variables may change. These were an easy mechanism of communication between L<fleetconf> and L<FleetConf> originally, but aren't very good solutions. Future revisions may include accessors from the L<FleetConf> singleton so that their effects can be modified after startup. Currently, if you set these after the C<instance> method is called, that change may have no effect. However, it's likely that I will keep these around and use some devious C<tie>ing to allow them to be effective. So perhaps my warning doesn't matter anyway.

This documentation shows the fully qualified name of each global variable and the initial/default value of that variable (if any).

=over

=item $FleetConf::verbose = 0;

The verbose setting is used to determine how much information to output while running. All output I<should> be routed through the logger (see C<$FleetConf::log> below), which is configured according to the value of this setting when C<initialize> is called.

When this setting is set to "0", the default log level of "warning" or "error" is used, meaning that anything below that threshold is not output. (See C<$FleetConf::no_warnings> for more information.) If verbose is set to "1", then the log level is set to "notice". If verbose is set to "2", the log level is set to "info". If verbose is set to "3", the log level is set to "debug". Higher levels will result in greater amounts of debug information being displayed. At this time, I believe level "4" is the highest implemented debug level, but more might be used in the future.

=item $FleetConf::pretend = 0;

All plugins should be careful to check the value of this variable. If this value is set to a true (non-zero) value, then no changes should be made to the system, the workflow, or anything. Plugins and commands should merely report back as if they were doing that work (or may log messages stating that we're pretending to do something, whatever is most appropriate).

This flag allows the user to safely run and see what would happen without actually causing anything to happen.

Setting this value to will cause verbose to be set to at least a value of "1" (so that log level is set to "notice").

=item $FleetConf::no_warnings = 0;

In some cases, it might be desireable to hide warnings from standard output. Setting this to a true (non-zero) value will mean that the log level will be set to "error" rather than "warning" as long as neither C<$FleetConf::verbose> nor C<$FleetConf::pretend> are non-zero.

=item $FleetConf::fleetconf_root = Cwd::getcwd;

This value is very important to set if you are writing an alternative to the L<fleetconf> front-end. This tells FleetConf which directory to use as the basis for all relative file names and where to find the configuration file (i.e., F<etc/fleet.conf> inside of this directory).

it defaults to the current working directory of the current Perl interpreter, but this is a poor default.

=item $FleetConf::log = ...;

This log mechanism is deprecated. Please use L<FleetConf::Log> instead. This is still used, but only internally.

=item $FleetConf::log_file;

Name the log file to log to. If none is given, then logging only goes to standard error. This file will be appended to rather than overwritten.

=item $FleetConf::log_stderr = 1;

If this is set to a false value, then logging will not be printed to the terminal on standard error.

=item %FleetConf::globals;

This global is setup initially from the "globals" configuration option. It may contain any information a plugin or agent wants to store here. It may be modified by any agent or plugin and those changes stay until changed by a later agent or plugin or when FleetConf quits. The contents of this variable are not saved between runs of FleetConf.

=back

=cut

our $verbose = 0;
our $pretend = 0;
our $no_warnings = 0;
our $fleetconf_root = Cwd::getcwd;
our $log_file;
our $log_stderr = 1;

our $log;

BEGIN { 
	$log = Log::Dispatch->new(
		callbacks => sub {
			my %args = @_;
			my $str = localtime;
			sprintf "%s [%s] %s\n", $str, $args{level}, $args{message};
		},
	); 
	$log->add(Log::Dispatch::Screen->new(
			name 		=> 'screen',
			min_level	=> 'debug',
			stderr		=> 1));

	sub strip_eol { 
		return () unless @_; 
		my $x = pop; chomp $x; return (@_, $x) 
	}
	$SIG{__WARN__} = sub { $log->warning(strip_eol(@_)) };
	$SIG{__DIE__}  = sub { $log->error(strip_eol(@_)); die @_ };
}

my $flog = FleetConf::Log->get_logger(__PACKAGE__);

# This is first initialized to the values loaded in fleet.conf, and
# can be further modified by the plugins.
our %globals;

=head2 METHODS

The most important method is the C<instance> method, which returns the singleton L<FleetConf> instance that is used to call most of the other methods.

=over

=item $fleetconf = FleetConf::instance

=item $fleetconf = FleetConf->instance

This method returns the singleton reference to the L<FleetConf> object. This is the starting point for all things FleetConf in the API. See the rest of the method documentation below to find out what you can do with it.

The first time this method is called, it will perform the first four phases of loading based upon the globals (see L</"GLOBAL VARIABLES"> above).

=over

=item Prologue

Before doing anything it will determine the log level that should be used to output to the screen (via standard error). It then resets the logger to use this log level on the screen (prior to this call, the logger will output anything to the screen as it's rare that it should be used at all prior to this point).

It also performs a late loading of the L<FleetConf::Agent> library (which shouldn't, in general, be loaded directly by any plugin or application). This late loading happens so that we can capture the output of the parser trace for debugging purposes.

=item Phase 1: Configuration

Loading the configuration happens next. See L</"CONFIGURATION"> for details on what is stored there.

=item Phase 2: Plugins

We search all directories specified by the plugin search path for any file ending in ".pl" or ".pm" and we run that file as if it were Perl. We report as errors or warnings any plugin that fails to load correctly, but we otherwise ignore them.

Most of the time, FleetConf ignores errors and continues despite them because it's possible that unrelated parts of the system should run anyway. If an error should stop some other part of the system from running a plugin should make sure and fail cleanly itself and alter the state of the system somehow to prevent the other system from failing (the C<%FleetConf::globals> would be a good place to do this).

=item Phase 3: Workflows

Based upon the configuration in the "workflows" variable, we will load workflow instances into the system. Agents then request named workflow instances to determine how they proceed.

One workflow instance is ubiquitous and loaded regardless of any other configuration. This workflow is called "Null" and is defined as a basic instance of L<FleetConf::Workflow::Null>. This module basically always returns a single empty workflow record and uses the C<$FleetConf::log> logger to record changes. See L<FleetConf::Workflow::Null> for more information.

=item Phase 4: Agents

Finally, we search all of the agent include directories for files ending with ".agent" and compile the agents there according to the C<load_file> method of L<FleetConf::Agent>. (See that module for more documentation on this process.)

=back

At this point everything that will be loaded is loaded, but (unless a plugin does something) no action should have been taken yet. The returned object is ready to continue.

=cut

my $fleetconf;
sub instance {
	my $class = shift;
	my $clean = shift;
	# FOR TESTING ONLY!!!!
	undef $fleetconf if $clean && $clean eq 'I_WANT_A_CLEAN_INSTANCE';

	return $fleetconf if defined $fleetconf;

	my $level = 
		$verbose > 2 ? 'debug' :
		$verbose > 1 ? 'info' :
		($verbose > 0 || $pretend) ? 'notice' : 
		$no_warnings ? 'error' : 'warning';

	$log->remove('screen');
	
	if ($log_stderr) {
		$log->add(Log::Dispatch::Screen->new(
				name      => 'screen',
				min_level => $level,
				stderr    => 1));
	}

	if ($log_file) {
		$log->add(Log::Dispatch::File->new(
				name      => 'file',
				min_level => $level,
				filename  => $log_file,
				mode      => 'append'));
	}

	# Load this late so that $::RD_TRACE picks up the value of
	# $verbose
	eval "use FleetConf::Agent";
	die $@ if $@;

	$fleetconf = bless {}, $class;
	$fleetconf->_load_configuration;
	$fleetconf->_load_plugins;
	$fleetconf->_load_workflows;
	$fleetconf->_load_agents;

	return $fleetconf;
}

=item $config = FleetConf::configuration

=item $config = FleetConf-E<gt>configuration

=item $config = $fleetconf-E<gt>configuration

This method can be used to fetch the configuration file after it is read in. If this method is not called on a L<FleetConf> instance, the C<instance> method will be called to get one and the configuration method called on that (i.e., don't call this if you aren't ready to call C<instance>).

For details on what this variable will contain, see L</"CONFIGURATION">.

=cut

sub configuration {
	my $class = shift;

	if (ref $class) {
		return $class->{conf};
	} else {
		return FleetConf->instance->{conf};
	}
}

sub _load_configuration {
	my $self = shift;

	# TODO Should attempt to find the root if not given.
	unless ($fleetconf_root) {
		die "fleetconf_root is unset, can't find fleet.conf";
	}

	my $conf_file = File::Spec->catfile(
		$fleetconf_root, "etc", "fleet.conf"
	);

	$flog->notice("Loading configuration '$conf_file'");

	my $parser = FleetConf::Conf->new;
	$self->{conf} = $parser->parse_file($conf_file);

	$flog->would_log('debug') && 
		$flog->debug(Data::Dumper->Dump([$self->{conf}],['conf']));

	if (defined $self->{conf}{globals} &&
			ref($self->{conf}{globals}) eq 'HASH') {
		%globals = %{ $self->{conf}{globals} };
		$flog->would_log('debug') &&
			$flog->debug(Data::Dumper->Dump([\%globals],['globals']));
	}

	if (defined $self->{conf}{perl_include}) {
		my @dirs = 
			map { File::Spec->file_name_is_absolute($_) ? $_ : File::Spec->catfile($fleetconf_root, $_) } 
			@{ $self->{conf}{perl_include} };

		for my $dir (@dirs) {
			-d $dir && push @INC, $dir;
		}
	}
}

sub _load_plugins {
	my $self = shift;

	$flog->would_log('notice') &&
		$flog->notice("Loading plugin directories: ",join(' ', @{ $self->{conf}{plugin_include} }));

	my @files;
	my $want = sub {
		/^\.svn$/ and $File::Find::prune = 1;
		/\.(pm|pl)$/ and push @files, $File::Find::name;
	};

	find($want, 
		grep { -d $_ }
		map { File::Spec->file_name_is_absolute($_) ? $_ : File::Spec->catfile($fleetconf_root, $_) } 
			@{ $self->{conf}{plugin_include} });

	for my $file (@files) {
		my $basefile = File::Basename::basename($file);
		unless (my $return = do $file) {
			warn "Failed to load plugin $basefile: $@" if $@;
			warn "Failed to open plugin $basefile: $!" unless defined $return;
			warn "Failed to run plugin $basefile"      unless $return;
		} elsif ($flog->would_log('notice')) {
			$flog->notice("Loaded plugin '$basefile'.");
		}
	}
}

sub _load_workflows {
	my $self = shift;

	my $workflows = $self->{conf}{workflows};

	while (my ($name, $args) = each %$workflows) {
		$flog->notice("Loading workflow '$name' using class '$args->{class}'.");

		$self->{workflows}{$name} = $args->{class}->new($args->{args});

		warn "Failed to load workflow '$name'." 
			unless $self->{workflows}{$name};
	}

	# Setup the ever present Null workflow
	$self->{workflows}{'Null'} = FleetConf::Workflow::Null->new;
}

sub _load_agents {
	my $self = shift;

	$flog->would_log('notice') &&
		$flog->notice("Loading agent directories: ",join(' ', @{ $self->{conf}{agent_include} }));

	my @files;
	my $want = sub {
		/^\.svn$/ and $File::Find::prune = 1;
		/\.agent$/ and push @files, $File::Find::name;
	};

	find($want, 
		map { /\// ? $_ : "$fleetconf_root/$_" } 
			@{ $self->{conf}{agent_include} });

	for my $file (@files) {
		my $agent = eval { FleetConf::Agent->load_file($file) };

		my $basefile = File::Basename::basename($file);
		if ($@) {
			warn "Failed to load agent $basefile: $@";
		} elsif ($agent && $agent->name) {
			push @{ $self->{agents} }, $agent;

			$flog->notice("Loaded agent named '".$agent->name."' from '$basefile'.");
		} else {
			warn "Failed to load agent $basefile";
		}
	}
}

=item $fleetconf-E<gt>select_agents(@selectors)

This method allows the user to specify which agents should be run. In some cases, it may be desireable to limit which agents are run externally (i.e., agents can internally refuse to run based on the situation as well). If only some of the agents should be run, then this method should be used to select the agents.

Each element of C<@selectors> is a subroutine (code reference) that takes an L<FleetConf::Agent> object reference as it's only argument. An agent will be used if I<any> selector returns a true (non-zero) value when pased that agent.

This call affects any call to C<run_agents> following until this method is called again. Each call to this method replaces the entire list of selectors. Calling this method with no arguments will cause all agents to be selected if immediately followed by a call to C<run_agents>.

=cut

sub select_agents {
	my $self = shift;

	$self->{agent_selectors} = [ grep defined($_), @_ ];
	
	return;
}

=item @agents = $fleetconf-E<gt>agents

This method returns a list of agents that are currently selected (according to the last call to C<select_agents>) or all agents if no selectors are set. See C<select_agents> for information on how to select agents.

=cut

sub agents {
	my $self = shift;

	if ($self->{agent_selectors} && @{ $self->{agent_selectors} }) {
		my @results;
		AGENT: for my $agent (@{ $self->{agents} }) {
			for my $selector (@{ $self->{agent_selectors} }) {
				if ($selector->($agent)) {
					push @results, $agent;
					next AGENT;
				}
			}
		}

		return @results;
	} else {
		return @{ $self->{agents} };
	}
}

=item $fleetconf->run_agents

Runs all the agents that have been selected (i.e., those that would be returned by C<agents>). This basically means that each agent is loaded and the C<run_foreach> method is called with the requested workflow passed.

=cut

sub run_agents {
	my $self = shift;

	for my $agent ($self->agents) {
		my $wf = $self->{workflows}{$agent->workflow};

		unless ($wf) {
			warn "Cannot run agent '".$agent->name."' because workflow '".$agent->workflow."' has not been loaded.";
			next;
		}

		$agent->run_foreach($wf);
	}
}

=back

=head2 CONFIGURATION

The configuration is stored as a L<YAML> file. Please see the documentation of L<YAML> for information on how YAML works. The top-level of the FleetConf configuration file, F<fleet.conf>, is a hash containing keys pointing to the different configuration directives. At this time, there are very few directives. 

For a basic and simple configuration file illustrating these directives, see the file F<etc/fleet.conf.sample> included in the distribution.

Each are described here:

=over

=item agent_include

This is an array containing the name of the directories to search for agents.

For example:

  agent_include:
   - agents
   - /etc/FleetConf/agents

Here, all agents found in the directory or subdirectories of F<agents> in the FleetConf root directory will be searched first and then those found in F</etc/FleetConf/agents> will be loaded second.

=item plugin_include

This is an array containing the name of the directories to search for plugins.

For example:

  plugin_include:
   - plugins
   - /etc/FleetConf/plugins

Here, all agents found in the directory or subdirectories of F<plugins> in the FleetConf root directory will be searched first. Then, those found in F</etc/FleetConf/plugins> will be leaded second.

=item workflows

This option contains a hash of the all the workflows to load. Each hash key is the name of the workflow instance. Each of these should then be a hash containing two keys, "class" and "args". The "class" key is a scalar naming the Perl class that will be used to create the workflow instance (and should already be loaded as a plugin). The "args" will be set to whatever the C<new> method of the given "class" expects to set it up.

For example:

  workflows:
    new_jobs:
      class: FleetConf::Workflow::RT
      args:
        proxy: https://example.com/cgi-bin/rt-soap-server.pl
        query: Queue='Jobs' AND Status='new'
        ssl_client_certificate: /etc/ssl/client/rt-workflow.crt
        ssl_client_key: /etc/ssl/client/rt-workflow.key
    open_jobs:
      class: FleetConf::Workflow::RT
      args:
        proxy: https://example.com/cgi-bin/rt-soap-server.pl
        query: Queue='Jobs' AND Status='open'
        ssl_client_certificate: /etc/ssl/client/rt-workflow.crt
        ssl_client_key: /etc/ssl/client/rt-workflow.key

This will instantiate two workflow instances: one named "new_jobs" and another named "open_jobs". If a workflow requires more complicated work to instantiate it, that work may be done with a plugin (though, the way to do that isn't part of teh published API yet as this isn't necessarily safe if you upgrade in the future).

=item globals

This option sets the initial value of C<%FleetConf::globals>. Thus, it should, obviously, be a hash.

For example:

  globals:
    master_path: /common/admin/FleetConf
    local_path: /usr/local

This would set C<$FleetConf::globals{master_path}> to "/common/admin/FleetConf" and C<$FleetConf::globals{local_path}> to "/usr/local".

=back

=head2 INSTALLATION

Installation follows the typical L<Module::Build> template with one important caveat. FleetConf is meant to operate in a more controlled environment, so C<install_base> is automatically set to F</usr/local/FleetConf>. That is, by doing the typical (such as installing with L<CPAN>):

  perl Build.PL
  ./Build
  ./Build test
  ./Build install

The files will all be dropped within F</usr/local/FleetConf> and subdirectories within that folder. It is strongly recommended that you install FleetConf into it's very own directory, which is why you will receive a complaint if you try to install into a directory not named "FleetConf", just to try and make sure you're aware of this if you have not yet read the docs.

Thus, the more typical installation will look like this:

  perl Build.PL install_base=/some/master/root/FleetConf
  ./Build
  ./Build test
  ./Build install

Just in case you hate using capitals, no complaint will occur if you install using all lower case, e.g., F</usr/local/fleetconf>.

After installation, you will need to create a file named F<etc/fleet.conf> inside the installation directory and add any agents you like. 

At this point, one agent is installed automatically, F<update.agent>, which will update a local installation from a global one. Delete this if you don't want it. Future versions might include this as an F<update.agent.sample> or something similar. You will need to check the agent folder and make sure you have all the agents you want there. You may also want to add plugins.

The rest is up to you. At this point, FleetConf has no standard policies on how things should be done. This will likely remain the case until either I find something useful, or a user community starts choosing those policies. I have no idea what would be best in general or what tricks might be handy.

=head1 SEE ALSO

L<FleetConf::Agent>, L<FleetConf::Agent::Parser>, L<FleetConf::Commands>, L<FleetConf::Functions>, L<FleetConf::Workflow::Null>, L<FleetCOnf::Workflow::RT>, L<Log::Dispatch>, L<Module::Build>, L<CPAN>

=head1 AUTHOR

Andrew Sterling Hanenkamp, E<lt>hanenkamp@users.sourceforge.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 Andrew Sterling Hanenkamp. All Rights Reserved.

FleetConf is licensed and distributed under the same terms as Perl itself.

=cut

1
