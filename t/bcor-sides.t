#!perl

use strict;
use warnings;
use Test::More tests => 15;
use File::Temp;
use File::Slurp qw/read_file write_file/;
use File::Spec::Functions qw/catfile/;
use Cwd;

use Text::Amuse::Compile::File;
use Text::Amuse::Compile::Templates;

my $dirh = File::Temp->newdir(CLEANUP => 1);
my $wd = $dirh->dirname;

my $home = getcwd;

chdir $wd;

write_file("test.muse", "#title test\n\nblablabla\n");

# we we call ->tex, normally the oneside/twoside/bcor are ignored,
# because it's used only on imposed ones, unless we set standalone to
# true.

my $templates = Text::Amuse::Compile::Templates->new;
my $muse = Text::Amuse::Compile::File->new(name => 'test',
                                           suffix => '.muse',
                                           options => {
                                                       oneside => 0,
                                                       twoside => 1,
                                                       bcor => '12mm',
                                                      },
                                           templates => $templates);

my $tex = read_file($muse->tex);

like $tex, qr/blablabla/, "Found the body";
like $tex, qr/oneside/, "Found oneside";
like $tex, qr/bcor=0mm/i, "Found bcor=0";
unlike $tex, qr/twoside/, "Found twoside";
unlike $tex, qr/bcor=12mm/i, "Found bcor=12mm";

# but with arguments, bcor and sides are obeyed.
$tex = read_file($muse->tex(dummy => 1));

like $tex, qr/blablabla/, "Found the body";
like $tex, qr/twoside/, "Found twoside";
like $tex, qr/bcor=12mm/i, "Found bcor=12mm";
unlike $tex, qr/oneside/, "Found oneside";
unlike $tex, qr/bcor=0mm/i, "Found bcor=0";


$muse = Text::Amuse::Compile::File->new(name => 'test',
                                        suffix => '.muse',
                                        standalone => 1,
                                        options => {
                                                    oneside => 0,
                                                    twoside => 1,
                                                    bcor => '12mm',
                                                   },
                                        templates => $templates);

$tex = read_file($muse->tex);

like $tex, qr/blablabla/, "Found the body";
like $tex, qr/twoside/, "Found twoside";
like $tex, qr/bcor=12mm/i, "Found bcor=12mm";
unlike $tex, qr/oneside/, "Found oneside";
unlike $tex, qr/bcor=0mm/i, "Found bcor=0";


chdir $home;






