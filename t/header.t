#!perl
use strict;
use warnings;
use utf8;

use Text::Amuse::Compile;
use Text::Amuse::Compile::Utils qw/write_file read_file/;
use File::Temp;
use File::Spec::Functions qw/catdir catfile/;
use Test::More tests => 32;
use Cwd;

my $cwd = getcwd();
my $workingdir = File::Temp->newdir(CLEANUP => !$ENV{NOCLEANUP});
chdir $workingdir or die "Cannot chdir";
my $testfile = "test.muse";
my $c = Text::Amuse::Compile->new;

{
    my $muse = <<MUSE;
#title blah
#deleted 1
#cover 11 Name.jpg
#coverwidth blablabla
#nocoverpage 0

deleted
MUSE
    write_file($testfile, $muse);
    my $header = $c->parse_muse_header($testfile);
    ok $header->is_deleted, "File is deleted";
    is $header->language, "en", "Language is en";
    ok !$header->wants_slides, "No slides";
    ok !$header->cover, "No cover";
    ok !$header->coverwidth, "No coverwidth";
    ok !$header->nocoverpage, "Nocoverpage is false";
}

{
    my $muse = <<MUSE;
#title blah
#deleted
#lang it
#slides NO
#cover -invalid-name.pdf
#coverwidth 1

deleted
MUSE
    write_file($testfile, $muse);
    my $header = $c->parse_muse_header($testfile);
    ok !$header->is_deleted, "File is not deleted";
    is $header->language, "it", "Language is it";
    ok !$header->wants_slides, "File doesn't want slides";
    ok !$header->cover, "No cover";
    ok !$header->coverwidth, "No coverwidth";
}

{
    my $muse = <<MUSE;
#title blah
#deleted
#lang it
#slides yes
#cover test.pdf

deleted
MUSE
    write_file($testfile, $muse);
    write_file("test.pdf", "x");
    my $header = $c->parse_muse_header($testfile);
    ok !$header->is_deleted, "File is not deleted";
    is $header->language, "it", "Language is it";
    ok $header->wants_slides, "File wants slides";
    is $header->cover, 'test.pdf', "Found the cover";
    is $header->coverwidth, 1, "width is 1";
}

{
    my $muse = <<MUSE;
#title blah
#deleted
#lang it
#slides yes
#cover test.pdf
#coverwidth 0.5

deleted
MUSE
    write_file($testfile, $muse);
    write_file("test.pdf", "x");
    my $header = $c->parse_muse_header($testfile);
    ok !$header->is_deleted, "File is not deleted";
    is $header->language, "it", "Language is it";
    ok $header->wants_slides, "File wants slides";
    is $header->cover, 'test.pdf', "Found the cover";
    is $header->coverwidth, '0.5', "width is 0.5";
}

{
    my $muse = <<MUSE;
#title blah
#deleted
#lang it
#slides yes
#cover test.pdf
#coverwidth 0.77

deleted
MUSE
    write_file($testfile, $muse);
    write_file("test.pdf", "x");
    my $header = $c->parse_muse_header($testfile);
    ok !$header->is_deleted, "File is not deleted";
    is $header->language, "it", "Language is it";
    ok $header->wants_slides, "File wants slides";
    is $header->cover, 'test.pdf', "Found the cover";
    is $header->coverwidth, '0.77', "width is 0.5";
}

{
    my $muse = <<MUSE;
#title blah
#deleted
#lang it
#slides yes
#cover test.pdf
#coverwidth 0.771
#nocoverpage 1

deleted
MUSE
    write_file($testfile, $muse);
    write_file("test.pdf", "x");
    my $header = $c->parse_muse_header($testfile);
    ok !$header->is_deleted, "File is not deleted";
    is $header->language, "it", "Language is it";
    ok $header->wants_slides, "File wants slides";
    is $header->cover, 'test.pdf', "Found the cover";
    is $header->coverwidth, '1', "width is 1";
    is $header->nocoverpage, 1, "nocoverpage ok";
}


chdir $cwd;
