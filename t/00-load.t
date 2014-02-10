#!perl -T
use 5.010001;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Text::Amuse::Compile' ) || print "Bail out!\n";
}

diag( "Testing Text::Amuse::Compile $Text::Amuse::Compile::VERSION, Perl $], $^X" );
