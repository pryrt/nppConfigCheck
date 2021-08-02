#!perl -l

use 5.012;  # strict, say
use warnings;
use Getopt::Long;
use Pod::Usage;

use FindBin;
use lib "$FindBin::Bin/lib";
use NppCC 'findNppDir';

our $VERSION = '0.001';

print "Hello World";

1;
