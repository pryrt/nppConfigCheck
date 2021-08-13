#!perl

package NppCfgChk::CLI;

use 5.012; # strict, //
use warnings;
use warnings::register;
use Exporter 5.57 'import';

use Getopt::Long qw/GetOptionsFromArray/;
use Pod::Usage;
use NppCfgChk;

#use FindBin; BEGIN { local $\ ="\n"; print STDERR for $FindBin::Bin, $FindBin::Script; }
# I _could_ use FindBin to get the name, but they warn against distributing
#   a module which calls FindBin, and caller(#) should get me the info I want, anyway

our $VERSION = '0.001'; # auto-populated from NppCfgChk

our @EXPORT_OK = qw/%Configuration/;
our %EXPORT_TAGS = (
    Configuration => [qw/%Configuration/],
    all     => [@EXPORT_OK],
);

our %Configuration = (
    path => undef, # path to current instance
    version => undef, # path to new version
    config => undef, # path to config file
);

sub _usage
{
    my ($msg, $ref) = @_;
    local $" = " ";
    #print STDERR "USAGE: '$msg' (@$ref)";
    print STDERR "caller: (@{[caller()]})\n";
    print STDERR "caller(0): (@{[caller(0)]})\n";
    print STDERR "caller(1): (@{[caller(1)]})\n";
    my $script = (caller(1))[1]; #calling-script's filename
    my $tmp = "\nERROR: $msg\ncommand line: $script @$ref";
    warn $tmp, "\n";
    pod2usage(
        -msg => $tmp,
        -exitvalue => 'NOEXIT',
        -input => $script,      # works in .pl, not in .exe
    );
    undef;  # use a FALSE return value in the caller to trigger pod2usage or similar;
            # actually tempted to trigger pod2usage here, which is why I moved it out
            # into its own function
}

sub run
{
    my @args = @_;
    GetOptionsFromArray(
        \@args,                         # array reference for the ARGV equivalent
        \%Configuration,                # store values in the hash
        ### option definitions start here
        'path=s',
        'version=s',
        'config=s',
    ) or return _usage('Unknown Option', \@_);

    # process PATH
    $Configuration{path} //= NppCfgChk::findNppDir();
    NppCfgChk::grabLocalPath($Configuration{path})
        or return _usage('Invalid local path', \@_);

    # process CONFIG
    #setConfig
    #$Configuration{config} eq 'appdata'

    # process VERSION
    if(!defined $Configuration{version}) {
        NppCfgChk::grabCurrentVersion()
            or return _usage('Cannot find current version', \@_);
    } elsif ( $Configuration{version} =~ /^v/i ) {
        NppCfgChk::grabSpecificVersion($Configuration{version})
            or return _usage('Cannot grab specific version', \@_);
    } else {
        NppCfgChk::grabDirectoryVersion($Configuration{version})
            or return _usage('Cannot find path to version', \@_);
    }

}

1;
__END__

I am referencing dummy functions in NppCfgChk/NppCfgChk that aren't
yet written.

The grabXXXVersion should populate the NppCfgChk data structures
in a way that will make it easy to access the various XML config
files.

I was briefly thinking of merging this back in with NppCfgChk, but
decided against it, because separation of concerns.

OTOH, maybe I want the processing to be handled in the script,
not this module... because having CLI::init() actually
run everything makes it non-atomic and harder to test again.
Or I could call this run(), and have it do everything _including_
the comparison and updates.  In which case, the script wouldn't
need to `use NppCfgChk;`, but it would instead just
    use CLI;
    CLI::run(@ARGV);

Things to think about.
