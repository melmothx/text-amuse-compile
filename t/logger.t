#!perl

use strict;
use warnings;
use Test::More tests => 1;
use Text::Amuse::Compile;


my $counter = 0;
my $logger = sub {
    $counter++;
};

my $c = Text::Amuse::Compile->new(logger => $logger);

$c->compile('laksdfljalsdkfj.muse');
ok $counter;






