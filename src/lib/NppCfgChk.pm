#!perl

package NppCfgChk;

use 5.012;  # strict, say, state
use warnings;
use warnings::register;
use File::Which 'which';
use File::Spec::Functions qw/catpath splitpath catdir splitdir/;

use Exporter 5.57 'import';

our $VERSION = '0.001'; # master version number; scripts and other modules inherit this value

our @EXPORT_OK = qw/findNppDir/;
our %EXPORT_TAGS = (
    all     => [@EXPORT_OK],
);

sub findNppDir
{
    my $npp_path;
    #return $npp_path if defined $npp_path;

    # priority to path, 64bit, default, then x86-specific locations
    my @try = ( which('notepad++') );
    push @try, "$ENV{ProgramW6432}/Notepad++/notepad++.exe" if exists $ENV{ProgramW6432};
    push @try, "$ENV{ProgramFiles}/Notepad++/notepad++.exe" if exists $ENV{ProgramFiles};
    push @try, "$ENV{'ProgramFiles(x86)'}/Notepad++/notepad++.exe" if exists $ENV{'ProgramFiles(x86)'};
    foreach my $try ( @try )
    {
        $npp_path = $try if -x $try;
        last if defined $npp_path;
    }
    unless(defined $npp_path) {
        warnings::warnif "could not find an instance of Notepad++; please add it to your path\n";
        return undef;
    }

    # remove the executable and just return the directory
    my ($v,$p,$f) = splitpath($npp_path);
    $npp_path = catpath( $v, catdir(splitdir($p)), '' );    # use cat(split) to fix mismatched slashes

    return $npp_path;
}

sub grabLocalPath
{
    1;
}
sub grabCurrentVersion
{
    1;
}
sub grabSpecificVersion
{
    1;
}
sub grabDirectoryVersion
{
    1;
}

sub mergeContents
{
    my ($src_contents, $dst_contents, $config) = @_;
    # the problem with this is that each file has a different set of items, and I'm not sure the best way to handle it;
    # for example, in config.xml,
    #   the <GuiConfig> items have unique name attributes, so those would be compared
    #   but I think on the <FindHistory> and <History> save options from those tabs, but don't have a unique name-like
    #   attribute to base the comparison on.
    # Come up with a way to pass in the configuration options:
    #   have $config = { key => value } , where
    #       each key is the element type,
    #       value is the attribute-name of the unique identifier (or `undef` if it's like <History>)
    #
    # The algorithm would then be:
    #   $src = XML::LibXML->load_xml(string => $src_contents)
    #   $dst = XML::LibXML->load_xml(string => $dst_contents)
    #   for each $node in $src
    #   {
    #       $key = $node->type()                # figure out the type of node
    #       next unless exists $config->{$key}  # if that type isn't in config, move on to next node
    #       $id_attr = $config->{$key}          # get the attribute name
    #       $id_val = $node->hasAttribute($id_attr) ? $node->getAttribute($id_attr) : undef;    # get the value of the attribute, or undef
    #       $match_expr = defined $id_val ? qq{//$key[\@$id_attr="$id_val"]} : qq{//$key}       # if available, look for the right type of node with id_attr=id_val, else just look for the right type of node
    #       loop over matching node(s) in destination structure
    #       {
    #           loop over attributes from src node
    #           {
    #               if srcnode.attr doesn't exist in dstnode, replicate it
    #           }
    #       }
    #   }
    }

}

1;
