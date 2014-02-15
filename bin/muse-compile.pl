#!/usr/bin/env perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";

use Text::Amuse::Compile;

my $compiler = Text::Amuse::Compile->new;

print $compiler->version;


$compiler->compile(@ARGV);
