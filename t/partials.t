#!perl

use utf8;
use strict;
use warnings;
use File::Spec::Functions qw/catfile catdir/;
use Text::Amuse::Compile;
use Test::More tests => 1;

my $muse = <<'MUSE';
#title The title ()
#author The author ()

First chunk àà (0)

* First part (1)

First part body ćđ (1)

** First chapter (2)

First chapter body (2)

*** First section (3)

First section body (3)

**** First subsection (4)

First subsection (4)

 Item :: Blabla (4)

* Second part (5)

Second part body (5)

** Second chapter (6)

Second chapter body (6)

*** Second section (7)

Second section body (7)

**** Second subsection (8)

Second subsection (8)

 Item :: Blabla

*** Third section (9)

Third section (9)

 Item :: Blabla

*** Fourth section (10)

Blabla (10)

MUSE

my $dh = File::Temp->newdir(CLEANUP => !$ENV{NO_CLEANUP});
my $wd = $dh->dirname;
diag "Working in $wd";
my @files = (qw/first second third/);

# populate
my $c = Text::Amuse::Compile->new(tex => 1, html => 1, epub => 1);

for my $file (@files) {
    my $filename = catfile($wd, $file. '.muse');
    my $body = $muse;
    $body =~ s/\(/- $file - (/g;
    open (my $fh, '>:encoding(utf-8)', $filename) or die $!;
    print $fh $body;
    close $fh;
    ok($c->compile($filename), "Plain $filename is ok");
    ok($c->compile($filename . ':1,3,9'));
}


ok($c->compile({
                path => $wd,
                name => 'new-test',
                files => \@files,
                title => 'Hello World',
               }), "plain virtual compiled ok");


ok($c->compile({
                path => $wd,
                name => 'new-test',
                files => [
                          $files[0] . ':1,3',
                          $files[1] . ':3,9',
                          $files[2] . ':9,100',
                         ],
                title => 'Hello World',
               }), "new-test compiled");
