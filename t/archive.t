#!perl
package testsuite;

use 5.012;  # strict, say, state
use warnings;
use Test::More;
use Test::Exception;

use FindBin;
use lib "$FindBin::Bin/../src/lib";

BEGIN { use_ok('NppCfgChk::Archive'); }

my $archive;
throws_ok { $archive = NppCfgChk::Archive->fromPath("$FindBin::Bin/", undef, 1); } qr/\Qarchive is missing files\E/,  'fromPath(directory): invalid source directory throws error';
lives_ok  { $archive = NppCfgChk::Archive->fromPath("$FindBin::Bin/settings", undef, 1); } 'fromPath(directory): source directory archive successful';
lives_ok  { $archive = NppCfgChk::Archive->fromPath("$FindBin::Bin/settings"); } 'fromPath(directory): destination directory archive successfully';
isa_ok $archive, 'NppCfgChk::Archive';
ok !$archive->isZip, 'fromPath(directory): not a zip archive';

my $zipped;
throws_ok { $zipped = NppCfgChk::Archive->fromPath("$FindBin::Bin/settings/missing_settings.zip"); } qr/\Qarchive is missing files\E/, 'fromPath(zip) correctly dies: archive is missing files';
lives_ok  { $zipped = NppCfgChk::Archive->fromPath("$FindBin::Bin/settings/settings.zip"); } 'fromPath(zip) correctly lives: archive has all required files';
isa_ok $zipped, 'NppCfgChk::Archive';
ok $zipped->isZip, 'frompath(zip): is a zip archive';

done_testing;
