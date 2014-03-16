use strict;
use warnings;

use Test::More;
use Text::Amuse::Compile;
use File::Spec;
use File::Slurp;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ':encoding(utf-8)';
binmode STDERR, ':encoding(utf-8)';

my $testnum = 9;

my $xelatex = $ENV{TEST_WITH_LATEX};
if ($xelatex) {
    plan tests => $testnum;
    diag "Testing with XeLaTeX";
}
else {
    diag "No TEST_WITH_LATEX environment variable found, avoiding use of xelatex";
    plan tests => ($testnum - 1);
}


my $c = Text::Amuse::Compile->new(tex => 1,
                                  pdf => $xelatex,
                                  extra => {
                                            mainfont => 'Charis SIL',
                                            papersize => 'a5',
                                           });

$c->compile({
             path  => File::Spec->catdir(qw/t merged-dir/),
             files => [qw/first second/],
             name  => 'my-new-test',
             title => 'My new shiny test',
             subtitle => 'Another one',
             date => 'Today!',
             source => 'Text::Amuse::Compile',
            });

my $base = File::Spec->catfile(qw/t merged-dir my-new-test/);
ok(-f "$base.tex" );

my $outtex = read_file("$base.tex", { binmode => ':encoding(utf-8)' });

like $outtex, qr/First \\emph\{file\} text/, "Found the first file body";
like $outtex, qr/Second file \\emph\{text\}/, "Found the second file body";
like $outtex, qr/Pallino Pinco/, "Found the first author";
like $outtex, qr/First file subtitle/, "Found the first text subtitle";
like $outtex, qr/Pallone Ponchi/, "Found the second file author";
like $outtex, qr/\{Second file subtitle\}/, "Found the title of the second file";

like $outtex, qr/\\title\{My new shiny test}/, "Doc title found";

if ($ENV{TEST_WITH_LATEX}) {
    ok(-f "$base.pdf");
}

foreach my $ext (qw/aux log pdf tex toc/) {
    unlink "$base.$ext" or warn $!;
}
