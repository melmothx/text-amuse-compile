package Text::Amuse::Compile::Fonts::Import;
use utf8;
use strict;
use warnings;
use IO::Pipe;
use JSON::MaybeXS ();
use Moo;

has output => (is => 'ro');

sub use_fclist {
    return system('fc-list', '--version') == 0;
}

sub use_imagemagick {
    return system('identify', '-version') == 0;
}

sub try_list {
    return {
            serif => [
                      'CMU Serif',
                      'Linux Libertine O',
                      'Charis SIL',
                      'TeX Gyre Termes',
                      'TeX Gyre Pagella',
                      'TeX Gyre Schola',
                      'TeX Gyre Bonum',
                      'Antykwa Poltawskiego',
                      'Antykwa Torunska',
                      'PT Serif',
                      'Droid Serif',
                      'Noto Serif',
                     ],
            sans => [
                     'CMU Sans Serif',
                     'Linux Biolinum O',
                     'Iwona',
                     'TeX Gyre Heros',
                     'TeX Gyre Adventor',
                     'Droid Sans',
                     'Noto Sans',
                     'DejaVu Sans',
                     'PT Sans',
                    ],
            mono => [
                     'CMU Typewriter Text',
                     'DejaVu Sans Mono',
                     'TeX Gyre Cursor',
                    ],
           };
}

sub all_fonts {
    my $self = shift;
    my $list = $self->try_list;
    my %all;
    foreach my $k (keys %$list) {
        foreach my $font (@{$list->{$k}}) {
            $all{$font} = $k;
        }
    }
    return %all;
}

sub import_with_fclist {
    my $self = shift;
    return unless $self->use_fclist;
    my %specs;
    my %all = $self->all_fonts;
    my $pipe = IO::Pipe->new;
    $pipe->reader('fc-list');
    $pipe->autoflush;
    while (<$pipe>) {
        chomp;
        if (m/(.+?)\s*:\s*(.+?)(\,.+)?\s*:\s*style=(Bold|Italic|Regular|Book|Bold\s*Italic|Oblique|Bold\s*Oblique)$/) {
            my $file = $1;
            my $name = $2;
            my $style = lc($4);
            $style =~ s/\s//g;
            $style =~ s/oblique/italic/;
            $style =~ s/book/regular/;
            next unless $all{$name};
            if ($specs{$name}{files}{$style}) {
                # warn "Duplicated font! $file $name $style $specs{$name}{files}{$style}\n";
            }
            else {
                $specs{$name}{files}{$style} = $file;
            }
        }
    }
    wait;
    return \%specs;
    
}

sub import_with_imagemagick {
    my $self = shift;
    return unless $self->use_imagemagick;
    my %specs;
    my %all = $self->all_fonts;
    my $pipe = IO::Pipe->new;
    $pipe->reader('identify', -list => 'font');
    $pipe->autoflush;
    my %current;
    while (<$pipe>) {
        chomp;
        if (m/^\s*Font:/) {
            if ($current{family} && $current{glyphs} && $current{style} && $current{weight}) {
                my $name = $current{family};
                my $file = $current{glyphs};
                my $style;
                if ($current{style} eq 'Normal') {
                    if ($current{weight} == 700) {
                        $style = 'bold';
                    }
                    elsif ($current{weight} == 400 or
                           $current{weight} == 500) {
                        $style = 'regular';
                    }
                }
                elsif ($current{style} eq 'Italic') {
                    if ($current{weight} == 700) {
                        $style = 'bolditalic';
                    }
                    elsif ($current{weight} == 400 or
                           $current{weight} == 500) {
                        $style = 'italic';
                    }
                }
                if ($style and $all{$name}) {
                    if ($specs{$name}{files}{$style}) {
                        # warn "Duplicated font! $file $name $style $specs{$name}{files}{$style}\n";
                    }
                    else {
                        $specs{$name}{files}{$style} = $file;
                    }
                }
            }
            %current = ();
        }
        elsif (m/^\s*(\w+):\s+(.+)\s*$/) {
            $current{$1} = $2;
        }
    }
    return \%specs;
}

sub import {
    my $self = shift;
    my $list = $self->try_list;
    my $specs = $self->import_with_fclist || $self->import_with_imagemagick;
    die "Cannot retrieve specs, nor with fc-list, nor with imagemagick" unless $specs;
    my @out;
    foreach my $type (qw/serif sans mono/) {
        foreach my $font (@{$list->{$type}}) {
            if (my $found = $specs->{$font}) {
                my $files = $found->{files};
                if (%$files and scalar(keys %$files) == 4) {
                    push @out, {
                                name => $font,
                                desc => $font,
                                type => $type,
                                regular => $files->{regular},
                                italic => $files->{italic},
                                bold => $files->{bold},
                                bolditalic => $files->{bolditalic},
                               };
                }
            }
        }
    }
    return \@out;
};

sub as_json {
    my $self = shift;
    my $list = $self->import;
    return JSON::MaybeXS->new(pretty => 1,
                              canonical => 1,
                             )->encode($list);
}

sub import_and_save {
    my $self = shift;
    my $json = $self->as_json;
    if (my $file = $self->output) {
        open (my $fh, '>', $file) or die $!;
        print $fh $json;
        close $fh;
    }
    else {
        print $json;
    }
}

1;
