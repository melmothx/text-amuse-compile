#!perl

use strict;
use warnings;
use utf8;

use Test::More tests => 90;
use Text::Amuse::Compile;
use Text::Amuse::Compile::TemplateOptions;
use Text::Amuse::Compile::Utils qw/read_file write_file/;
use File::Temp;
use File::Spec;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ':encoding(utf-8)';
binmode STDERR, ':encoding(utf-8)';

my $tmpdir = File::Temp->newdir(CLEANUP => !$ENV{NOCLEANUP});

diag "Working on $tmpdir";

my $random = "this is some text\n\n" x 3;

my $muse =<< "MUSE";
#title My title
#subtitle My subtitle
#author My author

$random

** This is a chapter

$random

*** this is a section

$random

**** this is a subsection

$random

** This is a chapter (2)

$random

*** this is a section (2)

$random

**** this is a subsection (2)

$random


MUSE

foreach my $spec (Text::Amuse::Compile::TemplateOptions->all_headings) {
    foreach my $twoside (0, 1) {
        my $c = Text::Amuse::Compile->new(tex => 1,
                                          pdf => !!$ENV{TEST_WITH_LATEX},
                                          extra => {
                                                    headings => $spec->{name},
                                                    papersize => 'b6',
                                                    twoside => $twoside,
                                                   });
        diag "Testing $spec->{desc} headings";

        my $basename = "test" . $spec->{name};
        $basename =~ s/_/-/g;
        if ($twoside) {
            $basename .= '-2side';
        }
        my $target = File::Spec->catfile($tmpdir, $basename . '.muse');
        my $tex = File::Spec->catfile($tmpdir, $basename . '.tex');
        my $pdf = File::Spec->catfile($tmpdir, $basename . '.pdf');
        write_file($target, $muse);
        $c->compile($target);
        ok (-f $tex, "$tex found");

        my $texbody = read_file($tex);
        if (!$spec->{name}) {
            like($texbody, qr{headinclude\=false\,\%}, "headinclude is false");
            like($texbody, qr!\\pagestyle\{plain\}!, "plain pagestyle");
            unlike($texbody, qr!\\pagestyle\{scrheadings\}!, "not custom pagestyle");
        } else {
            like($texbody, qr{headinclude\=true\,\%}, "headinclude is true");
            unlike($texbody, qr!\\pagestyle\{plain\}!, "not a plain pagestyle");
            like($texbody, qr!\\pagestyle\{scrheadings\}!, "custom pagestyle");
        }

      SKIP: {
            skip "pdf $pdf not required", 1 unless $ENV{TEST_WITH_LATEX};
            ok(-f $pdf, "$pdf created");
        }
    }
}
