#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Test::More tests => 5;
use Text::Amuse::Compile::Templates;

my $templates = Text::Amuse::Compile::Templates->new;

foreach my $method (qw/html css bare_html minimal_html latex/) {
    ok($templates->$method);
}


