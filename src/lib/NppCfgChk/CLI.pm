#!perl

package NppCfgChk::CLI;

use 5.012; # strict, //
use warnings;
use warnings::register;
use Exporter 5.57 'import';

use GetoptLong qw/GetOptionsFromArray/;
use NppCfgChk;  # I _think_ for this module to be found, the right path must exist for NppCfgChk

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
    undef;  # use a FALSE return value in the caller to trigger pod2usage or similar;
            # actually tempted to trigger pod2usage here, which is why I moved it out
            # into its own function
}

sub init
{
    my @args = @_;
    GetOptionsFromArray(
        \@args,                         # array reference for the ARGV equivalent
        \%Configuration,                # store values in the hash
        ### option definitions start here
        'path=s',
        'version=s',
        'config=s',
    ) or return _usage('Unknown Option', \@args);

    # process PATH
    $Configuration{path} //= NppCfgChk::findNppDir();
    NppCfgChk::grabLocalPath($Configuration{path})
        or return _usage('Invalid local path', \@args);

    # process CONFIG
    NppCfgChk::setConfig
    $Configuration{config} eq 'appdata'

    # process VERSION
    if(!defined $Configuration{version}) {
        NppCfgChk::grabCurrentVersion()
            or return _usage('Cannot find current version', \@args);
    } elsif ( $Configuration{version} =~ /^v/i ) {
        NppCfgChk::grabSpecificVersion($Configuration{version})
            or return _usage('Cannot grab specific version', \@args);
    } else {
        NppCfgChk::grabDirectoryVersion($Configuration{version})
            or return _usage('Cannot find path to version', \@args);
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
not this module... because having NppCfgChk::CLI::init() actually
run everything makes it non-atomic and harder to test again.
Or I could call this run(), and have it do everything _including_
the comparison and updates.  In which case, the script wouldn't
need to `use NppCfgChk;`, but it would instead just
    use NppCfgChk::CLI;
    NppCfgChk::CLI::run(@ARGV);

Things to think about.
