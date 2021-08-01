#!perl

use 5.012; # strict, //
use warnings;
use IPC::Run qw/run/;
use autodie;
use File::Spec::Functions qw/canonpath catfile splitpath splitdir/;

use Test::More;

use FindBin;

our $script = canonpath(catfile($FindBin::Bin, '..', 'src', 'nppConfigCheck.pl'));
diag "SCRIPT_PATH: script = ", $script;
ok -f $script, 'script is where it should be';

# verify run_script_with_args works, and that the perl executable is runnable
{
    my $retval = run_script_with_args( '-V:myuname');
    diag "perl -V:myuname => ", explain $retval;
    is scalar @$retval, 1, 'verify perl runs correctly: `perl -V:myuname` => right number of return lines';
    like $retval->[0], qr/perl/i, 'verify perl runs correctly: `perl -V:myuname` => first line mentions perl';
}

done_testing; exit; # delete line

# this one will just try to run with various args.pl
{
    # I know I've fully tested findNppDir() in nppcc_dir.t, but I need to override these to make sure I get the right script output
    #   of course spending too much time on the existing version of the script's output (which is likely going to change)
    #   is probably not worth it
    local $ENV{PATH} = "PathDirectory";
    local $ENV{ProgramW6432} = 'ProgramW6432';
    local $ENV{ProgramFiles} = 'ProgramFiles';
    local $ENV{'ProgramFiles(x86)'} = 'ProgramFiles(x86)';

    my $ret = run_script_with_args($script);
    diag "ret = ", explain $ret;
    is scalar(@$ret), 4, 'run(): correct number of lines returned' or diag explain $ret;
    is shift(@$ret), 'could not find an instance of Notepad++; please add it to your path', 'run(): line 1 correct';
    my $line2 = shift(@$ret);
    my $regex = qr{^\h+at (.*) line 24\.$};
    like $line2, $regex, 'run(): line 2 looks correct';
    my($pathVal) = ($line2 =~ /$regex/); #diag "\$1 = '$1' vs \$pathVal = '$pathVal'";
    my ($v,$p,$f) = splitpath($pathVal); #diag "splitpath => (v:$v, p:$p, f:$f)";
    my @dirs = splitdir($p); #diag "dirs => ", explain \@dirs;
    my $lastDir = $dirs[-2];
    is $lastDir, 'src', 'run(): line 2: correct subdirectory';
    is $f, 'nppConfigCheck.pl', 'run(): line 2: correct script name';
    is shift(@$ret), 'Hello World', 'run(): line 3 correct';
    is shift(@$ret), 'nppPath = <undef>', 'run(): line 4 correct';
}

done_testing();

sub run_script_with_args
{
    my @cmd = @_;
    unshift @cmd, $^X;
    my ($outstr, $errstr);
    diag "run(", join(', ', map qq("$_"), @cmd), ") into strings";
    run \@cmd, \undef, \$outstr, \$errstr;
    #print "string = ($string)\n";
    my @out = map { chomp; $_ } map {split /\n/, $_} $errstr, $outstr;
    return \@out
}

__END__

$ret = run_perl_with_args($^X, qw{d1.pl});
is_deeply $ret, [
   '',
   'STDERR: called as "d1.pl()"',
   '',
   'STDOUT: called as "d1.pl()"'
], 'no args' or diag explain $ret;

$ret = run_perl_with_args($^X, qw{d1.pl --option val -single});
is_deeply $ret, [
  '',
  'STDERR: called as "d1.pl("--option", "val", "-single")"',
  '',
  'STDOUT: called as "d1.pl("--option", "val", "-single")"'
], 'multiple args' or diag explain $ret;

done_testing();
exit;

sub old_run_perl_with_args
{
    my @cmd = @_;
    # system()
    open my $fh, '>', 'outfile.txt';
    run \@cmd, \undef, $fh, $fh;
    #print "string = ($string)\n";
    close $fh;
    open my $ifh, '<', 'outfile.txt';
    my @out = map { chomp; $_ } <$ifh>;
    #printf "outfile(@cmd): >>%s<<\n", $_ for grep { /^.+$/ } @out;
    close $ifh;
    return \@out
}

sub run_perl_with_args
{
    my @cmd = @_;
    my ($outstr, $errstr);
    run \@cmd, \undef, \$outstr, \$errstr;
    #print "string = ($string)\n";
    my @out = map { chomp; $_ } map {split /\n/, $_} $errstr, $outstr;
    return \@out
}
