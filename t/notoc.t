#!perl

use strict;
use warnings;
use Test::More tests => 28;
use File::Temp;
use File::Spec::Functions qw/catfile catdir/;
use Text::Amuse::Compile;
use Text::Amuse::Compile::Utils qw/write_file read_file/;

my $tmpdir = File::Temp->newdir(CLEANUP => 1);

my $target = catfile($tmpdir, 'default.muse');
my $tex = catfile($tmpdir, 'default.tex');
my $pdf = catfile($tmpdir, 'default.pdf');
my $html = catfile($tmpdir, 'default.html');
my $bare_html = catfile($tmpdir, 'default.bare.html');
my $muse =<<'MUSE';
#title Test

** Hello

** There

** Blah

Hello there
MUSE

foreach my $header (0..1) {
    foreach my $option (0..1) {
        my $c = Text::Amuse::Compile->new(tex => 1,
                                          html => 1,
                                          bare_html => 1,
                                          pdf => !!$ENV{TEST_WITH_LATEX},
                                          ($option ? (extra => { notoc => 1 }) : ()));
        
        my $musebody = $header ? "#notoc 1\n" . $muse : $muse;
        write_file($target, $musebody);
        $c->compile($target);
        ok(-f $tex, "$tex file is present");
        my $texbody = read_file($tex);
        my $htmlbody = read_file($html);
        my $barebody = read_file($bare_html);
        my $re_no_display = qr/<div class="table-of-contents" style="display:none"( dir="...")?>/;
        my $re_display    = qr/<div class="table-of-contents"( dir="...")?>/;
        if ($header || $option) {
            unlike($texbody, qr/\\tableofcontents/, "ToC is not present header: $header option: $option");
            like($htmlbody, $re_no_display);
            like($barebody, $re_no_display);
            unlike($htmlbody, $re_display);
            unlike($barebody, $re_display);

        }
        else {
            like($texbody, qr/\\tableofcontents/, "ToC is present header: $header option: $option");
            unlike($htmlbody, $re_no_display);
            unlike($barebody, $re_no_display);
            like($htmlbody, $re_display);
            like($barebody, $re_display);
        }
      SKIP:
        {
            skip "pdf $pdf not required", 1 unless $ENV{TEST_WITH_LATEX};
            ok(-f $pdf, "$pdf created");
        }
    }
}
