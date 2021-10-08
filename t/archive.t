#!perl
package testsuite;

use 5.012;  # strict, say, state
use warnings;
use Test::More;
use Test::Exception;

use FindBin;
use lib "$FindBin::Bin/../src/lib";

BEGIN { use_ok('NppCfgChk::Archive'); }

my $archive = NppCfgChk::Archive->fromPath("$FindBin::Bin/settings");
isa_ok $archive, 'NppCfgChk::Archive';
ok !$archive->isZip, 'not a zip archive';

my $zipped;
throws_ok { $zipped = NppCfgChk::Archive->fromPath("$FindBin::Bin/settings/missing_settings.zip"); } qr/\Qarchive is missing files\E/, 'fromPath correctly dies: archive is missing files';
lives_ok  { $zipped = NppCfgChk::Archive->fromPath("$FindBin::Bin/settings/settings.zip"); } 'fromPath correctly lives: archive has all required files';
isa_ok $zipped, 'NppCfgChk::Archive';
ok $zipped->isZip, 'is a zip archive';

done_testing;
