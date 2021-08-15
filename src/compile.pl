#!perl -l

use 5.012;  # strict, say
use strict;
use warnings;

my @extra_mods = qw(Pod::Simple::Transcode PerlIO::encoding);

print STDERR "running `$0 @ARGV`";
chomp(my $cwd=`echo %CD%`);
print STDERR "cwd: $cwd";
my @cmd =
    $ARGV[0] eq 'bin/nppConfigCheck.exe' ?
    ('pp', map("--module=$_", @extra_mods), '-x', '-o', @ARGV) :
    $ARGV[0] eq 't/Notepad++/notepad++.exe' ?
    do {
        mkdir 't/Notepad++' unless -d 't/Notepad++';
        (qw(gcc -o), @ARGV)
    } :
    die "unknown @ARGV";
print STDERR "becomes `@cmd`";
system(@cmd) and die "error in `@cmd` => $? => $!";
