#!perl
use strict;
use warnings;
use utf8;
use Test::More tests => 54;
use Text::Amuse::Compile;
use File::Spec;
use File::Slurp qw/read_file/;

my $extra = {
             site => "Test site",
             mainfont => "LModern",
             siteslogan => "Hello there!",
             site => "http://mysite.org",
             sitename => "Another crappy test site",
             size => "a4paperwithears",
             division => 9,
             fontsize => 48,
             twoside => "twoside",
             bcor => "23",
             logo => "pallinopinco",
            };

my $compile = Text::Amuse::Compile->new(
                                        extra => $extra,
                                        tex   => 1,
                                       );

is_deeply({ $compile->extra }, $extra, "extra options stored" );

my $returned = { $compile->extra };

diag "Added key to passed ref";
$extra->{ciao} = 1;

is_deeply({ $compile->extra }, $returned );

my @targets;
my @results;
my @okfiles;
foreach my $i (qw/1 2/) {
    my $target = File::Spec->catfile('t','options-f', 'dir' . $i, $i,
                                     'options' . $i);
    my $muse = $target . '.muse';
    my $tex  = $target . '.tex';
    my $okfile = $target . '.ok';
    push @results, $tex;
    push @targets, $muse;
    push @okfiles, $okfile;
}




foreach my $f (@results, @okfiles) {
    if (-f $f) {
        unlink $f or die $!;
    }
}


# twice to check the option persistence
for (1..2) {
    $compile->compile(@targets);

    foreach my $f (@results) {
        ok ((-f $f), "produced $f");
        my $c = read_file($f);
        diag substr($c, 0, 200);
        foreach my $string (values %$returned) {
            like $c, qr/\Q$string\E/, "Found $string";
        }
        like $c, qr/DIV=9/, "Found the div factor";
        like $c, qr/fontsize=48pt/, "Found the fontsize";
    }


    foreach my $f (@results, @okfiles) {
        if (-f $f) {
            unlink $f or die $!;
        }
    }
}


