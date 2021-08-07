#!perl
use 5.012; # strict, //
use warnings;
use Getopt::Long;
use Pod::Usage;

BEGIN {
    $|++;
    print "Hello World";
    print "ENV{$_} => $ENV{$_}\n" for sort keys %ENV;
}

use FindBin;
use lib "$FindBin::Bin/lib";
#use NppCC 'findNppDir';

use File::Spec::Functions qw/catfile/;

sub init
{
    pod2usage(
        -message => "message here",
        -exitval => 2,
    );
}

init();

=pod

=head1 EXAMPLE

blah

=head1 USAGE

usage here

=cut
