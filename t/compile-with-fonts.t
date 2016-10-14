#!perl

use strict;
use warnings;
use Text::Amuse::Compile;
use Text::Amuse::Compile::Utils qw/write_file read_file/;
use File::Temp;
use File::Spec;
use JSON::MaybeXS;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Test::More;

my $wd = File::Temp->newdir;
my %fontfiles = map { $_ => File::Spec->catfile($wd, $_ . '.otf') } (qw/regular italic
                                                                        bold bolditalic/);
foreach my $file (values %fontfiles) {
    diag "Creating file $file";
    write_file($file, 'x');
}
my @fonts = (
             {
              name => 'DejaVu Serif',
              type => 'serif',
              %fontfiles,
             },
             {
              name => 'DejaVu Sans',
              type => 'mono',
              %fontfiles,
             },
             {
              name => 'DejaVu Mono',
              type => 'sans',
              %fontfiles,
             },
            );

my $file = File::Spec->catfile($wd, 'fontspec.json');
my $json = JSON::MaybeXS->new(pretty => 1, canonical => 1, utf8 => 0)->encode(\@fonts);
write_file($file, $json);
my $muse_file = File::Spec->catfile($wd, 'test.muse');
write_file($muse_file, "#title Test fonts\n\nbla bla bla\n\n");

my $xelatex = $ENV{TEST_WITH_LATEX};
foreach my $fs ($file, \@fonts) {
    my $c = Text::Amuse::Compile->new(epub => 1,
                                      tex => 1,
                                      fontspec => $fs,
                                      extra => { mainfont => 'DejaVu Serif' },
                                      pdf => $xelatex);
    $c->compile($muse_file);
    {
        my $tex = $muse_file;
        $tex =~ s/\.muse/.tex/;
        ok (-f $tex, "$tex produced");
        like read_file($tex), qr/mainfont\{DejaVu Serif\}/;
    }
  SKIP: {
        skip "No pdf required", 1 unless $xelatex;
        my $pdf = $muse_file;
        $pdf =~ s/\.muse/.pdf/;
        ok (-f $pdf);
    }
    {
        my $epub = $muse_file;
        $epub =~ s/\.muse/.epub/;
        ok (-f $epub);
        my $tmpdir = File::Temp->newdir(CLEANUP => 1);
        my $zip = Archive::Zip->new;
        die "Couldn't read $epub" if $zip->read($epub) != AZ_OK;
        $zip->extractTree('OPS', $tmpdir->dirname) == AZ_OK
          or die "Couldn't extract $epub OPS into " . $tmpdir->dirname ;
        my $css = read_file(File::Spec->catfile($tmpdir->dirname, "stylesheet.css"));
        like $css, qr/font-family: "DejaVu Serif"/, "Found font-family";
        foreach my $file (qw/regular.otf bold.otf italic.otf bolditalic.otf/) {
            my $epubfile = File::Spec->catfile($tmpdir, $file);
            ok (-f $epubfile, "$epubfile embedded");
            like $css, qr/src: url\("\Q$file\E"\)/, "Found the css rules for $file";
        }
    }
}

done_testing;
