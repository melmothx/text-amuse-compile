#!perl
use strict;
use warnings;
use utf8;
use Test::More tests => 25;

use File::Spec;
use Data::Dumper;
use File::Slurp;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ':encoding(utf-8)';
binmode STDERR, ':encoding(utf-8)';

use Text::Amuse::Compile::Merged;

chdir File::Spec->catdir(qw/t merged-dir/) or die $!;

my $doc = Text::Amuse::Compile::Merged->new(files => [qw/first.muse second.muse/],
                                            title => "Title is Bla *bla* bla",
                                            author => "Various",
                                           );

ok($doc);

ok($doc->docs == 2);

is $doc->language, 'french', "Main language is french";
is $doc->language_code, 'fr', "Code ok";
is_deeply $doc->other_languages, [ qw/english/ ];
is_deeply $doc->other_language_codes, [ qw/en/ ];

foreach my $d ($doc->docs) {
    ok($d->isa('Text::Amuse'));
}

is_deeply([ $doc->files ], [qw/first.muse second.muse/]);

is_deeply({ $doc->headers }, {
                          title => "Title is Bla *bla* bla",
                          author => "Various",
                         });

my $tex = $doc->as_latex;

like $tex, qr/First \\emph\{file\} text/, "Found the first file body";
like $tex, qr/Second file \\emph\{text\}/, "Found the second file body";
like $tex, qr/Pallino Pinco/, "Found the first author";
like $tex, qr/First file subtitle/, "Found the first text subtitle";
like $tex, qr/Pallone Ponchi/, "Found the second file author";
like $tex, qr/\{Second file subtitle\}/, "Found the title of the second file";

is_deeply $doc->header_as_latex,
  {
   title => "Title is Bla \\emph{bla} bla",
   author => "Various",
  }, "Header as latex OK";

is_deeply $doc->header_as_html,
  {
   title => "Title is Bla <em>bla</em> bla",
   author => "Various",
  }, "Header as latex OK";



use Text::Amuse::Compile::File;
use Text::Amuse::Compile::Templates;

my $templates = Text::Amuse::Compile::Templates->new;

my $compile = Text::Amuse::Compile::File->new(
                                              document => $doc,
                                              name => 'test',
                                              suffix => '.muse',
                                              templates => $templates,
                                             );

my $outtex = read_file($compile->tex, { binmode => ':encoding(utf-8)' });

like $outtex, qr/First \\emph\{file\} text/, "Found the first file body";
like $outtex, qr/Second file \\emph\{text\}/, "Found the second file body";
like $outtex, qr/Pallino Pinco/, "Found the first author";
like $outtex, qr/First file subtitle/, "Found the first text subtitle";
like $outtex, qr/Pallone Ponchi/, "Found the second file author";
like $outtex, qr/\{Second file subtitle\}/, "Found the title of the second file";

like $outtex, qr/\\title\{Title is Bla \\emph\{bla\} bla\}/, "Doc title found";

# my $outpdf = $compile->pdf;
$compile->purge_all;

