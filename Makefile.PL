use ExtUtils::MakeMaker;
use 5.010;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
%mm_args = (
    'NAME'          => 'nppConfigCheck',
    'AUTHOR'        => 'Peter C. jones <petercj AT cpan.org>',
    'VERSION_FROM'  => 'src/nppConfigCheck.pl',
    'ABSTRACT_FROM' => 'src/nppConfigCheck.pl',
    'PREREQ_PM'     => {
        'Exporter'                  => 5.57,    # needed for `use Exporter qw(import);` notation
        'version'                   => 0.77,
        'warnings'                  => 0,
        'strict'                    => 0,
        'constant'                  => 0,
        'Carp'                      => 0,
        'Encode'                    => 0,
        'Archive::Zip'              => 0,
        'Text::Diff'                => 0,
        'File::Spec::Functions'     => 0,
        'Getopt::Long'              => 0,
        'Pod::Usage'                => 0,
        'File::Which'               => 0,
        'FindBin'                   => 0,
        #'IPC::Open2'               => 0,
        #'Win32::GuiTest'           => 1.64,    # version needed for 64-bit ::SendMessage retval
        #'Win32::API'               => 0.71,    # version needed for WINAPI calling convention
        #'Win32::GUI'               => 0,       # for now, needed for notepad()->prompt; need to look for alternative
        #'Win32'                    => 0,
        #'Config'                   => 0,       # needed in Notepad.pm::getFiles for $Config{ptrsize}
    },

    'PL_FILES'      => {
        'src/compile.pl' => {
            'bin/nppConfigCheck.exe' => 'src/nppConfigCheck.pl',
            't/Notepad++/notepad++.exe' => 'src/notepadpp.c'
        },
    },

);

{
    no warnings;
    if( $ExtUtils::MakeMaker::VERSION >= '6.46' ) {
        $mm_args{META_MERGE} = {
            'meta-spec' => {
                version => '2',
                url     => 'http://search.cpan.org/perldoc?CPAN::Meta::Spec',
            },
            resources => {
                bugtracker => {
                    web     => 'https://github.com/pryrt/nppConfigCheck/issues',
                },
                repository => {
                    url     => 'https://github.com/pryrt/nppConfigCheck.git',
                    web     => 'https://github.com/pryrt/nppConfigCheck',
                    type    => 'git',
                },
            },
            keywords => [ 'Notepad++' ],
        };
        # automatically determine the versions for 'provides'; MM->parse_version exists as of MM v6.31, so not a problem with >= 6.46
        #   => this comes out right when printed... but MYMETA.* shows values that look wrong
        my $v = MM->parse_version( $mm_args{VERSION_FROM} );
        $mm_args{META_MERGE}{provides} = {
            'nppConfigCheck' => {
                file => 'src/nppConfigCheck.pm',
                version => $v,
            },
        };
    }
    if( $ExtUtils::MakeMaker::VERSION >= '6.31' ) {
        $mm_args{LICENSE} = 'perl_5';
    }
    if( $ExtUtils::MakeMaker::VERSION >= '6.48' ) {
        $mm_args{MIN_PERL_VERSION} = '5.10.0';
    }
    if( $ExtUtils::MakeMaker::VERSION >= '6.52' ) {
        $mm_args{CONFIGURE_REQUIRES} = {
            'ExtUtils::MakeMaker' => '6.52',
            'warnings' => 0,
            'strict' => 0,
            'Test::More' => 0.86,
            'Test::Exception' => 0,
            'constant' => 0,
            'Config' => 0,
            'Win32' => 0,
            'FindBin' => 1.49, # the version released with perl v5.10
	    'PAR::Packer' => 0, # required for the pp run during the compile phase
        };
    }
    if( $ExtUtils::MakeMaker::VERSION >= '6.55_03' ) {
    	$mm_args{BUILD_REQUIRES} = {
	    'PAR::Packer' => 0, # required for the pp run during the compile phase
	}
    } else {
    	$mm_args{PREREQ_PM}{'PAR::Packer'} = 0; # append it to PREREQ_PM if it's not avaiable in 
    }
    if( $ExtUtils::MakeMaker::VERSION >= '6.64' ) {
        $mm_args{TEST_REQUIRES} = {
            'warnings' => 0,
            'strict' => 0,
            'Test::More' => 0.86,
            'Test::Exception' => 0,
            'constant' => 0,
            'Config' => 0,
            'Path::Tiny' => 0.058,          # 0.018 needed for rootdir and cwd; 0.058 needed for sibling
            #'Win32' => 0,
            #'Win32::API' => 0,
            #'Win32::GuiTest'    => 1.64,    # version needed for 64-bit ::SendMessage retval
            'Encode' => 0,
            'FindBin' => 1.49,              # the version released with perl v5.10
        };
    }
    if( $ExtUtils::MakeMaker::VERSION >= '6.18' ) {
        $mm_args{SIGN} = 1 if MM->can('signature_target') && $ENV{MM_SIGN_DIST};
    }
}

