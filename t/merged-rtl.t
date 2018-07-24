#!perl

use utf8;
use strict;
use warnings;
use Text::Amuse::Compile;
use File::Spec::Functions (qw/catdir catfile/);
use Text::Amuse::Compile::Devel qw/explode_epub/;
use Test::More tests => 4;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ':encoding(utf-8)';
binmode STDERR, ':encoding(utf-8)';

{
    my $c = Text::Amuse::Compile->new(
                                      pdf => $ENV{TEST_WITH_LATEX},
                                      tex => 1,
                                      epub => 1,
                                      extra => {
                                                mainfont => 'FreeSerif',
                                                monofont => 'DejaVu Sans Mono',
                                                sansfont => 'DejaVu Sans',
                                               },
                                     );
    $c->compile({
                 path => catdir(qw/t merged-dir-2/),
                 files => [qw/farsi english russian farsi english russian farsi/],
                 name => 'my-test',
                 title => 'Test multilingual',
                });
    my $base = catfile(qw/t merged-dir-2 my-test/);
    my $epub = $base . '.epub';
    my $pdf = $base. '.pdf';
    my $tex = $base .'.tex';
    ok -f $epub, "$epub exists";
    ok -f $tex, "$tex exists";
    my $html = explode_epub($epub);
    like $html, qr{dir="rtl".*dir="ltr".*dir="rtl".*dir="ltr".*dir="rtl"}si, "html switches directions";
    # diag $html;
  SKIP: {
        skip "No pdf required", 1 unless $ENV{TEST_WITH_LATEX};
        ok (-f $pdf, "$pdf exists");
    }

}
