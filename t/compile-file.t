#!perl
use strict;
use warnings;
use utf8;
use Test::More;

use File::Spec;
use Data::Dumper;
use File::Slurp;

use Text::Amuse::Compile::File;
use Text::Amuse::Compile::Templates;


my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ':encoding(utf-8)';
binmode STDERR, ':encoding(utf-8)';

my $targetdir = File::Spec->catfile('t', 'testfile');
chdir $targetdir or die $!;

my $tt = Text::Amuse::Compile::Templates->new;
my $file = Text::Amuse::Compile::File->new(name => 'test',
                                             suffix => '.muse',
                                             templates => $tt);


is($file->name, 'test');
is($file->suffix, '.muse');
ok($file->templates->html);
ok(!$file->is_deleted);
is($file->complete_file, 'test.ok');
is($file->lockfile, 'test.lock');
like $file->document->as_latex, qr/\\& Ćao! \\emph{another}/;
like $file->document->as_html, qr{<em>test</em> &amp; Ćao! <em>another</em>};

diag "Compile the html";
$file->html;
ok ((-f 'test.html'), "html found");

my $html_body = read_file ('test.html', { binmode => ':encoding(utf-8)' });
like $html_body, qr{<em>test</em> &amp; Ćao! <em>another</em>};
# print $html_body;

$file->tex;
ok ((-f 'test.tex'), "tex found");

$file->bare_html;
ok ((-f 'test.bare.html'), 'bare html found');


$file->mark_as_open;
foreach my $ext ($file->purged_extensions) {
    ok(! -f "test$ext", "test$ext purged");
}
ok(! -f 'test.html');

ok($file->tt);



done_testing;
