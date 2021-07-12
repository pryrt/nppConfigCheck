#!perl

use 5.012; # strict, //
use warnings;
use IPC::Run qw/run/;
use autodie;
use Test::More;

# this one will just try to run with various args.pl
my $ret = run_perl_with_args(qw{cmd /c echo hello world});
is_deeply $ret, ['hello world'], 'hello world';

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
