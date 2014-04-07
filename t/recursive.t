#!perl

use strict;
use warnings;
use Test::More tests => 16;
use File::Spec::Functions qw/catfile catdir/;
use Text::Amuse::Compile;
use Cwd;
use File::Spec;
use Data::Dumper;

my $base = getcwd();

my $compiler = Text::Amuse::Compile->new(html => 1);

my @targets = (catfile($base, qw/t recursive-dir a af a-file.muse    /),
               catfile($base, qw/t recursive-dir f ff first-file.muse/),
               catfile($base, qw/t recursive-dir z zf z-file.muse    /));

my @expected = @targets;

my @found = $compiler->find_muse_files(catdir(qw/t recursive-dir/));

is_deeply(\@found, \@expected, "Files are found");
ok (-f catfile($base, qw/t recursive-dir f .hidden prova.muse/),
    "File in hidded directory exists, but it's not listed");

ok (-f catfile($base, qw/t recursive-dir f .hidden.muse/),
    "Hidden file in directory exists, but it's not listed");

ok (-f catfile($base, qw/t recursive-dir f not_reported.muse/),
    "File with underscore in directory exists, but it's not listed");


my $first = shift(@expected);
$compiler->compile($first);

my $status_first = $first;
$status_first =~ s/muse$/status/;

ok (-f $status_first, "Found $status_first");


@found = $compiler->find_new_muse_files(catdir(qw/t recursive-dir/));

is_deeply(\@found, \@expected, "Files are found, and compiled file is skipped");

ok(@found == 2, "Total 2 files");

ok (-f $status_first, "Found $status_first");
my @compiled = $compiler->recursive_compile(catdir($base, qw/t recursive-dir/));

is_deeply (\@compiled, \@found, "Compiled two files")
  or diag Dumper(\@compiled, \@found);

@compiled = $compiler->recursive_compile(catdir($base, qw/t recursive-dir/));

is_deeply [], \@compiled, "Nothing to do";

foreach my $f (@targets) {
    my $basename = $f;
    $basename =~ s/muse$//;
    diag "Processing $basename";
    foreach my $ext (qw/html status/) {
        my $file = $basename . $ext;
        ok (-f $file, "$file found");
        unlink $file or die $!;
    }
}
