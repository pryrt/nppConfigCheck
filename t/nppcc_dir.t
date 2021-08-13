#!perl
package testsuite;

use 5.012;  # strict, say, state
use warnings;
use Test::More;
use Test::Exception;
use File::Spec::Functions qw/catpath splitpath catfile catdir splitdir updir/;

use FindBin;
use lib "$FindBin::Bin/../src/lib";
use NppCfgChk qw/findNppDir/;

sub cleanpath {
    my $in = shift;
    my ($v,$p,$f) = splitpath($in);
    my $out = catpath( $v, catdir(splitdir($p)), '');
}

my $progFiles = cleanpath("$FindBin::Bin/") or die "error cleaning progFiles";
ok defined $progFiles, 'defined: progFiles = ' . $progFiles // '<undef>';
ok -d $progFiles, 'progFiles exists';
my $exePath = cleanpath("$progFiles/Notepad++/") or die "error cleaning exePath";
ok defined $exePath, 'defined: exePath = ' . $exePath // '<undef>';
ok -d $exePath, 'exePath exists';
my $exeFile = catfile($exePath, 'notepad++.exe');
ok defined $exeFile, 'defined: exeFile = ' . $exeFile//'<undef>';
ok -f $exeFile, 'exeFile exists';
ok -x $exeFile, 'exeFile executable';

# only %PATH% is set
{
    local $ENV{PATH} = $exePath;
    local $ENV{ProgramW6432} = 'ProgramW6432';
    local $ENV{ProgramFiles} = 'ProgramFiles';
    local $ENV{'ProgramFiles(x86)'} = 'ProgramFiles(x86)';
    my $get = findNppDir();
    is $get, $exePath, 'findNppDir => PATH: ' . $exePath;
    (my $ran = `$exePath/notepad++ PATH BASED`) =~ s/\s*$//ms;
    like $ran, qr/^running:.*\Qnotepad++ PATH BASED\E$/ms, 'verify PATH-based notepad++.exe ran';
}

# only %ProgramW6432% is set
{
    local $ENV{PATH} = 'PATH';
    local $ENV{ProgramW6432} = $progFiles;
    local $ENV{ProgramFiles} = 'ProgramFiles';
    local $ENV{'ProgramFiles(x86)'} = 'ProgramFiles(x86)';
    my $get = findNppDir();
    is $get, $exePath, 'findNppDir => ProgramW6432: ' . $exePath;
    (my $ran = `$exePath/notepad++ ProgramW6432`) =~ s/\s*$//ms;
    like $ran, qr/^running:.*\Qnotepad++ ProgramW6432\E$/ms, 'verify PATH-based notepad++.exe ran';
}

# only %ProgramFiles% is set
{
    local %ENV;
    local $ENV{PATH} = 'PATH';
    local $ENV{ProgramW6432} = 'ProgramW6432';
    local $ENV{ProgramFiles} = $progFiles;
    local $ENV{'ProgramFiles(x86)'} = 'ProgramFiles(x86)';
    my $get = findNppDir();
    is $get, $exePath, 'findNppDir => ProgramFiles: ' . $exePath;
    (my $ran = `$exePath/notepad++ ProgramFiles`) =~ s/\s*$//ms;
    like $ran, qr/^running:.*\Qnotepad++ ProgramFiles\E$/ms, 'verify PATH-based notepad++.exe ran';
}

# only %ProgramFiles(x86)% is set
{
    local %ENV;
    local $ENV{PATH} = 'PATH';
    local $ENV{ProgramW6432} = 'ProgramW6432';
    local $ENV{ProgramFiles} = 'ProgramFiles';
    local $ENV{'ProgramFiles(x86)'} = $progFiles;
    my $get = findNppDir();
    is $get, $exePath, 'findNppDir => ProgramFiles(x86): ' . $exePath;
    (my $ran = `$exePath/notepad++ ProgramFiles(x86)`) =~ s/\s*$//ms;
    like $ran, qr/^running:.*\Qnotepad++ ProgramFiles(x86)\E$/ms, 'verify PATH-based notepad++.exe ran';
}

# none are set, so no path found; verify undef and proper warning
{
    local %ENV;
    local $ENV{PATH} = 'PATH';
    local $ENV{ProgramW6432} = 'ProgramW6432';
    local $ENV{ProgramFiles} = 'ProgramFiles';
    local $ENV{'ProgramFiles(x86)'} = 'ProgramFiles(x86)';

    {
        no warnings 'NppCfgChk';
        my $get = findNppDir();
        is $get, undef, 'findNppDir => check for not found';
    }

    {
        use warnings FATAL => 'NppCfgChk';
        throws_ok { findNppDir() } qr/\Qcould not find an instance of Notepad++; please add it to your path\E/, 'warns on no executable found';
    }

}

done_testing;
