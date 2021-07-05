#!perl

package NppCC;

use 5.012;  # strict, say, state
use warnings;
use File::Which 'which';
use File::Spec;

use Exporter 5.57 'import';

our $VERSION = '0.001'; # replicated from nppConfigCheck.pl

our @EXPORT_OK = qw/findNppDir/;
our %EXPORT_TAGS = (
    all     => [@EXPORT_OK],
);

sub _hidden { 1; }
sub findNppDir {
    state $npp_path;
    return $npp_path if defined $npp_path;

    # priority to path, 64bit, default, then x86-specific locations
    my @try = ( which('notepad++') );
    push @try, "$ENV{ProgramW6432}/Notepad++/notepad++.exe" if exists $ENV{ProgramW6432};
    push @try, "$ENV{ProgramFiles}/Notepad++/notepad++.exe" if exists $ENV{ProgramFiles};
    push @try, "$ENV{'ProgramFiles(x86)'}/Notepad++/notepad++.exe" if exists $ENV{'ProgramFiles(x86)'};
    foreach my $try ( @try )
    {
        $npp_path = $try if -x $try;
        last if defined $npp_path;
    }
    warn "could not find an instance of Notepad++; please add it to your path\n" and return undef unless defined $npp_path;

    # remove the executable and just return the directory
    $npp_path = File::Spec->catpath( (File::Spec->splitpath($npp_path))[0..1] );

    return $npp_path;
}

1;
