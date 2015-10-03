#!perl

use strict;
use warnings;
use Test::More tests => 12;
use Text::Amuse::Compile;
use Data::Dumper;
use File::Temp;
use File::Spec;
use Text::Amuse::Compile::Utils qw/write_file/;

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
sleep 2;
my $testfile = File::Spec->catfile($wd->dirname, "test.muse");
write_file($testfile, ".\n");
sleep 2;
foreach my $ext (qw/tex pdf epub/) {
    write_file(File::Spec->catfile($wd->dirname, "test.$ext"), ".\n");
}

$c = Text::Amuse::Compile->new(pdf => 1, epub => 1, html => 1);

is ( $c->file_needs_compilation($testfile), 1,
     "$testfile need compile, html stale" ) or inspect_wd($wd->dirname);

$c = Text::Amuse::Compile->new(pdf => 1, epub => 1, tex => 1);

is ( $c->file_needs_compilation($testfile), 0,
     "$testfile is already compiled for pdf, epub, tex" )
  or inspect_wd($wd->dirname);;

$c = Text::Amuse::Compile->new(pdf => 1, tex => 1);

is ( $c->file_needs_compilation($testfile), 0,
     "$testfile is already compiled for pdf and tex" ) or inspect_wd($wd->dirname);

$c = Text::Amuse::Compile->new(pdf => 1, tex => 1, zip => 1);

is ( $c->file_needs_compilation($testfile), 1,
     "$testfile is not fully compiled for pdf, tex, zip" )
  or inspect_wd($wd->dirname);

write_file(File::Spec->catfile($wd->dirname, "test.zip"), "blkasdf");

is ( $c->file_needs_compilation($testfile), 0,
     "$testfile is ok now for pdf, tex, zip" ) or inspect_wd($wd->dirname);

sub inspect_wd {
    my $wd = shift;
    die "Missing arg" unless $wd;
    die "$wd is not a dir" unless -d $wd;
    opendir my $dh, $wd or die $!;
    my @files = grep { -f File::Spec->catfile($wd, $_) } readdir $dh;
    closedir $dh;
    my %out;
    foreach my $file (@files) {
        $out{$file} = (stat(File::Spec->catfile($wd, $file)))[9];
    }
    diag Dumper(\%out);
}
