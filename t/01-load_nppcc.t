#!perl
package testsuite;

use 5.012;  # strict, say, state
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/../src/lib";

# verify module under test loads and will import function under test
use_ok 'NppCC', 'findNppDir';

# verify function under test exists in both namespaces
can_ok 'NppCC', 'findNppDir';
can_ok 'testsuite', 'findNppDir';

done_testing;
