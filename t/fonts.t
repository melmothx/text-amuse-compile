#!perl

use strict;
use warnings;
use Test::More;
use Text::Amuse::Compile::Fonts::File;
use File::Temp;
use File::Spec;
use Text::Amuse::Compile::Utils qw/write_file/;

my $wd = File::Temp->newdir;

my %files = ('file.ttf' => 'truetype',
             'file.TTF' => 'truetype',
             'file.OTF' => 'opentype',
             'file.otf' => 'opentype',
             'file.woff' => 'woff',
             'file.WOFF' => 'woff');

plan tests => scalar(keys %files) * 18;

foreach my $file (sort keys %files) {
    my $path = File::Spec->catfile($wd, $file);
    eval {
        Text::Amuse::Compile::Fonts::File->new(file => $path,
                                               shape => 'garbage');
    };
    ok $@, "Error found with wrong shape $@";
    eval {
        Text::Amuse::Compile::Fonts::File->new(file => $path,
                                               shape => 'italic');
    };
    ok $@, "Error found $@";
    {
        write_file($path . 'asdf', 'x');
        my $font = Text::Amuse::Compile::Fonts::File->new(file => $path . 'asdf',
                                                          shape => 'italic');
        eval { $font->format };
        ok $@, "Crash with bad file extension";
    }
    ok $@, "Error found with bad path $@";
    diag "Testing $path";
    write_file($path, 'x');
    eval {
        Text::Amuse::Compile::Fonts::File->new(file => $path,
                                               shape => 'garbage');
    };
    ok $@, "Error found with wrong shape";
    ok (-f $path, "$path exists");
    foreach my $shape (qw/regular bold italic bolditalic/) {
        diag "Creathing $path $shape";
        my $font = Text::Amuse::Compile::Fonts::File->new(file => $path,
                                                          shape => $shape);
        is $font->shape, $shape, "shape ok";
        is $font->format, $files{$file}, "format ok";
        if ($files{$file} eq 'truetype') {
            is $font->mimetype, 'application/x-font-ttf', 'mimetype ok';
        }
        elsif ($files{$file} eq 'opentype') {
            is $font->mimetype, 'application/x-font-opentype', 'mimetype ok';
        }
        elsif ($files{$file} eq 'woff') {
            is $font->mimetype, 'application/font-woff', 'mimetype ok';
        }
        else {
            die "Not reached";
        }
    }
}
             
