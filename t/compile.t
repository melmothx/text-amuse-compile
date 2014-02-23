#!perl
use strict;
use warnings;
use utf8;
use Test::More tests => 16;

use Text::Amuse::Compile;

my $compile;

eval {
    $compile = Text::Amuse::Compile->new(
                                         file => 1,
                                         pdf  => 1,
                                        );
};
ok($@);

$compile = Text::Amuse::Compile->new(pdf  => 1);

ok($compile->pdf);
foreach my $m (qw/a4_pdf lt_pdf epub html bare_html tex/) {
    ok(!$compile->$m, "$m is false");
}

ok(!$compile->epub);

$compile = Text::Amuse::Compile->new;

foreach my $m (qw/pdf a4_pdf lt_pdf epub html bare_html tex/) {
    ok ($compile->$m, "$m is true");
}

$compile->compile("hello.muse", "t/sadf/aklsdf/bau.muse", "asdf/aldkf/blabla.muse");

