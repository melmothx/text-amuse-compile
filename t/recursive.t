#!perl

use strict;
use warnings;
use Test::More tests => 3;
use File::Spec::Functions qw/catfile catdir/;
use Text::Amuse::Compile;
use Cwd;
use File::Spec;

my $base = getcwd();

my $compiler = Text::Amuse::Compile->new(html => 1);

my @expected = (catfile($base, qw/t recursive-dir a af a-file.muse    /),
                catfile($base, qw/t recursive-dir f ff first-file.muse/),
                catfile($base, qw/t recursive-dir z zf z-file.muse    /));

my @found = $compiler->find_muse_files(catdir(qw/t recursive-dir/));

is_deeply(\@found, \@expected, "Files are found");
ok (-f catfile($base, qw/t recursive-dir f .hidden prova.muse/),
    "File in hidded directory exists, but it's not listed");

ok (-f catfile($base, qw/t recursive-dir f .hidden.muse/),
    "Hidden file in directory exists, but it's not listed");


