# NAME

nppConfigCheck - Utility to compare Notepad++ config files to the default config files

# USAGE

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

## EXAMPLES

Compare the standard Notepad++ installation location to the most recently-released version of Notepad++:

    nppConfigCheck.exe

Compare the standard Notepad++ installation location to a specific version's config files:

    nppConfigCheck.exe --version v7.9.5

Compare a portable Notepad++ installation location to the most recently-released version of Notepad++:

    nppConfigCheck --path "c:\usr\local\apps\npp\npp.7.9.5.portable.x64"

Compare a portable Notepad++ installation location to a specific version of Notepad++:

    nppConfigCheck --path "c:\usr\local\apps\npp\npp.7.9.5.portable.x64" --version v7.9.5

Compare the standard Notepad++ installation location using \`%AppData%\` config files:

    nppConfigCheck --config appdata

Compare the standard Notepad++ installation location using Dropbox as the Cloud prodivder:

    nppConfigCheck --config d:\users\username\Dropbox\Notepad++

# DESCRIPTION

This can be used to compare your copy of Notepad++'s config files to a specific revision of Notepad++.

# AUTHOR

Peter C. Jones `<petercj AT cpan DOT org>`

Please report any bugs or feature requests
thru the repository's interface at [https://github.com/pryrt/nppConfigCheck/issues](https://github.com/pryrt/nppConfigCheck/issues).

<div>
    <a href="https://github.com/pryrt/nppConfigCheck/releases"><img src="https://img.shields.io/github/release/pryrt/nppConfigCheck.svg" alt="" title="github release"></a>
</div>

# COPYRIGHT

Copyright (C) 2021 Peter C. Jones

# LICENSE

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.
See \[http://dev.perl.org/licenses/\](http://dev.perl.org/licenses/) for more information.
