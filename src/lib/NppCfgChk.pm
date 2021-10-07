#!perl
package NppCfgChk;

use 5.012;  # strict, say, state
use warnings;
use warnings::register;
use Exporter 5.57 'import';

use File::Which 'which';
use File::Spec::Functions qw/catpath splitpath catdir splitdir/;
use Carp;
use XML::LibXML '1.70';


=pod

=encoding utf8

=head1 NAME

NppCfgChk - The guts of the nppConfigCheck application

=head1 SYNOPSIS

see L<nppConfigCheck.pl>

=head1 DESCRIPTION

The purpose of this module is to facilitate merging new
Notepad++ GUI settings from a new Notepad++ release into your
existing/installed Notepad++ instance.  When merging, it will
look for specific XML elements, and make sure that the destination
XML has a copy of all the important elements and attributes.

=head1 FUNCTIONS

=over

=cut

our $VERSION = '0.000001'; # master version number; scripts and other modules inherit this value

our @EXPORT_OK = qw/findNppDir mergeContents/;
our %EXPORT_TAGS = (
    all     => [@EXPORT_OK],
);

=item findNppDir

    my $directory = findNppDir();

Returns the path of the directory where the C<notepad++.exe> executable
is found.  This helps the L<CLI|NppCfgChk::CLI> to find the application.

=cut

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

sub _myCanonical
{
    my ($node) = @_;
    my $str = $node->toString(1);
    $str =~ s/(^|\G)(  |\t)/    /gm;
    return $str;
}

=item mergeContents

=item mergeContents($source, $destination, $config)

    my $source = ...;           # contents of source file, as string
    my $destination = ...;      # contents of destination file, as string
    my $config = {Item=>'id'};  # configuring the
    my $updated = mergeContents($source, $dst, );

The C<$source> input is the string contents of the source XML file.
The C<$destination> input is the string contents of the destination XML file.
The function will search through each node from the source, looking for the
node types defined as the keys of C<$config> (described below).  If it finds
such an element, then it will search through the destination looking for a node
that matches the element type (and optionally attribute value).  If it doesn't
find the matching element in the destination, it will try to add it to a
reasonable location in the destination structure; if it finds the element, it
will check to make sure

The C<$config> anonymous hash defines pairs of element names and attribute names:
the element names define which XML elements are searched for in the XML; if
there is an attribute name defined, then matches must also contain that same
attribute value (this allows matching elements based on id or name attributes,
or similar); if the attribute is undefined, then it will look for any matching
element.  The keys of C<%$config> can have one level of depth, so a key of
C<GUIConfig/PluginDlg> will only match a C<PluginDlg> element if it's inside
a C<GUIConfig> element.

