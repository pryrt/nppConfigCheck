#!perl
package testsuite;

use 5.012;  # strict, say, state
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/../src/lib";

# verify proper loading
BEGIN {
    require_ok 'NppCC';
    NppCC->import('findNppDir');
}

# verify
can_ok 'NppCC', 'findNppDir';
can_ok 'testsuite', 'findNppDir';

#use Data::Dumper;  ++$Data::Dumper::Sortkeys;
#diag Dumper \%:: ;

done_testing;
