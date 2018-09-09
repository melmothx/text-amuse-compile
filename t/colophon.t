#!perl

use utf8;
use strict;
use warnings;
use Text::Amuse::Compile;
use Text::Amuse::Compile::Devel qw/explode_epub/;
use Path::Tiny;
use Test::More;

my $muse = <<"MUSE";
#title My title
#author My author
#lang it
#pubdate 2018-09-05T13:30:34
#notes Seconda edizione riveduta e corretta: novembre 2018
MUSE

my %values = (
              isbn => '978-19-19333-15-8',
              rights => '© 2018 Pinco Pallino',
              seriesname => 'My series',
              seriesnumber => '69bis',
              publisher => 'My publisher <br> Publisher address <br> city',
             );

foreach my $k (keys %values) {
    $muse .= "#" . "$k $values{$k}\n";
}


my $wd = Path::Tiny->tempdir(CLEANUP => !$ENV{NOCLEANUP});
my $file = $wd->child("text.muse");
$file->spew_utf8($muse);

{
    my $c = Text::Amuse::Compile->new(html => 1, epub => 1, tex => 1, extra => { impressum => 1 });
    $c->compile("$file");
    my %tex = %values;

    my $html = $wd->child("text.html")->slurp_utf8;
    foreach my $str (values %values) {
        $str =~ s/<br>/<br \/>/g;
        like $html, qr{\Q$str\E};
    }

    my $tex = $wd->child("text.tex")->slurp_utf8;
    foreach my $str (values %tex) {
        diag $str;
        $str =~ s/ *<br>/\\forcelinebreak /g;
        like $tex, qr{\Q$str\E};
    }
    my $epub = explode_epub($wd->child("text.epub")->stringify);
    foreach my $str (values %values) {
        $str =~ s/<br>/<br \/>/g;
        like $epub, qr{\Q$str\E};
    }
}

diag $wd;

done_testing;
