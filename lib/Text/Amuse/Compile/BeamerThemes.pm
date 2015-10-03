package Text::Amuse::Compile::BeamerThemes;

use utf8;
use strict;
use warnings;

=encoding utf8

=head1 NAME

Text::Amuse::Compile::BeamerThemes - Validate Beamer themes and color themes.

=head1 SYNOPSIS

 my $themes = Text::Amuse::Compile::BeamerThemes->new(theme => 'default', color_theme => 'default');
 $theme->themes; # list
 $theme->color_themes; # list
 $theme->theme; # guaranteed to return a valid theme
 $theme->color_theme; # guaranteed to return a valid color theme;

=head1 METHODS

=head2 new(theme => 'default', color_theme => 'default');

Constructor. You may want to pass the theme and the color_theme here.

=head2 themes

The list of available themes

=head2 color_themes

The list of available color themes

=head2 theme

The selected theme.

=head2 color_theme

The selected color theme.

=head2 as_latex

LaTeX code for the preamble.

=cut

sub new {
    my ($class, %opts) = @_;
    my $self = {
                theme => 'default',
                color_theme => 'default',
               };
    foreach my $key (%$self) {
        if ($opts{$key}) {
            $self->{$key} = $opts{$key};
        }
    }
    bless $self, $class;
}

sub themes {
    return qw//;
}

sub color_themes {
    return qw//;
}

sub theme {
    my $self = shift;
    my $theme = $self->{theme};
    return $theme;
}

sub color_theme {
    my $self = shift;
    my $color_theme = $self->{color_theme};
    return $color_theme;
}

sub as_latex {
    my $self = shift;
    my $color_theme = $self->color_theme;
    my $theme = $self->theme;
    my $string = "\\usetheme{${theme}}\n\\usecolortheme{${color_theme}}\n";
    return $string;
}

1;
