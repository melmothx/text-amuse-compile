#!perl
use strict;
use warnings;
use utf8;
use Test::More tests => 138;
use Text::Amuse::Compile;
use File::Spec;
use Text::Amuse::Compile::File;
use Text::Amuse::Compile::Utils qw/read_file/;
use Cwd;

my $basepath = getcwd();

my $extra = {
             site => "Test site",
             mainfont => "LModern",
             siteslogan => "Hello there!",
             site => "http:mysite.org",
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
is_deeply({ $compile->extra }, $extracopy, "extra options stored" );
ok ($compile->cleanup);

my $returned = { $compile->extra };

diag "Added key to passed ref";
$extra->{ciao} = 1;

is_deeply({ $compile->extra }, $returned );

$returned = {
             $compile->extra,
             papersize => '210mm:11in',
             fontsize => 10,
             bcor => '0mm',
             coverwidth => '0.5',
            };

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
        like $c, qr/fontsize=10pt/, "Found the fontsize";
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
    like $c, qr/fontsize=10pt/, "Found the fontsize";
    like $c, qr/twoside/, "oneside not enforced";
    unlike $c, qr/oneside/, "oneside not enforced";
    like $c, qr/BCOR=0mm/, "BCOR enforced";
    unlike $c, qr/\\maketitle/;
    like $c, qr/includegraphics\[width=0\.5\\textwidth\]\{mycover.pdf\}/;
    like $c, qr/\\tableofcontents/;
    unlink $texfile or die $!;
}


my $dummy = Text::Amuse::Compile::File->new(
                                            name => 'dummy',
                                            suffix => '.muse',
                                            templates => 'dummy',
                                            options => {
                                                        pippo => '[[http://test.org][test]]',
                                                        prova => 'hello *there* & \stuff',
                                                        ciao => 1,
                                                        test => "Another great thing!",
                                                       },
                                           );

my $html_options = $dummy->options('html');
my $latex_options = $dummy->options;

is_deeply($html_options, {
                          pippo => '<a href="http://test.org">test</a>',
                          prova => 'hello <em>there</em> &amp; \stuff',
                          ciao => 1,
                          test => "Another great thing!",
                         }, "html escaped and interpreted ok");
is_deeply($latex_options, {
                           prova => 'hello \emph{there} \& \textbackslash{}stuff',
                           pippo => '\href{http://test.org}{test}',
                           ciao => 1,
                           test => "Another great thing!",
                          }, "latex escaped and interpreted ok");

is_deeply($dummy->options('ltx'), $latex_options);

eval {
    my $die = $dummy->options('garbage');
};
ok ($@, "Incorrect usage leads to exception");

chdir $basepath or die $!;

$dummy = Text::Amuse::Compile::File->new(
                                         name => 'dummy',
                                         suffix => '.muse',
                                         templates => 'dummy',
                                         options => {
                                                     cover => 'prova.pdf',
                                                     logo => 'c-i-a',
                                                    },
                                           );

is $dummy->options->{cover}, 'prova.pdf';
is $dummy->options->{logo}, 'c-i-a';

my $testfile = File::Spec->rel2abs(File::Spec->catfile(qw/t manual logo.png/));
ok (-f $testfile, "$testfile exists");

SKIP: {
    skip "Testfile $testfile doesn't look sane", 6
      unless $testfile =~ m/^[a-zA-Z0-9\-\:\/\\]+\.(pdf|jpe?g|png)$/s;
    $testfile =~ s/\\/\//g; # for tests on windows.
    my $wintestfile = $testfile;
    $wintestfile =~ s/\//\\/g;
    $dummy = Text::Amuse::Compile::File->new(
                                             name => 'dummy',
                                             suffix => '.muse',
                                             templates => 'dummy',
                                             options => {
                                                         cover => $testfile,
                                                         logo => $wintestfile,
                                                        },
                                            );

    ok $dummy->_check_filename($testfile), "$testfile is valid";
    ok $dummy->_check_filename($wintestfile), "$wintestfile is valid";

    is $dummy->options->{cover}, $testfile, "cover is $testfile";
    is $dummy->options->{logo}, $testfile, "logo is $testfile";

    $dummy = Text::Amuse::Compile::File->new(
                                             name => 'dummy',
                                             suffix => '.muse',
                                             templates => 'dummy',
                                             options => {
                                                         cover => 'a bc.pdf',
                                                         logo => 'c alsdkfl',
                                                        },
                                            );
    is $dummy->options->{cover}, undef, "cover with spaces doesn't validate";
    is $dummy->options->{logo}, undef, "logo with spaces doesn't validate";
}