sub MY::postamble {
    my (undef,%h) = @_;
    #require Data::Dumper;
    #print STDERR Data::Dumper->Dump([\%h], [qw(mm_args{postamble})]);
    my $POSTAMBLE =<<'POSTAMBLE';
# TEST_D is used to test for the existence of a directory
TEST_D = $(ABSPERLRUN) -MExtUtils::Command -e test_d --

# run a test coverage report
testcover ::
	$(NOECHO) cover -test -report html

# run author-tests on the original
authtest ::
	$(TEST_D) xt && $(MAKE) test TEST_FILES='xt/*.t'

# run author-tests on the distribution
distauthtest :: disttest
	cd $(DISTVNAME) && $(TEST_D) xt && $(MAKE) test TEST_FILES='xt/*.t'

# addition to realclean: also delete coverage database, if testcover was run
realclean ::
	$(NOECHO) ( $(TEST_D) cover_db && $(RM_RF) cover_db ) || $(ECHO) realclean:: didn't find cover_db
	$(NOECHO) ( $(TEST_F) LICENSE.pod && $(RM_RF) LICENSE.pod ) || $(ECHO) realclean:: didn't find LICENSE.pod intermediary
	$(NOECHO) ( $(TEST_F) README.pod && $(RM_RF) README.pod ) || $(ECHO) realclean:: didn't find README.pod intermediary
	$(NOECHO) ( $(TEST_F) MYMETA.json.lock && $(RM_RF) MYMETA.json.lock ) || $(ECHO) realclean:: didn't find MYMETA.json.lock temp file

# veryclean: runs realclean, then deletes .bak, .old, .orig, and similar

# # auto-populate the VERSION in the submodules from $(VERSION), which comes from main module
# populateversion :: src/nppConfigCheck.pm
# 	$(NOECHO) $(ECHO) want to auto-populate VERSION in all sub-modules: $(VERSION)
# 	$(PERL) -pi -e "s/^(\s*our\s+.VERSION\s*=).*?;.*?$$/\1 '$(VERSION)'; # auto-populated from W::M::NPP/" lib/Win32/Mechanize/NotepadPlusPlus/Notepad.pm lib/Win32/Mechanize/NotepadPlusPlus/Editor.pm

#config :: populateversion
#	$(NOECHO) $(NOOP)

# auto-generate the README from the lib/Win32/Mechanize/NotepadPlusPlus.pm
README.md :: src/nppConfigCheck.pl Makefile.PL
	$(PERL) -MPod::Simple::Select -e 'my $$p = Pod::Simple::Select->new();$$p->output_file(qq(README.pod));$$p->select({head1 => [qq(NAME),qq(USAGE),qq(DESCRIPTION),qq(LIMITATIONS),qq(INSTALLATION),qq(TODO),qq(AUTHOR),qq(COPYRIGHT),qq(LICENSE)]});$$p->parse_file(qq(src/nppConfigCheck.pl));'
	pod2markdown README.pod README.md
	$(RM_F) README.pod

# auto-generate the LICENSE file from the lib/Win32/Mechanize/NotepadPlusPlus.pm
LICENSE :: src/nppConfigCheck.pl Makefile.PL
	$(PERL) -MPod::Simple::Select -e 'my $$p = Pod::Simple::Select->new();$$p->output_file(qq(LICENSE.pod));$$p->select({head1 => [qw/AUTHOR COPYRIGHT LICENSE/]});$$p->parse_file(qq(src/nppConfigCheck.pl));'
	pod2text LICENSE.pod LICENSE
	$(RM_F) LICENSE.pod

docs :: README.md LICENSE manifest

POSTAMBLE

    return $POSTAMBLE;

}

if($ENV{W32MNPP_FORCE_WRONG_OS}) {
    $^O = 'WrongOS';
}

if($^O !~ /MSWin32|cygwin/ and !$ENV{W32MNPP_FORCE_NONWIN_TEST} ) {
    warn sprintf "I don't know whether it will work with Notepad++.exe in OS '%s'\n", $^O;
    warn << "EOW";

########################################
# However, it might work, so I don't want to FAIL on matrix.cpantesters.org.
#   Instead, don't create the Makefile by default, so it will show up as UNKNOWN
#
# If you'd like to try to make it work, please set the environment variable
#   W32MNPP_FORCE_NONWIN_TEST to a true value,
# then re-run perl Makefile.PL, and continue the standard test suite and
# installation procedure from there.
#
# If it works, feel free to create an issue explaining how to make it work:
#   https://github.com/pryrt/Win32-Mechanize-NotepadPlusPlus/issues
########################################

EOW
    exit 0; # exit 0 without Makefile existing will cause UNKNOWN
}


WriteMakefile( %mm_args )
