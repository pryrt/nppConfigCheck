#!perl

use 5.012; # strict, //
use warnings;
use Test::More;

use IPC::Run 'run';
use IPC::Open3;
use Symbol 'gensym';
use autodie;

use File::Spec::Functions qw/canonpath catfile splitpath splitdir/;
use FindBin;
my $script = canonpath(catfile($FindBin::Bin, 'p2u.pl'));
diag "script = $script";

my $iret = ipcrun($script);
ok scalar @$iret, 'ipcrun';
diag "ipcrun => ", join "\n", '', @$iret, '';

my $qret = qxrun($script);
ok scalar @$qret, 'qxrun';
diag "qxrun => ", join "\n", '', @$qret, '';

my $o3ret = o3run($script);
ok scalar @$o3ret, 'o3run';
diag "o3run => ", join "\n", '', @$o3ret, '';

done_testing;

sub ipcrun {
    my @cmd = ($^X, @_);
    my ($outstr, $errstr) = ('','');
    diag "ipcrun: start running command:\n";
    eval {
        run \@cmd, \undef, \$outstr, \$errstr;
        1;
    } or do {
        return ["IPC::Run found error", "\$\@:'$@'", "\$!:'$!'", "\$^E:'$^E'", "\$?:'$?'"];
    };
    diag "ipcrun: end running command:\n";
    $outstr =~ s/^(?=.)/\toutstr:\t/gim;
    $errstr =~ s/^(?=.)/\terrstr:\t/gim;
    return [map { chomp; $_ } map {split /\n/, $_} $errstr, $outstr];
}

sub qxrun {
    my $cmd = join(' ', qq(cmd /s /c "), map { qq("$_") } $^X, @_) . ' 2>&1 "';  # have to cmd.exe-redirect to capture both STDERR and STDOUT
    diag "qxrun: start running command `$cmd`:\n";
    my $outstr = qx/$cmd/;
    diag "qxrun: start running command:\n";
    $outstr =~ s/^(?=.)/\tqxrun:\t/gim;

    return [map { chomp; $_ } map {split /\n/, $_} $outstr];
}

sub o3run {
    my @cmd = ($^X, @_);
    diag "o3run: start running command:\n";
    my ($errstr, $outstr) = ('','');
    my $pid = open3(my $fakein, my $auto_out, my $auto_err = gensym, @cmd);
    $errstr = join '', <$auto_err>;
    $outstr = join '', <$auto_out>;
    my $w = waitpid($pid,0);
    my $stat = $? >> 8;
    diag "o3run: done  running command: pid=$pid w=$w stat=$stat\n";
    $outstr =~ s/^(?=.)/\toutstr:\t/gim;
    $errstr =~ s/^(?=.)/\terrstr:\t/gim;
    return [map { chomp; $_ } map {split /\n/, $_} $errstr, $outstr];
}
