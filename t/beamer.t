#!perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Spec::Functions qw/catdir catfile/;
use File::Temp;
use Text::Amuse::Compile::File;
use Text::Amuse::Compile::Utils qw/write_file read_file/;
use Text::Amuse::Compile::Templates;
use Text::Amuse::Compile;
use Cwd;

plan tests => ($ENV{TEST_WITH_LATEX} ? 54 : 21);

my $basename = "slides";
my $workingdir = File::Temp->newdir(CLEANUP => !$ENV{NOCLEANUP});
diag "Using " . $workingdir->dirname;

my $muse_body = <<'MUSE';
#title Slides

*** Text::Slides

 - first
 - second

*** Section ignored

; noslide

*** Ignored section

Text ignored

; noslide

This is ignored

*** Secon Text::Slides

 - third
 - fourth
 Term :: Definition

MUSE

my @falses = (undef, '', '0', 'no', 'NO', 'false', 'FALSE');
my @nocompile;
foreach my $false (@falses) {
    my $suffix = $false;
    my $body;
    if (!defined($false)) {
        $suffix = 'undefined';
        $body = $muse_body;
    }
    else {
        $body = "#slides $false\n" . $muse_body;
    }
    if (!length($suffix)) {
        $suffix = 'empty';
    }
    my $name = $basename . '-'. $suffix;
    my $target = catfile($workingdir->dirname, $name . '.muse');
    write_file($target, $body);
    push @nocompile, $name;
}

write_file(catfile($workingdir->dirname, $basename . '.muse'),
           "#slides yes\n" . $muse_body);
my @compile = ($basename);

my $home = getcwd;
chdir $workingdir->dirname or die $!;

my $templates = Text::Amuse::Compile::Templates->new;

foreach my $noc (@nocompile) {
    my $file = Text::Amuse::Compile::File->new(name => $noc,
                                               suffix => '.muse',
                                               templates => $templates,
                                              );
    ok (!$file->sl_tex, "No slides generated for $noc");
    ok (! -f $noc . '.sl.tex', "No tex file for slides for $noc");
    if ($ENV{TEST_WITH_LATEX}) {
        ok(!$file->slides, "No slide pdf generated for $noc");
        ok (! -f $noc . '.sl.pdf', "No pdf file for slides for $noc");
    }
}

foreach my $comp (@compile) {
    my $file = Text::Amuse::Compile::File->new(name => $comp,
                                               suffix => '.muse',
                                               templates => $templates,
                                               logger => sub { diag @_ },
                                              );
    ok ($file->sl_tex, "Slides generated for $comp");
    ok (-f $comp . '.sl.tex', "TeX file for slides for $comp");
    my $texbody = read_file($comp . '.sl.tex');
    unlike ($texbody, qr/Section ignored/, "No ignore part found");
    unlike ($texbody, qr/Ignored section/, "No ignore part found");
    unlike ($texbody, qr/This is ignored/, "No ignore part found");
    unlike ($texbody, qr/Text ignored/, "No ignore part found");
    like ($texbody, qr/begin\{frame\}.+first.+second.+end\{frame\}/s,
         "Found a frame");
    if ($ENV{TEST_WITH_LATEX}) {
        ok($file->slides, "Slides generated for $comp");
        ok (-f $comp . '.sl.pdf', "Pdf file for slides for $comp exists");
        # and check a garbaged file
        write_file('garbage.tex', 'lalksdflkjlakjsdflkjaòlksdjf');
        eval { $file->_compile_pdf('garbage.tex') };
        ok ($@, "failure on garbage");
    }
}

chdir $home or die $!;

my %extra = (
             sansfont => 'Iwona',
             beamertheme => 'Madrid',
             beamercolortheme => 'wolverine',
            );



if ($ENV{TEST_WITH_LATEX}) {
    my $c = Text::Amuse::Compile->new(slides => 1);
    my $muse = catfile(qw/t testfile slides.muse/);
    my $tex = catfile(qw/t testfile slides.sl.tex/);
    my $pdf = catfile(qw/t testfile slides.sl.pdf/);
    $c->compile($muse);
    ok (-f $tex, "TeX $tex generated");
    ok (-f $pdf, "PDF generated");
    my $content = read_file($tex);
    like $content, qr/sansfont\{CMU/, "Sans font as default";
    like $content, qr/colortheme\{dove/, "colortheme is dove";
    like $content, qr/usetheme\{default/, "theme is default";
    unlike $content, qr/ignored/, "Ignored sections are skipped";
    $c = Text::Amuse::Compile->new(slides => 1, extra => \%extra);
    $c->compile($muse);
    ok (-f $tex, "TeX $tex generated");
    ok (!$c->file_needs_compilation($muse), "File $muse doesn't need compilation");
    ok (-f $pdf, "PDF $pdf generated");
    $content = read_file($tex);
    like $content, qr/sansfont\{Iwona/, "Sans font as default";
    like $content, qr/colortheme\{wolverine/, "colortheme is dove";
    like $content, qr/usetheme\{Madrid/, "theme is default";
    $c->purge($muse);
    ok (! -f $pdf, "$pdf purged");
    ok (! -f $tex, "$tex purged");
    ok (-f $muse,  "$muse still here");
    ok ($c->file_needs_compilation($muse), "File $muse needs compilation");
}
