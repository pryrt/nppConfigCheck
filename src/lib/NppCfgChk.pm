#!perl

package NppCfgChk;

use 5.012;  # strict, say, state
use warnings;
use warnings::register;
use File::Which 'which';
use File::Spec::Functions qw/catpath splitpath catdir splitdir/;

use Exporter 5.57 'import';
use Carp;
use XML::LibXML '1.70';

our $VERSION = '0.001'; # master version number; scripts and other modules inherit this value

our @EXPORT_OK = qw/findNppDir mergeContents/;
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
    # To pass in the configuration options:
    #   have $config = { key => value } , where
    #       each key is the element type,
    #       value is the attribute-name of the unique identifier
    #       ... or `undef` if it's like <History>
    croak "need source data" unless defined $src_contents;
    croak "need destination data" unless defined $dst_contents;
    croak "need configuration" unless defined $config;
    croak "config must be reference" unless ref($config);
    croak "config must be hashref" unless UNIVERSAL::isa($config, 'HASH');
    croak "config must have keys" unless keys %$config;

    my $src = XML::LibXML->load_xml(string => $src_contents);
    my $dst = XML::LibXML->load_xml(string => $dst_contents);

    #print "src: $_\n" for $src->findnodes('/top/*');
    #print "dst: $_\n" for $dst->findnodes('/top/*');

    my $dbg = [];

    for my $src_node ( $src->findnodes('//*') )
    {
        my $key = $src_node->nodeName();        # gives <elementName ...>
        next unless exists $config->{$key};     # skip if it's not a configured element
        my $id_attr = $config->{$key};
        my $id_val = $src_node->hasAttribute($id_attr) ? $src_node->getAttribute($id_attr) : undef;
        my $match_xpath= defined $id_val ? qq{//$key\[\@$id_attr="$id_val"]} : qq{//$key};          # if available, look for the right type of node with id_attr=id_val, else just look for the right type of node
        my @dnodes;
        for my $dst_node ( $dst->findnodes($match_xpath) )
        {
            my $struct = {'dst_node' => "$dst_node"};
            for my $attr_obj ( $src_node->attributes )
            {
                my $attr_name = $attr_obj->nodeName();
                next if $attr_name eq $id_attr;
                my $attr_value = $attr_obj->nodeValue();
                $struct->{looking_for}{$attr_name} = $attr_value;
                if( $dst_node->hasAttribute($attr_name) ) {
                    $struct->{found}{$attr_name} = sprintf "already has %s=%s", $attr_name, $dst_node->getAttribute($attr_name);
                } else {
                    $dst_node->setAttribute($attr_name, $attr_value);
                    $struct->{added}{$attr_name} = sprintf "adding %s=%s to destination", $attr_name, $dst_node->getAttribute($attr_name);
                    $struct->{added}{node} = "$dst_node (updated)";
                }
            }
            push @dnodes, $struct;
        }
        push @$dbg, {
            '1.node_text        ' => "$src_node",
            '2.key              ' => $key,
            '3.id_attr          ' => $id_attr,
            '4.id_val           ' => $id_val,
            '5.match_xpath      ' => $match_xpath,
            '6.dnodes           ' => \@dnodes,
        };
    }
    push @$dbg, {final_destination => $dst->toString };
    return $dbg;
}

1;
__END__
__TODO__
I think what I want to do next for the src_node loop is if no
matching destination nodes were found, then I need to add one...
but I'm not sure where to add it; maybe as a sibling to the last-found
destination node or something; or maybe I'll have to find the parent
of the current source node, and then find a matching parent node
in the destination, and add a child to the matchingParent
