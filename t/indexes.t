#!perl
use utf8;
use strict;
use warnings;
use Test::More tests => 1;
use Text::Amuse::Compile;
use Text::Amuse::Compile::File;
use Text::Amuse::Compile::Indexer;
use Text::Amuse::Compile::Devel qw/create_font_object/;
use Data::Dumper;
use Path::Tiny;

{
    my $c = Text::Amuse::Compile->new(tex => 1);
    my $file = path(qw/t testfile index-me/);
    my $cfile = Text::Amuse::Compile::File->new(
                                                name => "$file",
                                                suffix => '.muse',
                                                templates => Text::Amuse::Compile::Templates->new,
                                                logger => sub {
                                                    diag @_;
                                                },
                                                fonts => create_font_object(),
                                               );
    ok $cfile;
    my $doc = $cfile->document;
    diag Dumper($cfile->document_indexes);
    my $indexer = Text::Amuse::Compile::Indexer->new(latex_body => $doc->as_latex,
                                                     index_specs => [ $cfile->document_indexes ]);
    diag $indexer->interpolate_indexes;
}

