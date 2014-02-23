#!perl

use strict;
use warnings;
use Text::Amuse::Compile;
use File::Spec;
use File::Slurp;
use Test::More;
use Try::Tiny;

my $c = Text::Amuse::Compile->new(
                                  pdf => 1,
                                  report_failure_sub => sub { die join(" ", @_) },
                                 );

my $target = File::Spec->catfile('t', 'testfile', 'broken.muse');
write_file($target, "#title test\n\n blabla\n");
my $pdf = $target;
my $tex = $target;
$pdf =~ s/muse$/pdf/;
$tex =~ s/muse$/tex/;

if (-f $pdf) {
    unlink $pdf or die $!;
}
if (-f $tex) {
    unlink $tex or die $!;
}

$c->compile($target);
ok(-f $pdf);
ok(-f $tex);

diag "Overwriting .tex with garbage";

write_file($tex, "\\laskdflasdf\\bye");

eval {
    $c->compile($target);
};

ok($@, "Now the compiler dies");


$c->report_failure_sub(sub {
                           diag "$$ calling report failure with diag: "
                             . scalar (@_) . " lines";
                           });

unlink $pdf if -f $pdf;

$c->compile($target);

ok((! -f $pdf), "Now we're still alive");

my $log = $target;
$log =~ s/muse$/test/;

if (-f $log) {
    unlink $log or die $!;
}

$c->report_failure_sub(sub { write_file($log, "$$ calling report failure") });

$c->compile($target);

ok(-f $log);

done_testing;

