#!perl
use strict;
use warnings;
use utf8;
use Test::More tests => 127;
use Text::Amuse::Compile;
use File::Spec;
use Text::Amuse::Compile::Utils qw/read_file/;

my $extra = {
             site => "Test site",
             mainfont => "LModern",
             siteslogan => "Hello there!",
             site => "http://mysite.org",
             sitename => "Another crappy test site",
             papersize => "a4paperwithears",
             division => 9,
             fontsize => 48,
             twoside => "true",
             bcor => "23",
             logo => "pallinopinco",
             cover => "mycover.pdf",
             coverwidth => "\\0.5", # given the filtering, the \\ will  be stripped
            };

my $compile = Text::Amuse::Compile->new(
                                        extra => $extra,
                                        standalone => 0,
                                        tex   => 1,
                                        cleanup => 1,
                                       );

my $extracopy = { %$extra };
$extracopy->{coverwidth} = '0.5';
is_deeply({ $compile->extra }, $extracopy, "extra options stored" );
ok ($compile->cleanup);

my $returned = { $compile->extra };

diag "Added key to passed ref";
$extra->{ciao} = 1;

is_deeply({ $compile->extra }, $returned );

my @targets;
my @results;
my @statusfiles;
foreach my $i (qw/1 2/) {
    my $target = File::Spec->catfile('t','options-f', 'dir' . $i, $i,
                                     'options' . $i);
    push @results, $target . '.tex';
    push @targets, $target . '.muse';
    push @statusfiles, $target . '.status';
}




foreach my $f (@results) {
    if (-f $f) {
        unlink $f or die $!;
    }
}


# twice to check the option persistence
for (1..2) {
    diag "Run $_";
    $compile->compile(@targets);
    diag "Compilation finished";
    foreach my $f (@results) {
        ok ((-f $f), "produced $f");
        my $c = read_file($f);
        # diag substr($c, 0, 200);
        my %tests = %$returned;
        delete $tests{bcor};
        delete $tests{twoside};
        foreach my $string (values %tests) {
            like $c, qr/\Q$string\E/, "Found $string";
        }
        like $c, qr/DIV=9/, "Found the div factor";
        like $c, qr/fontsize=48pt/, "Found the fontsize";
        unlike $c, qr/twoside/, "oneside enforced";
        like $c, qr/oneside/, "oneside enforced on single pdf";
        like $c, qr/BCOR=0mm/, "BCOR validated and enforced";
        unlike $c, qr/\\maketitle/;
        like $c, qr/includegraphics\[width=0\.5\\textwidth\]\{mycover.pdf\}/;
        like $c, qr/\\tableofcontents/;
    }

    foreach my $f (@results) {
        if (-f $f) {
            unlink $f or die $!;
        }
    }
    foreach my $f (@statusfiles) {
        ok ((! -e $f), File::Spec->rel2abs($f) . " was removed!");
    }
}


my $targetdir = File::Spec->catfile('t', 'testfile');
chdir $targetdir or die $!;
my $tt = Text::Amuse::Compile::Templates->new;
my $file = Text::Amuse::Compile::File->new(name => 'test',
                                           suffix => '.muse',
                                           cleanup => 1,
                                           templates => $tt);

foreach my $ext (qw/.html .tex .pdf .bare.html .epub/) {
    my $f = $file->name . $ext;
    if (-f $f) {
        unlink $f or die $!;
    }
}

diag "Working in $targetdir";

for (1..2) {
    $file->tex(%$returned);
    my $texfile = $file->name . '.tex';
    ok ((-f $texfile), "produced $texfile");
    my $c = read_file($texfile);
    # diag substr($c, 0, 200);
    my %tests = %$returned;
    foreach my $string (values %tests) {
        like $c, qr/\Q$string\E/, "Found $string";
    }
    like $c, qr/DIV=9/, "Found the div factor";
    like $c, qr/fontsize=48pt/, "Found the fontsize";
    like $c, qr/twoside/, "oneside not enforced";
    unlike $c, qr/oneside/, "oneside not enforced";
    unlike $c, qr/BCOR=0mm/, "BCOR not enforced";
    like $c, qr/BCOR=23/, "BCOR not enforced";
    unlike $c, qr/\\maketitle/;
    like $c, qr/includegraphics\[width=0\.5\\textwidth\]\{mycover.pdf\}/;
    like $c, qr/\\tableofcontents/;
    unlink $texfile or die $!;
}