=cut

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
    my $dst = XML::LibXML->load_xml(string => $dst_contents, no_blanks=>1);

    #print "src: $_\n" for $src->findnodes('/top/*');
    #print "dst: $_\n" for $dst->findnodes('/top/*');

    my $dbg = [];

    for my $src_node ( $src->findnodes('//*') )
    {
        my $key = $src_node->nodeName();        # gives <elementName ...>
        unless(exists $config->{$key})          # if the element isn't the key of the config hash,
        {                                       # ... then try with 'parent/key', because I allow one level of depth specfication
            my $pname = $src_node->parentNode->nodeName();
            # print STDERR "trying $pname/$key because $key doesn't exist in config\n";
            if(exists $config->{"$pname/$key"}) {
                $key = "$pname/$key";           # update key
            } else {
                next;                               # skip if it's not a configured element
            }
        }
        my $id_attr = $config->{$key};
        my $id_val = !defined($id_attr) ? undef : $src_node->hasAttribute($id_attr) ? $src_node->getAttribute($id_attr) : undef;
        my $match_xpath= defined $id_val ? qq{//$key\[\@$id_attr="$id_val"]} : qq{//$key};          # if available, look for the right type of node with id_attr=id_val, else just look for the right type of node
        #my @dnodes;
        my $dnodes;
        for my $dst_node ( $dst->findnodes($match_xpath) )
        {
            # my $debug_struct = {'dst_node' => _myCanonical($dst_node) };
            for my $attr_obj ( $src_node->attributes )
            {
                my $attr_name = $attr_obj->nodeName();
                next if $attr_name eq $id_attr;
                my $attr_value = $attr_obj->nodeValue();
                # $debug_struct->{looking_for}{$attr_name} = $attr_value;
                if( $dst_node->hasAttribute($attr_name) ) {
                    # $debug_struct->{found}{$attr_name} = sprintf "already has %s=%s", $attr_name, $dst_node->getAttribute($attr_name);
                } else {
                    $dst_node->setAttribute($attr_name, $attr_value);
                    # $debug_struct->{added}{$attr_name} = sprintf "adding %s=%s to destination", $attr_name, $dst_node->getAttribute($attr_name);
                    # $debug_struct->{updated_node} = "$dst_node (updated)";
                }
            }
            # push @dnodes, $debug_struct;
            ++$dnodes;
        }
        if($dnodes) {
            # push @$dbg, {
            #     '1.src_node         ' => _myCanonical($src_node),
            #     '2.src_key          ' => $key,
            #     '3.src_id_attr      ' => $id_attr,
            #     '4.src_id_val       ' => $id_val,
            #     '5.match_xpath      ' => $match_xpath,
            #     '6.dnodes           ' => \@dnodes,
            # };
        } else {
            my $src_parent = $src_node->parentNode();
            my $parent_name = $src_parent->nodeName;
            my $parent_xpath = qq{//$parent_name};
            my $dst_parent = ($dst->findnodes($parent_xpath))[0] // croak "parent not found in destination";
            $dst_parent->appendChild( $src_node->cloneNode(1));
            # push @$dbg, {
            #     '1.src_node         ' => _myCanonical($src_node),
            #     '2.missing          ' => "no dst_node found for src_node",
            #     '3.src_parent_name  ' => $parent_name,
            #     '4.parent_xpath     ' => $parent_xpath,
            #     '5.dst_parent       ' => _myCanonical($dst_parent),
            # };
        }
    }
    return my $out_contents = _myCanonical($dst);
    #push @$dbg, {final_destination => $out_contents };
    #return $dbg;
}

=item compareConfigFiles

=item compareConfigFiles()

Goes through the list of configuration files, grabs the contents
of the source (new version) and destination (installed version)
files, and

=cut

#sub compareConfigFiles
#{
#    my ($srcObj, $dstObj) = @_;
#    my @todo = (
#        ['config.xml' => {
#            'FindHistory' => undef,
#            'ProjectPanel' => 'id',
#            'GUIConfig' => 'name',
#        }],
#        [],
#    );
#    while(my ($xmlfilename, $config) = @{shift @todo} ) {
#        my $srcString = $srcObj->contents($xmlfile);
#        my $dstString = $dstObj->contents($xmlfile);
#        my $outString = mergeContents($srcString, $dstString, $config);
#    }
#}

=back

=head1 AUTHOR

Peter C. Jones C<E<lt>petercj AT cpan DOT orgE<gt>>

Please report any bugs or feature requests
thru the repository's interface at L<https://github.com/pryrt/nppConfigCheck/issues>.

=begin html

<!--a href="https://metacpan.org/pod/Win32::Mechanize::NotepadPlusPlus"><img src="https://img.shields.io/cpan/v/Win32-Mechanize-NotepadPlusPlus.svg?colorB=00CC00" alt="" title="metacpan"></a-->
<!--a href="http://matrix.cpantesters.org/?dist=Win32-Mechanize-NotepadPlusPlus"><img src="http://cpants.cpanauthors.org/dist/Win32-Mechanize-NotepadPlusPlus.png" alt="" title="cpan testers"></a-->
<a href="https://github.com/pryrt/nppConfigCheck/releases"><img src="https://img.shields.io/github/release/pryrt/nppConfigCheck.svg" alt="" title="github release"></a>
<a href="https://github.com/pryrt/nppConfigCheck/issues"><img src="https://img.shields.io/github/issues/pryrt/nppConfigCheck.svg" alt="" title="issues"></a>
<!--a href="https://ci.appveyor.com/project/pryrt/win32-mechanize-notepadplusplus"><img src="https://ci.appveyor.com/api/projects/status/6gv0lnwj1t6yaykp/branch/master?svg=true" alt="" title="test coverage"></a-->

=end html

=head1 COPYRIGHT

Copyright (C) 2021 Peter C. Jones

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;
