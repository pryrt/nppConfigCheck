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
    throws_ok { mergeContents() } qr/\Qneed source data\E/, 'mergeContents SHOULD ERROR: need source data';
    throws_ok { mergeContents('<top/>') } qr/\Qneed destination data\E/, 'mergeContents SHOULD ERROR: need destination data';
    throws_ok { mergeContents('<top/>', '<top/>') } qr/\Qneed configuration\E/, 'mergeContents SHOULD ERROR: need configuration';
    throws_ok { mergeContents('<top/>', '<top/>', 'scalar')} qr/\Qconfig must be reference\E/, 'mergeContents SHOULD ERROR: config must be reference';
    throws_ok { mergeContents('<top/>', '<top/>', [])} qr/\Qconfig must be hashref\E/, 'mergeContents SHOULD ERROR: config must be hashref';
    throws_ok { mergeContents('<top/>', '<top/>', {})} qr/\Qconfig must have keys\E/, 'mergeContents SHOULD ERROR: config must have keys';
    dies_ok { mergeContents('<invalid', '<top/>', {key=>'value'}) } 'mergeContents SHOULD ERROR: invalid source XML';
    dies_ok { mergeContents('<top/>', '<invalid', {key=>'value'}) } 'mergeContents SHOULD ERROR: invalid destination XML';
    lives_ok { mergeContents('<top/>', '<top/>', {key=>'value'}) } 'mergeContents: completed parameter checking';
    throws_ok { mergeContents('<top><item id="1"/></top>', '<xtop/>', {item=>'id'}) } qr/\Qparent not found in destination/, 'mergeContents SHOULD ERROR: parent not found in destination';
}

{
    # merge in missing attributes
    my $src_string =<<EOSRC;
<top a1="x">
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
    SKIP: {
        skip 'test only valid for debug structure', 4 unless ref $retval and UNIVERSAL::isa($retval, 'ARRAY');
        diag "debug => ", explain $retval;
        my $last = $retval->[-1];
        my $ok = 1;
        $ok &&= ok defined $last, 'DEBUG: structure ends with defined array element';
        $ok &&= ok ref($last), 'DEBUG: final element is reference';
        $ok &&= ok UNIVERSAL::isa($last, 'HASH'), 'DEBUG: final element is hashref';
        $ok &&= ok exists $last->{'final_destination'}, 'DEBUG: structure defines final destination';
        $ok &&= $retval = $last->{'final_destination'};
        $ok or diag "\t last => ", explain $last;
    };
    my $ok = 1;
    $ok &&= ok defined $retval, 'mergeContents OUTPUT: must be defined';
    $ok &&= ok !ref($retval), 'mergeContents OUTPUT: must be scalar';
    $ok &&= like $retval, qr/^(?=.*id="314159")(?=.*first="1").*$/m, 'mergeContents OUTPUT: id=314159 adds attribute first="1"';
    $ok &&= like $retval, qr/^(?=.*id="271828")(?=.*extra="2").*$/m, 'mergeContents OUTPUT: id=271828 adds attribute extra="2"';
    $ok &&= like $retval, qr/^(?=.*id="unique").*$/m, 'mergeContents OUTPUT: adds element <Item id="unique">';
    $ok or diag "debug => ", explain $retval;

}

ok 1;

done_testing;
