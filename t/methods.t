#!perl

use strict;
use warnings;
use Test::More tests => 12;
use Text::Amuse::Compile;
use File::Temp;
use File::Spec;
use File::Slurp qw/write_file/;

my $c = Text::Amuse::Compile->new(pdf => 1);

my @avail = $c->available_methods;

is_deeply(\@avail, [
                    qw/bare_html html
                       epub
                       a4_pdf lt_pdf
                       tex zip
                       pdf/
                   ]);

is_deeply([$c->compile_methods], [ qw/pdf/ ]);

$c = Text::Amuse::Compile->new(pdf => 1, epub => 1);

is_deeply([$c->compile_methods], [ qw/epub pdf/ ]);

$c = Text::Amuse::Compile->new(pdf => 1, epub => 1, tex => 1);

is_deeply([$c->compile_methods], [ qw/epub tex  pdf/ ]);


is $c->_suffix_for_method('bare_html'), '.bare.html';
is $c->_suffix_for_method('tex'), '.tex';
is $c->_suffix_for_method('a4_pdf'), '.a4.pdf';

my $wd = File::Temp->newdir;

my $stale = File::Spec->catfile($wd->dirname, "test.html");
sleep 1;
my $testfile = File::Spec->catfile($wd->dirname, "test.muse");
write_file($testfile, ".\n");
sleep 1;
foreach my $ext (qw/tex pdf epub/) {
    write_file(File::Spec->catfile($wd->dirname, "test.$ext"), ".\n");
}

$c = Text::Amuse::Compile->new(pdf => 1, epub => 1, html => 1);

is $c->file_needs_compilation($testfile), 1, "$testfile need compile, html stale";

$c = Text::Amuse::Compile->new(pdf => 1, epub => 1, tex => 1);

is $c->file_needs_compilation($testfile), 0,"$testfile is already compiled";

$c = Text::Amuse::Compile->new(pdf => 1, tex => 1);

is $c->file_needs_compilation($testfile), 0, "$testfile is already compiled";

$c = Text::Amuse::Compile->new(pdf => 1, tex => 1, zip => 1);

is $c->file_needs_compilation($testfile), 1, "$testfile is not fully compiled";

write_file(File::Spec->catfile($wd->dirname, "test.zip"), "blkasdf");

is $c->file_needs_compilation($testfile), 0, "$testfile is ok now";


