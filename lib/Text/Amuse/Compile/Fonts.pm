package Text::Amuse::Compile::Fonts;
use utf8;
use strict;
use warnings;
use Types::Standard qw/ArrayRef InstanceOf/;
use JSON::MaybeXS qw/decode_json/;
use Text::Amuse::Compile::Fonts::Family;
use Text::Amuse::Compile::Fonts::File;
use Moo;
use Try::Tiny;

has list => (is => 'ro',
             isa => ArrayRef[InstanceOf['Text::Amuse::Compile::Fonts::Family']]);

sub BUILDARGS {
    my ($class, $arg) = @_;
    my $list;
    if ($arg) {
        if (my $ref = ref($arg)) {
            if ($ref eq 'ARRAY') {
                $list = $arg;
            }
            else {
                die "Argument to ->new must be either a file or an arrayref";
            }
        }
        else {
            try {
                open (my $fh, '<', $arg) or die "Cannot open $arg $!";
                local $/ = undef;
                my $body = <$fh>;
                close $fh;
                $list = decode_json($body);
            } catch {
                $list = undef;
            };
        }
    }
    $list ||= $class->_default_font_list;
    my @out;
    foreach my $font (@$list) {
        if ($font->{name} and $font->{type}) {
            $font->{desc} ||= $font->{name};
            foreach my $type (qw/regular bold italic bolditalic/) {
                if (my $file = delete $font->{$type}) {
                    my $obj = Text::Amuse::Compile::Fonts::File->new(file => $file,
                                                                     shape => $type
                                                                    );
                    $font->{$type} = $obj;
                }
            }
            push @out, Text::Amuse::Compile::Fonts::Family->new(%$font);
        }
    }
    return { list => \@out };
}

sub _default_font_list {
    return [
            {
             name => 'CMU Serif',
             desc => 'Computer Modern',
             type => 'serif',
            },
            {
             name => 'Linux Libertine O',
             desc => 'Linux Libertine',
             type => 'serif',
            },
            {
             name => 'TeX Gyre Termes',
             desc => 'TeX Gyre Termes (Times)',
             type => 'serif',
            },
            {
             name => 'TeX Gyre Pagella',
             desc => 'TeX Gyre Pagella (Palatino)',
             type => 'serif',
            },
            {
             name => 'TeX Gyre Schola',
             desc => 'TeX Gyre Schola (Century)',
             type => 'serif',
            },
            {
             name => 'TeX Gyre Bonum',
             desc => 'TeX Gyre Bonum (Bookman)',
             type => 'serif',
            },
            {
             name => 'Antykwa Poltawskiego',
             desc => 'Antykwa Półtawskiego',
             type => 'serif',
            },
            {
             name => 'Antykwa Torunska',
             desc => 'Antykwa Toruńska',
             type => 'serif',
            },
            {
             name => 'Charis SIL',
             desc => 'Charis SIL (Bitstream Charter)',
             type => 'serif',
            },
            {
             name => 'PT Serif',
             desc => 'Paratype (cyrillic)',
             type => 'serif',
            },
            {
             name => 'CMU Typewriter Text',
             desc => 'Computer Modern Typewriter Text',
             type => 'mono',
            },
            {
             name => 'DejaVu Sans Mono',
             desc => 'DejaVu Sans Mono',
             type => 'mono',
            },
            {
             name => 'TeX Gyre Cursor',
             desc => 'TeX Gyre Cursor (Courier)',
             type => 'mono',
            },
            {
             name => 'CMU Sans Serif',
             desc => 'Computer Modern Sans Serif',
             type => 'sans',
            },
            {
             name => 'TeX Gyre Heros',
             desc => 'TeX Gyre Heros (Helvetica)',
             type => 'sans',
            },
            {
             name => 'TeX Gyre Adventor',
             desc => 'TeX Gyre Adventor (Avant Garde Gothic)',
             type => 'sans',
            },
            {
             name => 'Iwona',
             desc => 'Iwona',
             type => 'sans',
            },
            {
             name => 'Linux Biolinum O',
             desc => 'Linux Biolinum',
             type => 'sans',
            },
            {
             name => 'DejaVu Sans',
             desc => 'DejaVu Sans',
             type => 'sans',
            },
            {
             name => 'PT Sans',
             desc => 'PT Sans (cyrillic)',
             type => 'sans',
            },
           ];
}


1;
