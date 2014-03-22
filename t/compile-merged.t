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

my $testnum = 16;

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
             files => [qw/first forth second third/],
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


like $outtex, qr/\\selectlanguage\{russian\}/, "Found language selection";
like $outtex, qr/\\selectlanguage\{english\}/, "Found language selection";
like $outtex, qr/\\setmainlanguage\{french\}/, "Found language selection";
like $outtex, qr/\\setotherlanguages\{.*russian.*\}/;
like $outtex, qr/\\setotherlanguages\{.*english.*\}/;
like $outtex, qr/\\russianfont/;

if ($xelatex) {
    ok(-f "$base.pdf");
}

my @chunks = grep { /language/ } split(/\n/, $outtex);

is_deeply \@chunks, [
                     '\setmainlanguage{french}',
                     '\setotherlanguages{russian,english}',
                     '\selectlanguage{russian}',
                     '\selectlanguage{english}',
                     '\selectlanguage{russian}',
                    ];

foreach my $ext (qw/aux log pdf tex toc/) {
    my $remove = "$base.$ext";
    if (-f $remove) {
        unlink $remove or warn $!;
    }
}
