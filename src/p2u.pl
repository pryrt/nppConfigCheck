#!perl
use 5.012; # strict, //
use warnings;
use Pod::Usage;

BEGIN {
    $|++;
    print "Hello World";
    print "ENV{$_} => $ENV{$_}\n" for sort keys %ENV;
}

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
