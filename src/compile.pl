#!perl -l

use 5.012;  # strict, say
use strict;
use warnings;

print STDERR "running `$0 @ARGV`";
chomp(my $cwd=`echo %CD%`);
print STDERR "cwd: $cwd";
my @cmd = (qw(pp -x -o), @ARGV);
print STDERR "becomes `@cmd`";
system(@cmd) and die "error in `@cmd` => $? => $!";
