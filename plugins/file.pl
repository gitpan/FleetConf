package FleetConf::Functions;

use Cwd;
use File::Basename;

our $VERSION = '0.01';

sub NewerThan {
	my ($first, $second) = @_;

	my @fstat = CORE::lstat $first;
	my @sstat = CORE::lstat $second;

	return $fstat[9] > $sstat[9];
}

package FleetConf::Commands;

use File::Copy;
use File::Path;

1
