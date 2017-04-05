#!perl

use strict;
use warnings;
use Test::More tests => 12;
use File::Temp;
use File::Spec::Functions qw/catfile catdir/;
use Text::Amuse::Compile;
use Text::Amuse::Compile::Utils qw/write_file read_file/;

my $tmpdir = File::Temp->newdir;

my $target = catfile($tmpdir, 'default.muse');
my $tex = catfile($tmpdir, 'default.tex');
my $pdf = catfile($tmpdir, 'default.pdf');
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
                                          pdf => !!$ENV{TEST_WITH_LATEX},
                                          ($option ? (extra => { notoc => 1 }) : ()));
        
        my $musebody = $header ? "#notoc 1\n" . $muse : $muse;
        write_file($target, $muse);
        $c->compile($target);
        ok(-f $tex, "$tex file is present");
        my $texbody = read_file($tex);
        if ($header || $option) {
            unlike($texbody, qr/\\tableofcontents/, "ToC is not present");
        }
        else {
            like($texbody, qr/\\tableofcontents/, "ToC is present");
        }
      SKIP:
        {
            skip "pdf $pdf not required", 1 unless $ENV{TEST_WITH_LATEX};
            ok(-f $pdf, "$pdf created");
        }
    }
}
