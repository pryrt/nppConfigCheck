#!perl

package NppCfgChk;

use 5.012;  # strict, say, state
use warnings;
use warnings::register;
use File::Which 'which';
use File::Spec::Functions qw/catpath splitpath catdir splitdir/;

use Exporter 5.57 'import';

our $VERSION = '0.001'; # master version number; scripts and other modules inherit this value

our @EXPORT_OK = qw/findNppDir/;
our %EXPORT_TAGS = (
    all     => [@EXPORT_OK],
);

sub findNppDir {
    my $npp_path;
    #return $npp_path if defined $npp_path;

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
    unless(defined $npp_path) {
        warnings::warnif "could not find an instance of Notepad++; please add it to your path\n";
        return undef;
    }

    # remove the executable and just return the directory
    my ($v,$p,$f) = splitpath($npp_path);
    $npp_path = catpath( $v, catdir(splitdir($p)), '' );    # use cat(split) to fix mismatched slashes

    return $npp_path;
}

1;
