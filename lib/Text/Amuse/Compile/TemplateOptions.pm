package Text::Amuse::Compile::TemplateOptions;

use utf8;
use strict;
use warnings FATAL => 'all';
use Types::Standard qw/Str Bool/;
use Moo;
use Text::Amuse::Compile::BeamerThemes;

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

=item * oneside (true or false)

This is the default.

=item * twoside (true or false)

=back

=cut

has papersize  => (is => 'ro', isa => Str, default => sub { '' });
has bcor       => (is => 'ro', isa => Str, defautl => sub { '' });
has division   => (is => 'ro', isa => Str, default => sub { '' });
has oneside => (is => 'ro');
has twoside => (is => 'ro');

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

=cut

has mainfont   => (is => 'ro', isa => Str, default => sub { '' });
has sansfont   => (is => 'ro', isa => Str, default => sub { '' });
has monofont   => (is => 'ro', isa => Str, default => sub { '' });
has fontsize   => (is => 'ro', isa => Str, default => sub { '' });



=item * sitename

=item * siteslogan

=item * site

=item * logo (filename)

=cut

has sitename   => (is => 'ro', isa => Str, default => sub { '' });
has siteslogan => (is => 'ro', isa => Str, default => sub { '' });
has site       => (is => 'ro', isa => Str, default => sub { '' });
has logo       => (is => 'ro', isa => Str, default => sub { '' });

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

has cover      => (is => 'ro', isa => Str, default => sub { '' });
has coverwidth => (is => 'ro', isa => Str, default => sub { '' });
has nocoverpage => (is => 'ro');
has notoc   => (is => 'ro');
has opening => (is => 'ro');

=item * beamertheme

The theme to use with beamer, if and when the slides are produced. See
the beamer manual or L<https://www.hartwork.org/beamer-theme-matrix/>.
Defaults to the default one.

=item * beamercolortheme

Same as above, but for the color theme. Defaults to "dove" (b/w theme,
can't see the default purple).

=back

=cut

has beamertheme => (is => 'ro', isa => Str, default => sub { '' });
has beamercolortheme => (is => 'ro', isa => Str, default => sub { '' });

=head1 METHODS

=head2 as_latex($doc)

Return an hashref with parsed options for LaTeX output.

=cut

sub as_latex {
    
}


1;

