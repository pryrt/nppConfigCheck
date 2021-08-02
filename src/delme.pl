#!perl -l

use 5.012;  # strict, say
use warnings;
use Getopt::Long;
use Pod::Usage;

use FindBin;
use lib "$FindBin::Bin/lib";
use NppCC 'findNppDir';

our $VERSION = '0.001';

BEGIN { print "Hello World"; }

my %arg = (
    path => undef,
);

sub init {
    GetOptions(
        "path=s" => \$arg{path},
    ) or do {
        pod2usage( sprintf qq(\nunknown command line '%s(%s)'\n) , $0, join(', ', @ARGV));
    };
    $arg{path} //= findNppDir()
}

1;
