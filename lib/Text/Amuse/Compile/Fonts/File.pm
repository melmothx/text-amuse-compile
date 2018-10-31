package Text::Amuse::Compile::Fonts::File;
use strict;
use warnings;
use utf8;

use Moo;
use File::Basename qw//;
use File::Spec;
use Types::Standard qw/Maybe Str Enum ArrayRef/;

=head1 NAME

Text::Amuse::Compile::Fonts::File - font file object

=head1 ACCESSORS

=head2 file

The filename. Required

=head2 shape

The shape of the font. Must be regular, bold, italic or bolditalic.

=head2 format

Built lazily from the filename, validating it and crashing if it's not
otf, ttf or woff.

=head2 mimetype

Built lazily from the filename, validating it and crashing if it's not
otf, ttf or woff.

=head2 basename

The basename of the font.

=cut

has file => (is => 'ro',
             required => 1,
             isa => sub {
                 die "$_[0] is not a font file"
                   unless $_[0] && -f $_[0] && $_[0] =~ m/\.(woff|ttf|otf)\z/i
               });

has shape => (is => 'ro',
              required => 1,
              isa => Enum[qw/regular bold italic bolditalic/]);

has format => (is => 'lazy',
               isa => Str);

has mimetype => (is => 'lazy',
                 isa => Str);

has parsed_path => (is => 'lazy',
                    isa => ArrayRef);

sub _build_parsed_path {
    my $self = shift;
    if (my $file = $self->file) {
        return [ File::Basename::fileparse(File::Spec->rel2abs($file), qr/\.(woff|ttf|otf)\z/i) ];
    }
    else {
        return [ '', '', '' ];
    }
}

# my ($filename, $dirs, $suffix) = fileparse($path, @suffixes);

sub basename {
    shift->parsed_path->[0];
}

sub dirname {
    shift->parsed_path->[1];
}

sub basename_and_ext {
    my $parts = shift->parsed_path;
    return $parts->[0] . $parts->[2];
}

sub extension {
    shift->parsed_path->[2];
}

sub _build_format {
    my $self = shift;
    if (my $ext = $self->extension) {
        my %map = (
                   '.woff' => 'woff',
                   '.ttf' => 'truetype',
                   '.otf' => 'opentype',
                  );
        if (my $type = $map{lc($ext)}) {
            return $type;
        }
    }
    die "Bad file format without extension " . $self->file;
}

sub _build_mimetype {
    my $self = shift;
    if (my $format = $self->format) {
        my %map = (
                   woff => 'application/font-woff',
                   truetype => 'application/x-font-ttf',
                   opentype => 'application/x-font-opentype',
                  );
        return $map{$format};
    }
    return;
}


1;
