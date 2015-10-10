package Text::Amuse::Compile::TemplateOptions;

use utf8;
use strict;
use warnings FATAL => 'all';
use Types::Standard qw/Str Bool/;
use Type::Utils qw/enum/;
use Moo;
use Text::Amuse::Compile::BeamerThemes;
use constant {
    TEX_MEASURE => qr{[0-9]+(\.[0-9]+)?(cm|mm|in|pt)},
};

=head1 NAME

Text::Amuse::Compile::TemplateOptions - parse and validate options for templates

=head2 SYNOPSIS

  use Text::Amuse::Compile::TemplateOptions;
  my $options = Text::Amuse::Compile::TemplateOptions->new(%options);
  my $doc = Text::Amuse->new(file => 'test.muse');
  # and get the hashrefs for the tokens
  my $latex_options = $options->as_latex($doc);

=head1 ACCESSORS

The follow accessors are read only and should be set in the
contructor. The same settings can be passed to the C<muse-compile.pl>
script.

=head2 Paper

=over 4

=item * papersize (common values: a4, a5, letter)

=item * bcor (binding correction for inner margins)

=item * division (the DIV factor for margin control)

=item * oneside (boolean)

This is the default. Actually, this option doesn't have any use.

=item * twoside (boolean)

=back

=cut

sub _get_papersize {
    my $paper = $_[0];
    my %aliases = (
                   'half-a4' => 'a5',
                   'half-lt' => '5.5in:8.5in',
                   generic => '210mm:11in',
                   a4 => 'a4',
                   a5 => 'a5',
                   a6 => 'a6',
                   letter => 'letter',
                  );
    if ($paper) {
        my $tex_measure = TEX_MEASURE;
        if ($aliases{$paper}) {
            return $aliases{$paper};
        }
        elsif ($paper =~ m/\A$tex_measure:$tex_measure\z/) {
            return $paper;
        }
        else {
            die "papersize is invalid";
        }
    }
    else {
        return '210mm:11in';
    }
}


has papersize  => (is => 'rw',
                   isa => \&_get_papersize,
                   default => sub { '210mm:11in' },
                  );

sub tex_papersize {
    my $self = shift;
    return _get_papersize($self->papersize);
}


has bcor => (is => 'rw',
             isa => sub {
                 die "Bcor must be a measure like 11mm"
                   unless $_[0] =~ TEX_MEASURE;                 
             },
             default => sub { '0mm' });

sub division_values {
    return [9..15];
}

has division   => (is => 'rw',
                   isa => enum(__PACKAGE__->division_values),
                   default => sub { '12' },
                  );
has oneside => (is => 'rw', isa => Bool);
has twoside => (is => 'rw', isa => Bool);

=head2 Fonts

=over 4

=item * mainfont (grep fc-list -l for the correct name)

=item * sansfont 

The sans serif font to use. This option has some effects only on
slides.

=item * monofont 

The monospace font to use.

=item * fontsize (9, 10, 11, 12) as integer, meaning points (pt)

=back

Additionally, the following methods are provided, which can be called
on the class:

=over 4

=item sans_fonts

=item mono_fonts

=item serif_fonts

=item all_fonts

=back

They return a list of hashrefs, with two keys, C<name> and C<desc>.
The first is the system font name, the second is the description.

=cut

sub serif_fonts {
    my @fonts = (
                 {
                  name => 'Linux Libertine O',
                  desc => 'Linux Libertine'
                 },
                 {
                  name => 'CMU Serif',
                  desc => 'Computer Modern',
                 },
                 {
                  name => 'TeX Gyre Termes',
                  desc => 'TeX Gyre Termes (Times)',
                 },
                 {
                  name => 'TeX Gyre Pagella',
                  desc => 'TeX Gyre Pagella (Palatino)',
                 },
                 {
                  name => 'TeX Gyre Schola',
                  desc => 'TeX Gyre Schola (Century)',
                 },
                 {
                  name => 'TeX Gyre Bonum',
                  desc => 'TeX Gyre Bonum (Bookman)',
                 },
                 {
                  name => 'Antykwa Poltawskiego',
                  desc => 'Antykwa Półtawskiego',
                 },
                 {
                  name => 'Antykwa Torunska',
                  desc => 'Antykwa Toruńska',
                 },
                 {
                  name => 'Charis SIL',
                  desc => 'Charis SIL (Bitstream Charter)',
                 },
                 {
                  name => 'PT Serif',
                  desc => 'Paratype (cyrillic)',
                 },
                );
    return @fonts;
}
sub mono_fonts {
    my @fonts = (
                 {
                  name => 'DejaVu Sans Mono',
                  desc => 'DejaVu Sans Mono',
                 },
                 {
                  name => 'CMU Typewriter Text',
                  desc => 'Computer Modern Typewriter Text',
                 },
                );
}
sub sans_fonts {
    my @fonts = (
                 {
                  name => 'CMU Sans Serif',
                  desc => 'Computer Modern Sans Serif',
                 },
                 {
                  name => 'TeX Gyre Heros',
                  desc => 'TeX Gyre Heros (Helvetica)',
                 },
                 {
                  name => 'TeX Gyre Adventor',
                  desc => 'TeX Gyre Adventor (Avant Garde Gothic)',
                 },
                 {
                  name => 'Iwona',
                  desc => 'Iwona',
                 },
                 {
                  name => 'Linux Biolinum O',
                  desc => 'Linux Biolinum',
                 },
                 {
                  name => 'DejaVu Sans',
                  desc => 'DejaVu Sans',
                 },
                 {
                  name => 'PT Sans',
                  desc => 'PT Sans (cyrillic)',
                 },

                );
    return @fonts;
}

