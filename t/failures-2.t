#!/usr/bin/env perl

use utf8;
use strict;
use warnings;
use Text::Amuse::Compile;
use File::Spec;
use Text::Amuse::Compile::Utils qw/append_file read_file/;
use Test::More;
use File::Temp;
use Cwd;

my $xelatex = $ENV{TEST_WITH_LATEX};
if ($xelatex) {
    diag "Using (Xe|Lua)LaTeX for testing";
    plan tests => 4;
}
else {
    plan skip_all => "No TEST_WITH_LATEX env found! skipping tests\n";
    exit;
}

my $wd = File::Temp->newdir;

for my $luatex (0..1) {
    my $logfile = File::Spec->rel2abs(File::Spec->catfile($wd,
                                                          'for-multipar-footnotes.logging.' . $luatex ));
    diag "Logging in $logfile";
    unlink $logfile if -f $logfile;
    my $c = Text::Amuse::Compile->new(
                                      pdf => 1,
                                      luatex => $luatex,
                                      logger => sub { append_file($logfile, @_) },
                                     );
    $c->compile(File::Spec->catfile('t', 'testfile', 'for-multipar-footnotes.muse'));
    my $logs = read_file($logfile);
    like $logs, qr{аргументацией};
    like $logs, qr{It is possible that you have a multiparagraph footnote};
}
