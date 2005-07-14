package FleetConf::Functions;

our $VERSION = '0.01';

# Stuff imported from the Perl CORE API

sub IsReadable { -r CORE::shift() }
sub IsWritable { -w CORE::shift() }
sub IsExecutable { -x CORE::shift () }
sub IsOwned { -o CORE::shift() }

sub IsReallyReadable { -R CORE::shift() }
sub IsReallyWritable { -W CORE::shift() }
sub IsReallyExecutable { -X CORE::shift() }
sub IsReallyOwned { -O CORE::shift() }

sub IsPathExists { -e CORE::shift() }
sub IsEmpty { -z CORE::shift() }
sub IsNonEmpty { -s CORE::shift() }
sub FileSize { -s CORE::shift() }

sub IsFile { -f CORE::shift() }
sub IsDir { -d CORE::shift() }
sub IsSymLink { -l CORE::shift() }
sub IsPipe { -p CORE::shift() }
sub IsSocket { -s CORE::shift() }
sub IsBlockSpecial { -b CORE::shift() }
sub IsCharSpecial { -c CORE::shift() }
sub IsTTY { -t CORE::shift() }

sub IsSetUID { -u CORE::shift() }
sub IsSetGID { -g CORE::shift() }
sub IsSticky { -k CORE::shift() }

sub IsASCII { -T CORE::shift() }
sub IsBinary { -B CORE::shift() }

sub ModificationDays { -M CORE::shift() }
sub AccessDays { -A CORE::shift() }
sub ChangeDays { -A CORE::shift() }

sub abs { CORE::abs(CORE::shift) }
sub atan2 { CORE::atan2(CORE::shift, CORE::shift) }
sub chomp { my $x = CORE::shift; CORE::chomp $x; $x }
sub chop { my $x = CORE::shift; CORE::chop $x; $x }
sub chr { CORE::chr(CORE::shift) }
sub cos { CORE::cos(CORE::shift) }
sub crypt { CORE::crypt(CORE::shift, CORE::shift) }

no warnings 'redefine';
sub defined { CORE::defined(CORE::shift); }
use warnings 'redefine';

sub exp { CORE::exp(CORE::shift) }
#*getpgrp = \&CORE::getpgrp;
#*getppid = \&CORE::getppid;
#*getpriority = \&CORE::getpriority;
#*getpwnam = \&CORE::getpwnam;
#*getgrnam = \&CORE::getgrnam;
#*gethostbyname = \&CORE::gethostbyname;
#*getprotobyname = \&CORE::getprotobyname;
#*getpwuid = \&CORE::getpwuid;
#*getgrgid = \&CORE::getgrgid;
#*getservbyname = \&CORE::getservbyname;
#*gethostbyaddr = \&CORE::gethostbyaddr;
#*getnetbyaddr = \&CORE::getnetbyaddr;
#*getprotobynumber = \&CORE::getprotobynumber;
#*getservbyport = \&CORE::getservbyport;

sub glob { [ CORE::glob(CORE::shift()) ] }
sub gmtime { [ CORE::gmtime(CORE::shift()) ] }
sub grep { my ($expr, $list) = @_; [ CORE::grep($expr, @$list) ] }

sub hex { CORE::hex(CORE::shift) }
sub index { CORE::index(CORE::shift, CORE::shift, CORE::shift) }
sub int { CORE::int(CORE::shift) }
sub join { CORE::join(@{CORE::shift()}) }
sub lc { CORE::lc(CORE::shift) }
sub lowercase { CORE::lc(CORE::shift) }
sub lcfirst { CORE::lcfirst(CORE::shift) }
sub length { CORE::length(CORE::shift) }
sub log { CORE::log(CORE::shift) }
sub lstat { CORE::lstat(CORE::shift) }
sub oct { CORE::oct(CORE::shift) }
sub ord { CORE::ord(CORE::shift) }
sub pack { my ($tmpl, $list) = @_; [ CORE::pack($tmpl, @$list) ] }
sub pop { CORE::pop(@{ $_[0] }) }
sub push { my $list = CORE::shift; CORE::push(@$list, @_)}
sub quotemeta { CORE::quotemeta(CORE::shift) }
sub rand { CORE::rand(CORE::shift) }

sub replace {
	my $str = CORE::shift;
	my $pattern = CORE::shift;
	my $replacement = CORE::shift;

	$str =~ s/$pattern/$replacement/;

	return $str;
}

sub reverse { [ CORE::reverse(@{ $_[0] }) ] }
sub rindex { CORE::rindex(CORE::shift, CORE::shift, CORE::shift) }
sub scalar { CORE::scalar(@{CORE::shift()}) }
sub size { CORE::scalar(@{CORE::shift()}) || 0 } # not really a Perl thing, but it makes a lot more sense to most peeps than "scalar(some_array)"
sub shift { CORE::shift(@{ $_[0] }) }
sub sin { CORE::sin(CORE::shift) }
sub sort { [ CORE::sort(@{ $_[0] }) ] }
sub splice { my $list = CORE::shift; my $offset = CORE::shift; my $length = CORE::shift; [ CORE::splice(@$list, $offset, $length, @_) ] }
sub split { [ CORE::split $_[0], $_[1] ] }
sub sprintf { CORE::sprintf(@_) }
sub sqrt { CORE::sqrt(CORE::shift) }
sub srand { CORE::srand(CORE::shift) }
sub stat { CORE::stat(CORE::shift) }
sub substr { CORE::substr(CORE::shift, CORE::shift, CORE::shift, CORE::shift) }
sub time { CORE::time }
sub times { [ CORE::times ] }
sub uc { CORE::uc(CORE::shift) }
sub uppercase { CORE::uc(CORE::shift) }
sub ucfirst { CORE::ucfirst(CORE::shift) }
sub upack { [ CORE::unpack($_[0], $_[1]) ] }
sub unshift { my $list = CORE::shift; CORE::unshift(@$list, @_) }

sub OS { return $^O }

1
