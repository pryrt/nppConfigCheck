#!perl -l

use 5.012;  # strict, say
use warnings;

our $VERSION = '0.007';  # rrr.mmmsss : rrr is major revision; mmm is minor revision; sss is sub-revision (new feature path or bugfix); optionally use _sss instead, for alpha sub-releases


print "Hello World";

=pod

=encoding utf8

=head1 NAME

nppConfigCheck - Utility to compare Notepad++ config files to the default config files

=head1 USAGE

    nppConfigCheck.exe [--path <pathToNotepadPlusPlus>] [--version <versionToCompareTo>] [--config appdata|<pathToNotepadPlusPlusConfigs>]

        --path <pathToNotepadPlusPlus>  Chooses the path for the notepad++ executable.
                                        If not provided, defaults to checking `c:\Program Files\Notepad++` then `c:\Program Files (x86)\Notepad++`.

        --version <versionToCompareTo>  Chooses a version of Notepad++ to compare against.
                                        If not provided, defaults to the most recently-released version of Notepad++.

        --config appdata                        Checks the %AppData%\Notepad++ folder.
        --config <pathToNotepadPlusPlusConfig   Checks a specific path for config files.
                                                This is useful for when you have Notepad++ configured to use a Cloud path,
                                                or using the -settingsDir command-line option.
                                                If not provided, will use a heuristic to guess the correct location.

=head2 EXAMPLES

Compare the standard Notepad++ installation location to the most recently-released version of Notepad++:

    nppConfigCheck.exe

Compare the standard Notepad++ installation location to a specific version's config files:

    nppConfigCheck.exe --version v7.9.5

Compare a portable Notepad++ installation location to the most recently-released version of Notepad++:

    nppConfigCheck --path "c:\usr\local\apps\npp\npp.7.9.5.portable.x64"

Compare a portable Notepad++ installation location to a specific version of Notepad++:

    nppConfigCheck --path "c:\usr\local\apps\npp\npp.7.9.5.portable.x64" --version v7.9.5

Compare the standard Notepad++ installation location using `%AppData%` config files:

    nppConfigCheck --config appdata

Compare the standard Notepad++ installation location using Dropbox as the Cloud prodivder:

    nppConfigCheck --config d:\users\username\Dropbox\Notepad++


=head1 DESCRIPTION

This can be used to compare your copy of Notepad++'s config files to a specific revision of Notepad++.

=head1 AUTHOR

Peter C. Jones C<E<lt>petercj AT cpan DOT orgE<gt>>

Please report any bugs or feature requests
thru the repository's interface at L<https://github.com/pryrt/nppConfigCheck/issues>.

=begin html

<!--
<a href="https://metacpan.org/pod/Win32::Mechanize::NotepadPlusPlus"><img src="https://img.shields.io/cpan/v/Win32-Mechanize-NotepadPlusPlus.svg?colorB=00CC00" alt="" title="metacpan"></a>
<a href="http://matrix.cpantesters.org/?dist=Win32-Mechanize-NotepadPlusPlus"><img src="http://cpants.cpanauthors.org/dist/Win32-Mechanize-NotepadPlusPlus.png" alt="" title="cpan testers"></a>
<a href="https://github.com/pryrt/Win32-Mechanize-NotepadPlusPlus/releases"><img src="https://img.shields.io/github/release/pryrt/Win32-Mechanize-NotepadPlusPlus.svg" alt="" title="github release"></a>
<a href="https://github.com/pryrt/Win32-Mechanize-NotepadPlusPlus/issues"><img src="https://img.shields.io/github/issues/pryrt/Win32-Mechanize-NotepadPlusPlus.svg" alt="" title="issues"></a>
<a href="https://ci.appveyor.com/project/pryrt/win32-mechanize-notepadplusplus"><img src="https://ci.appveyor.com/api/projects/status/6gv0lnwj1t6yaykp/branch/master?svg=true" alt="" title="test coverage"></a>
-->

=end html

=head1 COPYRIGHT

Copyright (C) 2021 Peter C. Jones

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.
See [http://dev.perl.org/licenses/](http://dev.perl.org/licenses/) for more information.
