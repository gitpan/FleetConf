use strict;

use Module::Build 0.26;

my $subclass = Module::Build->subclass(
	class => 'FleetConf::Build',
	code => q(
use File::Spec;

# I don't like putting script files into the "script" directory. The "bin"
# directory is traditional and normal. Module::Build should support
# this...dummies.
sub process_bin_files {
	my $self = shift;

	my $files = $self->find_all_files('bin', 'bin');

	while (my ($file, $dest) = each %$files) {
		$self->copy_if_modified(from => $file, to => File::Spec->catfile($self->blib, $dest) );
		$self->make_executable(File::Spec->catfile($self->blib, $dest));
	}
}

sub process_plugin_files {
	my $self = shift;

	my $files = $self->find_all_files('plugin', 'plugins');

	while (my ($file, $dest) = each %$files) {
		$self->copy_if_modified(from => $file, to => File::Spec->catfile($self->blib, $dest) );
	}
}

sub process_agent_files {
	my $self = shift;

	my $files = $self->find_all_files('agent', 'agents');

	while (my ($file, $dest) = each %$files) {
		$self->copy_if_modified(from => $file, to => File::Spec->catfile($self->blib, $dest) );
	}
}

sub process_config_files {
	my $self = shift;

	my $files = $self->find_all_files('cofig', 'etc');

	while (my ($file, $dest) = each %$files) {
		$self->copy_if_modified(from => $file, to => File::Spec->catfile($self->blib, $dest) );
	}
}

sub skip_files {
	return 0 if -d $File::Find::name;
	!m/\bRCS\b|\bCVS\b|,v$|\B\.svn\b|~$|\.tmp$|\.old$|\.bak$|\#$|\b\.#|\.in$|\.sw.?$/;
}

sub find_all_files {
	my $self = shift;
	my $type = shift;
	my $dir  = shift;

	if (my $files = $self->{properties}{"${type}_files"}) {
		return { map $self->localize_file_path($_), %$files };
	}

	return {} unless -d $dir;
	return { map {$_, $_}
		map $self->localize_file_path($_),
		grep !/\.#/,
		@{ $self->rscan_dir($dir, \&skip_files) } };
}
));

my $build = $subclass->new(
	module_name        => 'FleetConf',
	dist_version_from  => 'lib/FleetConf.pm',
	license            => 'perl',
	create_makefile_pl => 'passthrough',
	create_readme      => 1,
	requires           => {
		'YAML'             => '0.39',
		'Log::Dispatch'    => '2.10',
	},
);

$build->{properties}{install_base} ||= '/usr/local/FleetConf';
print STDERR "\nInstall Base: $build->{properties}{install_base}\n\n";

# This is a lame heuristic, oh well...
unless ($build->{properties}{install_base} =~ /FleetConf/i) {
	warn "FleetConf ***REALLY*** ***REALLY*** wants to be installed in a\n";
	warn "separate directory. Please make sure you do or you will regret\n";
	warn "not doing so later!!!\n\n";

	my $oldv = $|;
	$| = 1;
	print "\a";
	sleep 1;
	print "\a";
	sleep 1;
	print "\a";
	sleep 1;
	print "\a";
	$| = $oldv;
}

my $root = $build->{properties}{install_base};
$build->{properties}{install_path}{'bin'}     ||= "$root/bin";
$build->{properties}{install_path}{'etc'}     ||= "$root/etc";
$build->{properties}{install_path}{'plugins'} ||= "$root/plugins";
$build->{properties}{install_path}{'agents'}  ||= "$root/agents";

$build->add_build_element('agent');
$build->add_build_element('bin');
$build->add_build_element('plugin');
$build->add_build_element('config');
$build->create_build_script;
