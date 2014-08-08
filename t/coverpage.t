#!perl

use strict;
use warnings;
use Test::More tests => 5;
use File::Temp;
use File::Spec::Functions qw/catfile catdir/;
use Text::Amuse::Compile;
use Text::Amuse::Compile::Utils qw/write_file read_file/;

my $tmpdir = File::Temp->newdir;

my $target = catfile($tmpdir, 'default.muse');
my $tex = catfile($tmpdir, 'default.tex');
my $muse =<<'MUSE';
#title Test

Hello there
MUSE

my $c = Text::Amuse::Compile->new(tex => 1);

write_file($target, $muse);

$c->compile($target);

ok(-f $tex);

my $texbody = read_file($tex);

like($texbody, qr/\{scrbook\}/);

$c = Text::Amuse::Compile->new(tex => 1, extra => { nocoverpage => 1 });

$c->compile($target);
$texbody = read_file($tex);

like($texbody, qr/\{scrartcl\}/, "Passing nocoverpage as extra changes the class");

$muse =<<'MUSE';
#title Test
#nocoverpage 1

Hello there
MUSE

write_file($target, $muse);
$c = Text::Amuse::Compile->new(tex => 1);
$c->compile($target);
$texbody = read_file($tex);
like($texbody, qr/\{scrartcl\}/, "Passing nocoverpage in header changes the class");

$muse =<<'MUSE';
#title Test
#nocoverpage 1

** Hello there

Blablabla

MUSE

write_file($target, $muse);
$c = Text::Amuse::Compile->new(tex => 1);
$c->compile($target);
$texbody = read_file($tex);
like($texbody, qr/\{scrbook\}/,
     "Passing nocoverpage in header, but with toc, doesn't change the class");


