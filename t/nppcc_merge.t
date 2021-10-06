#!perl
package testsuite;

use 5.012;  # strict, say, state
use warnings;
use Test::More;
use Test::Exception;
use File::Spec::Functions qw/catpath splitpath catfile catdir splitdir updir/;

use FindBin;
use lib "$FindBin::Bin/../src/lib";
use NppCfgChk qw/mergeContents/;

{
    # initial error checking
    throws_ok { mergeContents() } qr/\Qneed source data\E/, 'mergeContents ERROR: need source data';
    throws_ok { mergeContents('<top/>') } qr/\Qneed destination data\E/, 'mergeContents ERROR: need destination data';
    throws_ok { mergeContents('<top/>', '<top/>') } qr/\Qneed configuration\E/, 'mergeContents ERROR: need configuration';
    throws_ok { mergeContents('<top/>', '<top/>', 'scalar')} qr/\Qconfig must be reference\E/, 'mergeContents ERROR: config must be reference';
    throws_ok { mergeContents('<top/>', '<top/>', [])} qr/\Qconfig must be hashref\E/, 'mergeContents ERROR: config must be hashref';
    throws_ok { mergeContents('<top/>', '<top/>', {})} qr/\Qconfig must have keys\E/, 'mergeContents ERROR: config must have keys';
    dies_ok { mergeContents('<invalid', '<top/>', {key=>'value'}) } 'mergeContents ERROR: invalid source XML';
    dies_ok { mergeContents('<top/>', '<invalid', {key=>'value'}) } 'mergeContents ERROR: invalid destination XML';
    lives_ok { mergeContents('<top/>', '<top/>', {key=>'value'}) } 'mergeContents: done with error checking';
}

{
    # merge in missing attributes
    my $src_string =<<EOSRC;
<top>
    <Item id="unique" first="1" extra="2" />
    <Item id="314159" first="1" extra="2" />
    <Item id="271828" first="1" extra="2" />
</top>
EOSRC
    my $dst_string =<<EODST;
<top>
    <Item id="271828" first="one" file="dest" />
    <Item id="314159" extra=".ext" file="dest" />
    <Item id="161803" file="dest">PHI</Item>
</top>
EODST
    my $retval = mergeContents( $src_string, $dst_string, {Item=>'id'});
    ok scalar @$retval, 'DEBUG TEST: reasonable array length'
        or 1;
        diag "retval => ", explain $retval;
}

ok 1;

done_testing;