sub all_fonts {
    my $self = shift;
    my @all = ($self->serif_fonts, $self->sans_fonts, $self->mono_fonts);
    return @all;
}

my $font_type = enum([ map { $_->{name} } __PACKAGE__->all_fonts ]);

has mainfont   => (is => 'rw',
                   isa => $font_type,
                   default => sub { 'CMU Serif' },
                  );
has sansfont   => (is => 'rw',
                   isa => $font_type,
                   default => sub { 'CMU Sans Serif' },
                  );
has monofont   => (is => 'rw',
                   isa => $font_type,
                   default => sub { 'CMU Typewriter Text' },
                  );

sub font_sizes {
    return [ 9..12 ];
}

has fontsize   => (is => 'rw',
                   isa => enum(__PACKAGE__->font_sizes),
                   default => sub { 10 },
                  );


=item * sitename

=item * siteslogan

=item * site

=item * logo (filename)

=cut

sub _check_filename {
    my $filename = $_[0];
    # false value, accept, will not be inserted.
    return unless $filename;
    # windows thing, in case
    $filename =~ s!\\!/!g;
    # is a path? test if it exists
    if ($filename =~ m!/!) {
        # non-ascii things will never match here
        # because of the decoding. I see this as a feature
        if (-f $filename and
            $filename =~ m/^[a-zA-Z0-9\-\:\/]+\.(pdf|jpe?g|png)$/s) {
            return $filename;
        }
        else {
            die "Absolute filename $filename must exist";
        }
    }
    elsif ($filename =~ m/\A
                          (
                              [a-zA-Z0-9-]+
                              (\.(pdf|jpe?g|png))?
                          )
                          \z/x) {
        # sane filename;
        return $1;
    }
    die "$filename is neither absolute and existing or a bare name without specail characters";
}

has sitename   => (is => 'rw', isa => Str, default => sub { '' });
has siteslogan => (is => 'rw', isa => Str, default => sub { '' });
has site       => (is => 'rw', isa => Str, default => sub { '' });
has logo       => (is => 'rw',
                   isa => \&_check_filename,
                   default => sub { '' },
                  );

=item * cover (filename for front cover)

When this option is set to a true value, skip the creation of the
title page with \maketitle, and instead build a custome one, with the
cover placed in the middle of the page.

The value can be an absolute path, or a bare filename, which can be
found by C<kpsewhich>. If the path is not valid and sane (from the
LaTeX point of view: no spaces, no strange chars), the value is
ignored.

=item * coverwidth (dimension ratio with the text width, eg. '0.85')

It requires a float, where 1 is the full text-width, 0.5 half, etc.

=item * nocoverpage

Use the LaTeX article class if ToC is not present

=item * notoc

Never generate a table of contents

=item * opening

Page for starting a chapter: "any" or "right" or (at your own peril)
"left"

=cut

has cover      => (is => 'rw',
                   isa => \&_check_filename,
                   default => sub { '' },
                  );

sub _check_coverwidth {
    my $width = $_[0];
    die "$width should be a number" unless $width;
    if ($width =~ m/\A[01](\.[0-9][0-9]?)?\z/) {
        die "coverwidth should be a number minor or equal to 1"
          unless ($width <= 1 && $width > 0);
    }
    else {
        die "coverwidth should be a number minor or equal to 1"
    }
}

has coverwidth => (is => 'rw',
                   isa => \&_check_coverwidth,
                   default => sub { 1 });

has nocoverpage => (is => 'rw', isa => Bool, default => sub { 0 });
has notoc       => (is => 'rw', isa => Bool, default => sub { 0 });

has opening => (is => 'rw', isa => enum([qw/any right left/]));

=item * beamertheme

The theme to use with beamer, if and when the slides are produced. See
the beamer manual or L<https://www.hartwork.org/beamer-theme-matrix/>.
Defaults to the default one.

=item * beamercolortheme

Same as above, but for the color theme. Defaults to "dove" (b/w theme,
can't see the default purple).

=back

=cut

has beamertheme => (is => 'rw', isa => Str, default => sub { '' });
has beamercolortheme => (is => 'rw', isa => Str, default => sub { '' });

=head1 METHODS

=head2 as_latex($doc)

Return an hashref with parsed options for LaTeX output.

=cut

sub as_latex {
    
}

=head2 paging

This merges C<oneside> and C<twoside>. If both or none
are set, defaults to C<oneside>.

=cut

sub paging {
    my $self = shift;
    my $default = 'oneside';
    if ($self->twoside && $self->oneside) {
        return $default;
    }
    if ($self->twoside) {
        return 'twoside';
    }
    else {
        return $default;
    }
}

1;

