#!perl

package NppCfgChk::Archive;

use 5.012; # strict, //
use warnings;
use warnings::register;
use Carp;

use Archive::Zip;

=pod

=encoding utf8

=head1 NAME

NppCfgChk - The guts of the nppConfigCheck application

=head1 SYNOPSIS

    my $archive = NppCfgChk::Archive->fromPath($path);
    my $contents = $archive->contents($filename);

=head1 DESCRIPTION

This will allow a consistent interface to grabbing the contents
from either a file inside a zip archive, or a file inside a
portable or installed folder.

=head2 Constructor

=over

=item fromPath

    my $archive = NppCfgChk::Archive->fromPath($path);
    my $withCfg = NppCfgChk::Archive->fromPath($path,$configPath);
    my $withCfg = NppCfgChk::Archive->fromPath($path,$configPath,$isSource);

Pass C<fromPath()> either a $path to a zipfile or a directory. It will then return an object which will give a consistent interface for accessing, and will set up some mappings so that it can find all the files, even for installations where some config files are in the cloud folder and some are in the main installation folder (or installations that are missing some appdata files, so it falls back to using the installation-directory files).

You can optionally specify a C<$configPath>, which will be used to implement L<nppConfigCheck.pl>'s C<--config ...> command-line option, to look for the config files in a specific location.  (So in this case, the first C<$path> is the directory that contains the C<notepad++.exe> and fallback settings files; the C<$configPath> contains the active config files.)

If C<$isSource> is true, or if a zipfile is specified as the path, the archive is expected to be a fully-popluated archive suitable for being the "source" archive for the merge.

=cut

sub fromPath
{
    my ($class, $path, $configPath, $isSource) = @_;
    my $self = bless {
        mainPath => $path ,
        configPath => $configPath,

        # per-config-file defaults
        'config.xml' => {
            elements => {
                'FindHistory' => undef,
                'History' => undef,
                'ProjectPanels' => undef,
                'ProjectPanels/ProjectPanel' => 'id',
                'GUIConfigs' => undef,
                'GUIConfigs/GUIConfig' => 'name',
            },
        },
        'langs.xml' => {
            elements => {
                'Languages' => undef,
                'Language' => 'name',
                'Keywords' => 'name'
            },
        },
        'stylers.xml' => {
            elements => {
                'LexerStyles' => undef,
                'LexerType' => 'name',
                'WordsStyle' => 'name',
                'GlobalStyles' => undef,
                'WidgetStyle' => 'name',
            },
        },
        'shortcuts.xml' => {
            elements => {
                'InternalCommands' => undef,
                'InternalCommands/Shortcut' => undef,
                'Macros' => undef,
                'Macros/Macro' => 'name',
                'Macro/Action' => 'name',
                'UserDefinedCommands' => undef,
                'PluginCommands' => undef,
                'ScintillaKeys' => undef,
            }
        },
        'contextMenu.xml' => {
            elements => {
                'ScintillaContextMenu' => undef,
                'ScintillaContextMenu/Item' => 'id',    #     SctintillaContextMenu > Item{id|MenuItemName|PluginCommandItemName}
            }
        },

        # TODO: continue populating, but this is enough for development purposes
    }, $class;

    if($path =~ m/\.zip$/i) {

        $isSource = 1;      # zipfiles are always considered a source archive
        $self->{isZip} = 1;
        $self->{zipObj} = Archive::Zip->new($path);

        # map filenames to zipfile location, using .model variant because zipfile is source
        $self->{'langs.xml'}{location} = 'langs.model.xml';
        $self->{'stylers.xml'}{location} = 'stylers.model.xml';
        for my $cfile ( qw/config.xml shortcuts.xml contextMenu.xml/ ) {
            $self->{$cfile}{location} = $cfile;
        }

    } else {

        $self->{isZip} = 0;
        $self->{zipObj} = undef;

        # map filenames to location
        for my $cfile (qw/langs.xml stylers.xml config.xml shortcuts.xml contextMenu.xml/) {
            $self->{$cfile}{location} = (defined($configPath) && -d $configPath) ? "$configPath/$cfile" : "$path/$cfile";
            $self->{$cfile}{location} =~ s{//}{/};  # remove double-slash in case configPath or path ends in /
        }

        # for source directory, include .model in location
        if($isSource) {
            for my $cfile (qw/langs.xml stylers.xml/) {
                $self->{$cfile}{location} =~ s/\./.model./;
            }
        }

    }

    # check for missing source files and throw error if any missing
    if($isSource) {
        my @missing;
        for my $memberName ( grep /\.xml$/, keys %$self ) {
            push @missing, $memberName unless $self->exists($memberName);
        }
        local $" = ", ";
        croak "archive is missing files: @missing" if @missing;
    }

    return $self;
}

# config.xml
#     FindHistory > attr:*
#     ProjectPanels > ProjectPanel{id}
#     GUIConfigs > GUIConfig{name}
#     GUIConfigs > GUIConfig{DockingManager} > *
# langs(.model).xml
#     Languages > Language{name}
#     Languages > Language > Keywords{name} (value)
# stylers(.model).xml and themes\*.xml
#     LexerStyles > LexerType{name}
#     LexerStyles > LexerType > WordsStyle (optional value)
# shortcuts.xml
#     InternalCommands > Shortcut
#     Macros > Macro{name} > Action{name}
#     UserDefinedCommands > Command{name}
#     PluginCommands > PluginCommand
#     ScintillaKeys > ScintKey > opt:NextKey
# contextMenu.xml
#     SctintillaContextMenu > Item{id|MenuItemName|PluginCommandItemName}
# autoCompletion\*.xml
#     AutoComplete > Environment
#     AutoComplete > Keyword{name}
#     AutoComplete > Keyword{name} > Overload > Param{name}
# localization\*.xml & nativeLang.xml
#     NativeLangue > * > *{m/id|name/i}
# functionList\overrideMap.xml
#     functionList > associationMap > association{LangID|userDefinedLangName}
# functionList\*.xml
#     functionList > parser > *


=back

=head2 Methods

=over

=item contents

    my $contents = $archive->contents($filename);

Slurps the contents of $filename from the archive.

=cut

=item exists

    do {...} if $archive->exists($filename);

Checks if the file is present in the archive.

=cut

sub exists
{
    my ($self, $member) = @_;
    return $self->isZip ?
        # if it's a zip archive, check if it finds a member with the right name
        defined( $self->{zipObj}->memberNamed( $self->{$member}{location} ) ) :
        # if it's not a zip archive, use a normal filesystem check to see if the file exists
        -f $self->{$member}{location};
}

=item isZip

    print $archive->isZip;

Returns a true value if the archive is in the form of a Zip file, or false if not.

=cut

sub isZip
{
    return $_[0]->{isZip};
}

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
