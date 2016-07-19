#!perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use Text::Amuse::Compile;

if ($ENV{TEST_WITH_LATEX}) {
    plan tests => 12;
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
unlink $output or die "Cannot unlink $output $!";

$c = Text::Amuse::Compile->new(tex => 1, pdf => 1, luatex => 1);

$c->compile($file);
ok (-f $output);
unlink $output or die "Cannot unlink $output $!";
like first_line($log), qr{This is LuaTeX};
}

sub first_line {
    my $file = shift;
    open (my $fh, '<', $file) or die $!;
    my $first = <$fh>;
    close $fh;
    return $first;
}
