#!perl
package testsuite;

use 5.012;  # strict, say, state
use warnings;
use Test::More;
use Test::Exception;
use File::Spec::Functions qw/catpath splitpath catdir splitdir updir/;

use FindBin;
use lib "$FindBin::Bin/../src/lib";

# verify module under test loads and will import function under test
use_ok 'NppCC', 'findNppDir';

# verify function under test exists in both namespaces
can_ok 'NppCC', 'findNppDir';
can_ok 'testsuite', 'findNppDir';

sub cleanpath {
    my $in = shift;
    my ($v,$p,$f) = splitpath($in);
    my $out = catpath( $v, catdir(splitdir($p)), '');
}

my $exePath = cleanpath("$FindBin::Bin/Notepad++/") or die "error cleaning exePath";
ok defined $exePath, 'exePath = ' . $exePath // '<undef>';
my $progFiles = cleanpath("$FindBin::Bin/") or die "error cleaning progFiles";
ok defined $progFiles, 'progFiles = ' . $progFiles // '<undef>';

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

#use Data::Dumper;  ++$Data::Dumper::Sortkeys;
#diag Dumper \%:: ;

done_testing;
