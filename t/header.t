#!perl
use strict;
use warnings;
use utf8;

use Text::Amuse::Compile;
use Text::Amuse::Compile::Utils qw/write_file read_file/;
use File::Temp;
use File::Spec::Functions qw/catdir catfile/;
use Test::More tests => 9;

my $workingdir = File::Temp->newdir(CLEANUP => !$ENV{NOCLEANUP});
my $testfile = catfile($workingdir->dirname, "test.muse");
my $c = Text::Amuse::Compile->new;

{
    my $muse = <<MUSE;
#title blah
#deleted 1

deleted
MUSE
    write_file($testfile, $muse);
    my $header = $c->parse_muse_header($testfile);
    ok $header->is_deleted, "File is deleted";
    is $header->language, "en", "Language is en";
    ok !$header->wants_slides, "No slides";
}

{
    my $muse = <<MUSE;
#title blah
#deleted
#lang it
#slides NO

deleted
MUSE
    write_file($testfile, $muse);
    my $header = $c->parse_muse_header($testfile);
    ok !$header->is_deleted, "File is not deleted";
    is $header->language, "it", "Language is it";
    ok !$header->wants_slides, "File doesn't want slides";
}

{
    my $muse = <<MUSE;
#title blah
#deleted
#lang it
#slides yes

deleted
MUSE
    write_file($testfile, $muse);
    my $header = $c->parse_muse_header($testfile);
    ok !$header->is_deleted, "File is not deleted";
    is $header->language, "it", "Language is it";
    ok $header->wants_slides, "File wants slides";
}
