#!perl
use strict;
use warnings;
use utf8;
use Test::More;
use Text::Amuse::Compile;

my $extra = {
             site => "Test site",
             fonts => "LModern",
            };

my $compile = Text::Amuse::Compile->new(
                                        extra => $extra,
                                       );

is_deeply({ $compile->extra }, $extra, "extra options stored" );

my $returned = { $compile->extra };

diag "Added key to passed ref";
$extra->{ciao} = 1;

is_deeply({ $compile->extra }, $returned );

done_testing;
