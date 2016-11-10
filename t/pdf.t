#!perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use Text::Amuse::Compile;
use PDF::API2;
use Data::Dumper;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";


if ($ENV{TEST_WITH_LATEX}) {
    plan tests => 40;
}
else {
    plan skip_all => "No TEST_WITH_LATEX set, skipping";
}

foreach my $file (File::Spec->catfile(qw/t manual manual.muse/),
                  File::Spec->catfile(qw/t manual br-in-footnotes.muse/)) {
ok (-f $file, "$file found");

my $output = $file;
my $log = $file;
$output =~ s/muse$/pdf/;
$log =~ s/muse$/log/;
if (-f $output) {
    unlink $output or die "Cannot unlink $output $!";
}
ok (! -f $output);
my $c = Text::Amuse::Compile->new(tex => 1, pdf => 1);
$c->compile($file);
ok (-f $output);
like first_line($log), qr{This is XeTeX};
check_metadata($output);

unlink $output or die "Cannot unlink $output $!";

$c = Text::Amuse::Compile->new(tex => 1, pdf => 1, luatex => 1);

$c->compile($file);
ok (-f $output);
check_metadata($output);

unlink $output or die "Cannot unlink $output $!";
like first_line($log), qr{This is LuaTeX};
}

foreach my $luatex (0..1) {
    my $expected = File::Spec->catfile(qw/t manual merged.pdf/);
    unlink $expected if -f $expected;
    ok (! -f $expected);
    my $c = Text::Amuse::Compile->new(tex => 1, pdf => 1, luatex => $luatex);
    $c->compile({
                 files => [qw/manual br-in-footnotes/],
                 path => File::Spec->catdir(qw/t manual/),
                 name => 'merged',
                 title => "Title is Bla *bla* bla",
                 subtitle => "My [subtitle]",
                 author => 'My {author}',
                 topics => '\-=my= \ **cat**, [another] {cat}',
                });
    ok (-f $expected, "Found expected");
    check_metadata($expected);
}


sub first_line {
    my $file = shift;
    open (my $fh, '<', $file) or die $!;
    my $first = <$fh>;
    close $fh;
    return $first;
}

sub check_metadata {
    my $file = shift;
    my $pdf = PDF::API2->open($file);
    my %info = $pdf->info;
    foreach my $field (qw/Author Title Subject Keywords/) {
        ok $info{$field}, "Found $field metadata" and diag $info{$field};
    }
    $pdf->end;
}

