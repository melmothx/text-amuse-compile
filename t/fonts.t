#!perl

use strict;
use warnings;
use Test::More;
use Text::Amuse::Compile::Fonts::File;
use Text::Amuse::Compile::Fonts;
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

plan tests => scalar(keys %files) * 18 + 6;

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

{
    # no list provided, use the defaults
    my $fonts = Text::Amuse::Compile::Fonts->new;
    my $default = $fonts->list->[0];
    ok !$default->has_files, $default->name . ' has no files';
}
{
    my $fonts = Text::Amuse::Compile::Fonts->new([ { name => 'Pippo', type => 'serif' } ]);
    my $default = $fonts->list->[0];
    ok !$default->has_files, $default->name . ' has no files';
}

{
    my $fonts;
    eval {
        $fonts = Text::Amuse::Compile::Fonts->new([ { name => 'Pippo',
                                                     type => 'serif',
                                                     italic => 'x',
                                                       } ]);
    };
    ok($@, "Found error passing a file which doesn't exist as italic $@");
    ok(!$fonts, "No font object initialized");
}
{
    my $file = File::Spec->catfile($wd, 'file.ttf');
    my $fonts = Text::Amuse::Compile::Fonts->new([
                                                  {
                                                   name => 'Pippo',
                                                   type => 'serif',
                                                   italic => $file,
                                                   bold => $file,
                                                   bolditalic => $file,
                                                  },
                                                 ]);
    ok !$fonts->list->[0]->has_files;
}

{
    my $file = File::Spec->catfile($wd, 'file.ttf');
    my $fonts = Text::Amuse::Compile::Fonts->new([
                                                  {
                                                   name => 'Pippo',
                                                   type => 'serif',
                                                   italic => $file,
                                                   bold => $file,
                                                   bolditalic => $file,
                                                   regular => $file,
                                                  },
                                                 ]);
    ok $fonts->list->[0]->has_files;
}
