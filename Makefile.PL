use 5.010001;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Text::Amuse::Compile',
    AUTHOR           => q{Marco Pessotto <melmothx@gmail.com>},
    VERSION_FROM     => 'lib/Text/Amuse/Compile.pm',
    ABSTRACT_FROM    => 'lib/Text/Amuse/Compile.pm',
    LICENSE          => 'Perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010001,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'File::Temp' => 0,
    },
    PREREQ_PM => {
        # ours
        'Text::Amuse' => 0.60,
        'PDF::Imposition' => 0.14,
        'EBook::EPUB::Lite' => 0.71,
        # needed
        'Moo' => 1,
        'Type::Tiny' => 1,
        'Template::Tiny' => 1.12, # version in wheezy
        'IO::Pipe' => 0,
        'Archive::Zip' => 0, # alread a requirement of EBook::EPUB
    },
    EXE_FILES => [ 'bin/muse-compile.pl' ],
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Text-Amuse-Compile-*' },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/melmothx/text-amuse-compile',
            homepage => 'http://amusewiki.org',
            x_IRC => 'irc://chat.freenode.net/#amusewiki',
            x_WebIRC => 'https://webchat.freenode.net/?channels=#amusewiki',
           },
    },

);

# Local Variables:
# cperl-indent-parens-as-block: t
# End:
