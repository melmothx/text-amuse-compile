#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 16;
use File::Spec;
use Text::Amuse::Compile;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use File::Temp;
use Text::Amuse::Compile::Utils qw/read_file write_file/;

my $c = Text::Amuse::Compile->new(epub => 1);

my $target_base = File::Spec->catfile(qw/t testfile for-epub/);

$c->compile($target_base . '.muse');

my $epub = $target_base . '.epub';

die "No epub produced, cannot continue!" unless -f $epub;

# let's inspect the damned thing

my $zip = Archive::Zip->new;
die "Couldn't read $epub" if $zip->read($epub) != AZ_OK;

my $tmpdir = File::Temp->newdir(CLEANUP => 1);

diag "Using " .$tmpdir->dirname;

$zip->extractTree('OPS', $tmpdir->dirname);

foreach my $file (qw/piece1.xhtml
                     piece2.xhtml
                     piece3.xhtml
                     titlepage.xhtml/) {
    my $page = read_file(File::Spec->catfile($tmpdir->dirname,
                                             $file));
    like $page, qr{<title>.*\&amp\;.*\&amp\;.*</title>}, "Title escaped on $file";
    like $page, qr{\&amp\;.*\&amp\;}, "& escaped on $file";
    unlike $page, qr{\& }, "no lonely & on $file";
    if ($page =~ m{<title>(.*)</title>}) {
        my $title = $1;
        unlike $title, qr{[<>"']}, "Title: $title escaped";
    }
    else {
        die "No title on $file";
    }
}
