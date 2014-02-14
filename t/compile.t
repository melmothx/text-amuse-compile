#!perl
use strict;
use warnings;
use utf8;
use Test::More;

use Text::Amuse::Compile;

my $compile;

$compile = Text::Amuse::Compile->new(
                                     file => 1,
                                     pdf  => 1,
                                    );
ok($compile->pdf);
foreach my $m (qw/pdfa4 pdflt epub html bare/) {
    ok(!$compile->$m, "$m is false");
}

ok(!$compile->epub);

$compile = Text::Amuse::Compile->new(
                                     file => 1,
                                    );

foreach my $m (qw/pdf pdfa4 pdflt epub html bare/) {
    ok ($compile->$m, "$m is true");
}

done_testing;
