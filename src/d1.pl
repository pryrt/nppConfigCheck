#!perl

use 5.012; # //, strict, say
use warnings;

printf STDERR qq(\ncalled as "%s(%s)"\n), $0, join(', ', map qq("$_"), @ARGV);
