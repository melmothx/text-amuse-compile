#!perl

use strict;
use warnings;
use Test::More tests => 3;
use File::Temp;
use File::Spec::Functions qw/catfile catdir/;
use Text::Amuse::Compile;
use Text::Amuse::Compile::Utils qw/write_file read_file/;

my $tmpdir = File::Temp->newdir;

my $target = catfile($tmpdir, 'default.muse');
my $tex = catfile($tmpdir, 'default.tex');
my $muse =<<'MUSE';
#title Test

** Hello

** There

** Blah

Hello there
MUSE

my $c = Text::Amuse::Compile->new(tex => 1);

write_file($target, $muse);

$c->compile($target);

ok(-f $tex, "$tex file is present");

my $texbody = read_file($tex);

like($texbody, qr/\\tableofcontents/, "ToC is present");

$c = Text::Amuse::Compile->new(tex => 1, extra => { notoc => 1 });

$c->compile($target);
$texbody = read_file($tex);

unlike($texbody, qr/\\tableofcontents/, "notoc prevents the ToC generation");

