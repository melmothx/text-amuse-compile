#!perl

use strict;
use warnings;
use Text::Amuse::Compile;
use File::Spec;
use File::Slurp qw/write_file append_file read_file/;
use Test::More;

my $xelatex = system(xelatex => '--version');
if ($xelatex == 0) {
    plan tests => 14;
}
else {
    plan skip_all => "No xelatex installed, skipping tests\n";
    exit;
}


my $c = Text::Amuse::Compile->new(
                                  pdf => 1,
                                  report_failure_sub => sub { die join(" ", @_) },
                                 );

my $target = File::Spec->catfile('t', 'testfile', 'broken.muse');
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
ok(!$c->errors);
ok(-f $pdf);
ok(-f $tex);

diag "Overwriting .tex with garbage";

write_file($tex, "\\laskdflasdf\\bye");

eval {
    $c->compile($target);
};

ok($@, "Now the compiler dies");
ok($c->errors);


$c->report_failure_sub(sub {
                           diag "Calling report failure with diag: "
                             . scalar (@_) . " lines";
                           });

unlink $pdf if -f $pdf;

$c->compile($target);
ok($c->errors);

ok((! -f $pdf), "Now we're still alive");

my $log = $target;
$log =~ s/muse$/test/;

if (-f $log) {
    unlink $log or die $!;
}

$c->report_failure_sub(sub {
                           my @errors = @_;
                           my $string = join("\n", @errors);
                           append_file($log, "$$ report failure\n:$string\n");
                       });

$c->compile($target, "t/lasdf/asd.muse", "t/alkasdf/alsf.text");
ok($c->errors);

ok((-f $log), "Found $log");

my @lines = read_file($log);

my @error = grep { /\Q$target\E/ } @lines;
ok(@error >= 1);

@error = grep { /Undefined control sequence/ } @lines;
ok(@error >= 1);

@error = grep { /Cannot chdir into/ } @lines;
ok(@error = 2);

unlink $tex or die $!;

ok($c->errors);
$c->compile($target);
ok(!$c->errors);

