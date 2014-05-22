#!perl

use strict;
use warnings;
use Test::More tests => 2;
use Text::Amuse::Compile;


my $counter = 0;
my $logger = sub {
    $counter++;
};

my @errors;

my $c = Text::Amuse::Compile->new(logger => $logger,
                                  report_failure_sub => sub {
                                      push @errors, $_[0];
                                  });

$c->compile('laksdfljalsdkfj.muse');

is_deeply(\@errors, ['laksdfljalsdkfj.muse']);

ok $counter;






