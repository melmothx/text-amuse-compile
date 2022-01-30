#!perl
use utf8;
use strict;
use warnings;
use Test::More;
use Text::Amuse::Compile::Fonts::File;
use Text::Amuse::Compile::Fonts;
use File::Temp;
use File::Spec;
use Text::Amuse::Compile::Utils qw/write_file/;
use JSON::MaybeXS;
use Data::Dumper;

my $wd = File::Temp->newdir;

my %files = ('file.ttf' => 'truetype',
             'fileuc.TTF' => 'truetype',
             'fileuc.OTF' => 'opentype',
             'file.otf' => 'opentype');

plan tests => 120;

foreach my $file (sort keys %files) {
    my $path = File::Spec->catfile($wd, $file);
    eval {
        Text::Amuse::Compile::Fonts::File->new(file => $path,
                                               shape => 'garbage');
    };
    ok !!$@, "Error found with wrong shape $@ for $file";
    eval {
        Text::Amuse::Compile::Fonts::File->new(file => $path,
                                               shape => 'italic');
    };
    ok !!$@, "Error found $@ for $file";
    write_file($path . 'asdf', 'x');
    eval {
        my $font = Text::Amuse::Compile::Fonts::File->new(file => $path . 'asdf',
                                                          shape => 'italic');
    };
    ok !!$@, "Error found with bad path $@ for $file";
    diag "Testing $path";
    write_file($path, 'x');
    eval {
        Text::Amuse::Compile::Fonts::File->new(file => $path,
                                               shape => 'garbage');
    };
    ok $@, "Error found with wrong shape";
    ok (-f $path, "$path exists");

    # 5 + 12 tests
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

{
    my $file = File::Spec->catfile($wd, 'fontspec.json');
    my $fontfile = File::Spec->catfile($wd, 'file.ttf');
    my @list = ({
                 name => 'Pippo Serif',
                 type => 'serif',
                 italic     => $fontfile,
                 bold       => $fontfile,
                 bolditalic => $fontfile,
                 regular    => $fontfile,
                },
                {
                 name => 'Pippo Mono',
                 type => 'mono',
                 regular => $fontfile,
                },
                {
                 name => 'Pippo Sans',
                 desc => 'Pippo ž Sans',
                 type => 'sans',
                },
               );
    # we're doing the encoding ourselves, so utf8 => 0
    my $json = JSON::MaybeXS->new(pretty => 1, canonical => 1, utf8 => 0)->encode(\@list);
    write_file($file, $json);
    for my $arg ($file, [ @list ]) {
        my $fonts = Text::Amuse::Compile::Fonts->new($arg);
        my ($sans) = $fonts->sans_fonts;
        my ($serif) = $fonts->serif_fonts;
        my ($mono)  = $fonts->mono_fonts;
        ok ($serif, "Found the serif font");
        is $serif->desc, $list[0]{name};
        is $serif->name, $list[0]{name};
        ok $serif->has_files, $serif->name . " has files";
        ok ($mono, "Found the mono font");
        is $mono->desc, $list[1]{name};
        is $mono->name, $list[1]{name};
        ok !$mono->has_files, $mono->name . " has no files";
        ok $mono->regular, "but has the regular file";
        ok ($sans, "Found the sans font");
        is $sans->desc, $list[2]{desc}, "Found the font desc";
        is $sans->name, $list[2]{name}, "Found the font name";
    }
}

# SYNOPSIS

{
    my %fontfiles = map { $_ => File::Spec->catfile($wd, $_ . '.otf') } (qw/regular italic
                                                                            bold bolditalic/);
    foreach my $file (values %fontfiles) {
        diag "Creating file $file";
        write_file($file, 'x');
    }
    my $fonts = Text::Amuse::Compile::Fonts->new([
                                                  {
                                                   name => 'Example Serif',
                                                   type => 'serif',
                                                   desc => 'example font',
                                                   regular => $fontfiles{regular},
                                                   italic => $fontfiles{italic},
                                                   bold => $fontfiles{bold},
                                                   bolditalic => $fontfiles{bolditalic},
                                                   languages => [qw/hr it/]
                                                  },
                                                  {
                                                   name => 'Example Sans',
                                                   type => 'sans',
                                                   desc => 'example sans font',
                                                   regular => $fontfiles{regular},
                                                   italic => $fontfiles{italic},
                                                   bold => $fontfiles{bold},
                                                   bolditalic => $fontfiles{bolditalic},
                                                  },
                                                  {
                                                   name => 'Example Mono',
                                                   type => 'mono',
                                                   desc => 'example font',
                                                   regular => $fontfiles{regular},
                                                   italic => $fontfiles{italic},
                                                   bold => $fontfiles{bold},
                                                   bolditalic => $fontfiles{bolditalic},
                                                  },

                                                  # more fonts here
                                                 ]);
    foreach my $method (qw/all_fonts sans_fonts mono_fonts serif_fonts
                           all_fonts_with_files sans_fonts_with_files
                           mono_fonts_with_files serif_fonts_with_files/) {
        my $name = ($fonts->$method)[0]->name;
        ok $name, "$method return $name";
    }
    my ($first) = $fonts->serif_fonts;
    is $first->babel_font_name, 'regular.otf';
    diag Dumper($first->babel_font_args);
    my $opts =  $first->babel_font_options(Scale => 'MatchLowercase');
    like $opts, qr{Scale=MatchLowercase};
    foreach my $type (qw/Bold Italic BoldItalic/) {
        like $opts, qr{${type}font=$type\.otf}i;
    }
    diag $opts;
    diag "Testing languages";
    ok $first->has_languages;
    ok $first->for_language_code('hr');
    ok $first->for_babel_language('croatian');
    ok !$first->for_language_code('en');
    ok !$first->for_babel_language('english');
    ok !$first->for_babel_language('pippo');
    my ($mono) = $fonts->mono_fonts;
    ok !$mono->has_languages;
    ok !$mono->for_language_code('hr');
    ok !$mono->for_babel_language('croatian');
}
