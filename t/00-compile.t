#!perl
package testsuite;

use 5.012;  # strict, say, state
use warnings;
use Test::More;

use FindBin;

ok -x "$FindBin::Bin/../bin/nppConfigCheck.exe", 'compile OK: nppConfigCheck.exe';
ok -x "$FindBin::Bin/../t/Notepad++/notepad++.exe", 'compile OK: pseudo notepad++.exe';

done_testing;
