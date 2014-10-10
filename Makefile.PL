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
        'Text::Amuse' => 0.14,
        'PDF::Imposition' => 0.07,
        # needed
        'Template' => 2.24,
        'IO::Pipe' => 0,
        'EBook::EPUB' => 0.6,
        'Archive::Zip' => 0, # alread a requirement of EBook::EPUB
    },
    EXE_FILES => [ 'bin/muse-compile.pl' ],
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Text-Amuse-Compile-*' },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/melmothx/text-amuse-compile',
           },
    },

);

# Local Variables:
# cperl-indent-parens-as-block: t
# End:
