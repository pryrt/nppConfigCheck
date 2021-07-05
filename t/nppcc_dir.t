#!perl
package testsuite;

use 5.012;  # strict, say, state
use warnings;
use Test::More;
use File::Spec::Functions qw/catpath splitpath catdir splitdir/;

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

my $batchPath = cleanpath("$FindBin::Bin/bin/") or die "error cleaning batchPath";
diag 'batchPath => ', $batchPath // '<undef>';

# only %PATH% is set
{
    local $ENV{PATH} = $batchPath;
    local $ENV{ProgramW6432} = 'ProgramW6432';
    local $ENV{ProgramFiles} = 'ProgramFiles';
    local $ENV{'ProgramFiles(x86)'} = 'ProgramFiles(x86)';
    my $get = findNppDir();
    is $get, $batchPath, 'findNppDir => PATH: ' . $batchPath;
}

# only %ProgramW6432% is set
{
    local $ENV{PATH} = 'PATH';
    local $ENV{ProgramW6432} = $batchPath;
    local $ENV{ProgramFiles} = 'ProgramFiles';
    local $ENV{'ProgramFiles(x86)'} = 'ProgramFiles(x86)';
    my $get = findNppDir();
    is $get, $batchPath, 'findNppDir => ProgramW6432: ' . $batchPath;
}

# only %ProgramFiles% is set
{
    local %ENV;
    local $ENV{PATH} = 'PATH';
    local $ENV{ProgramW6432} = 'ProgramW6432';
    local $ENV{ProgramFiles} = $batchPath;
    local $ENV{'ProgramFiles(x86)'} = 'ProgramFiles(x86)';
    my $get = findNppDir();
    is $get, $batchPath, 'findNppDir => ProgramFiles: ' . $batchPath;
}

# only %ProgramFiles(x86)% is set
{
    local %ENV;
    local $ENV{PATH} = 'PATH';
    local $ENV{ProgramW6432} = 'ProgramW6432';
    local $ENV{ProgramFiles} = 'ProgramFiles';
    local $ENV{'ProgramFiles(x86)'} = $batchPath;
    my $get = findNppDir();
    is $get, $batchPath, 'findNppDir => ProgramFiles: ' . $batchPath;
}

#use Data::Dumper;  ++$Data::Dumper::Sortkeys;
#diag Dumper \%:: ;

done_testing;
