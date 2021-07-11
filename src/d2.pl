#!perl

use 5.012; # //, strict, say
use warnings;
use autodie;

my $string = "original\none";
print STDOUT "normal STDOUT: ", __LINE__, "\n";
wrap_do();
print STDOUT "normal STDOUT: ", __LINE__, "\n";
wrap_do('./d1.pl');
print STDOUT "normal STDOUT: ", __LINE__, "\n";
wrap_do('./d1.pl', 'one', 'two');
print STDOUT "normal STDOUT: ", __LINE__, "\n";

printf STDOUT qq(\ncalled as "%s(%s)"\n), $0, join(', ', map qq("$_"), @ARGV);

sub wrap_do
{
    (my $file, my @ARGV) = @_;
    open my $oldout, ">&", \*STDOUT;                        # duplicate oldout from STDOUT
    close STDOUT;                                           # close the original (required before redirecting)
    open STDOUT, '>', \$string;                             # string will contain whatever is printed to STDOUT
    print STDOUT "Hello World __", __LINE__, "__\n";        # actually into string instead of STDOUT
    print STDOUT "filename: $file\n" if defined $file;      # filename
    if(@ARGV) {
        local $" = ", ";
        print STDOUT "ARGV = (@ARGV)\n";
    }
    # TODO: call `do $file` with localized @ARGV
    print STDOUT "Farewell World __", __LINE__, "__\n";     # actually into string instead of STDOUT
    print {$oldout} "OLDOUT: look at string >>$_<<\n" for map { chomp; $_; } split /\n/, $string;
    close STDOUT;
    open STDOUT, '>&', $oldout;                         # return to normal
}
