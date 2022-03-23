#!perl

use Test::More;
use Text::Amuse;
use Text::Amuse::Compile;
use Data::Dumper;
use Path::Tiny;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ':encoding(utf-8)';
binmode STDERR, ':encoding(utf-8)';

my $testnum = 141;

my $xelatex = $ENV{TEST_WITH_LATEX};

diag "Creating the compiler";

my $c = Text::Amuse::Compile->new(tex => 1,
                                  pdf => $xelatex,
                                  extra => {
                                            mainfont => 'TeX Gyre Pagella',
                                            papersize => 'a5',
                                           });

diag "Try to compile";

my $src = path(qw/t testfile split-volumes.muse/);
$c->compile("$src");

