#!perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Spec;
use Text::Amuse;
use Text::Amuse::Compile;
use Text::Amuse::Compile::Utils qw/read_file/;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ':encoding(utf-8)';
binmode STDERR, ':encoding(utf-8)';

plan tests => 24;


# this is the test file for the LaTeX output, which is the most
# complicated.

my $file_no_toc = File::Spec->catfile(qw/t tex testing-no-toc.muse/);
my $file_with_toc = File::Spec->catfile(qw/t tex testing.muse/);

test_file($file_no_toc, {
                         division => 9,
                         fontsize => 11,
                         papersize => 'half-lt',
                        },
          qr/scrbook/,
          qr/DIV=9/,
          qr/fontsize=11pt/,
          qr/mainlanguage\{croatian\}/,
          qr/paper=5.5in:8.5in/,
         );



test_file($file_with_toc, {
                           papersize => 'generic',
                          },
          qr/scrbook/,
          qr/mainlanguage\{russian\}/,
          qr/\\renewcaptionname\{russian\}\{\\contentsname\}\{Содржина\}/,
          qr/paper=210mm:11in/,
         );

test_file($file_with_toc, {
                           papersize => 'half-a4',
                          },
          qr/paper=a5/,
         );

test_file({
           path => File::Spec->catfile(qw/t tex/),
           files => [ qw/testing testing-no-toc/],
           name => 'merged-1',
           title => 'Merged',
          },
          {
          },
          qr/croatian/,
          qr/russian/,
          qr/\\setmainlanguage\{russian\}\s*
             \\newfontfamily\s*
             \\russianfont\[Script=Cyrillic\]\{Linux\sLibertine\sO\}\s*
             \\setotherlanguages\{croatian\}\s*
             \\renewcaptionname\{russian\}\{\\contentsname\}\{Содржина\}/sx,
         );

test_file({
           path => File::Spec->catfile(qw/t tex/),
           files => [ qw/testing-no-toc testing/],
           name => 'merged-2',
           title => 'Merged',
          },
          {
          },
          qr/croatian/,
          qr/russian/,
          qr/\\setmainlanguage\{croatian\}\s*
             \\setotherlanguages\{russian\}\s*
             \\newfontfamily\s*
             \\russianfont\[Script=Cyrillic\]\{Linux\sLibertine\sO\}/sx
         );

sub test_file {
    my ($file, $extra, @regexps) = @_;
    my $c = Text::Amuse::Compile->new(tex => 1, extra => $extra);
    $c->compile($file);
    my $out;
    if (ref($file)) {
        $out = File::Spec->catfile($file->{path}, $file->{name} . '.tex');
    }
    else {
        $out = $file;
        $out =~ s/\.muse$/.tex/;
    }
    ok (-f $out, "$out produced");
    my $body = read_file($out);
    print $body;
    my $error = 0;
    foreach my $regexp (@regexps) {
        like($body, $regexp, "$regexp matches the body") or $error++;
    }
    if (ref($file)) {
        my $index = 0;
        foreach my $f (@{$file->{files}}) {
            my $fullpath = File::Spec->catfile($file->{path},
                                               $f . '.muse');
            my $muse = Text::Amuse->new(file => $fullpath);
            my $current = index($body, $muse->as_latex);
            ok($current >= $index) or $error++;;
            $index = $current;
        }
    }
    else {
        my $muse = Text::Amuse->new(file => $file);
        my $latex = $muse->as_latex;
        ok ((index($body, $latex) > 0), "Found the body") or $error++;
    }
    unlink $out unless $error;
    $out =~ s/tex$/status/;
    unlink $out unless $error;
}

