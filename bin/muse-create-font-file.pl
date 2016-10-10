#!/usr/bin/env perl

use strict;
use warnings;
use Text::Amuse::Compile::Fonts::Import;
my $file = shift;
Text::Amuse::Compile::Fonts::Import->new(output => $file)->import_and_save;
