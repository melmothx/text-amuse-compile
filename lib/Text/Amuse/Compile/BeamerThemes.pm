package Text::Amuse::Compile::BeamerThemes;

use utf8;
use strict;
use warnings;

=encoding utf8

=head1 NAME

Text::Amuse::Compile::BeamerThemes - Validate Beamer themes and color themes.

=head2 DESCRIPTION

Implements L<https://www.hartwork.org/beamer-theme-matrix/>

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

=head2 default_theme

The default theme.

=head2 default_color_theme

The default color theme.

=head2 as_latex

LaTeX code for the preamble.

=cut

use constant {
    DEFAULT_THEME => 'default',
    DEFAULT_COLOR_THEME => 'dove',
};



sub new {
    my ($class, %opts) = @_;
    my $self = {
                theme => DEFAULT_THEME,
                color_theme => DEFAULT_COLOR_THEME,
               };
    foreach my $key (%$self) {
        if ($opts{$key}) {
            $self->{$key} = $opts{$key};
        }
    }
    bless $self, $class;
}

sub default_color_theme {
    return DEFAULT_COLOR_THEME;
}

sub default_theme {
    return DEFAULT_THEME;
}

sub themes {
    my @themes = (qw/default
                     Bergen
                     Boadilla
                     Madrid
                     AnnArbor
                     CambridgeUS
                     EastLansing
                     Pittsburgh
                     Rochester
                     Antibes
                     JuanLesPins
                     Montpellier
                     Berkeley
                     PaloAlto
                     Goettingen
                     Marburg
                     Hannover
                     Berlin
                     Ilmenau
                     Dresden
                     Darmstadt
                     Frankfurt
                     Singapore
                     Szeged
                     Copenhagen
                     Luebeck
                     Malmoe
                     Warsaw/);
    return @themes;
}

sub color_themes {
    my @themes = (qw/default
                     albatross
                     beetle
                     crane
                     dove
                     fly
                     monarca
                     seagull
                     wolverine
                     beaver
                     spruce
                     lily
                     orchid
                     rose
                     whale
                     seahorse
                     dolphin/);
    return @themes;
}

sub theme {
    my $self = shift;
    my $theme = $self->{theme} || DEFAULT_THEME;
    my @match = grep { $theme eq $_ } $self->themes;
    if (@match) {
        return $theme;
    }
    else {
        return DEFAULT_THEME;
    }
}

sub color_theme {
    my $self = shift;
    my $theme = $self->{color_theme} || DEFAULT_COLOR_THEME;
    my @match = grep { $theme eq $_ } $self->color_themes;
    if (@match) {
        return $theme;
    }
    else {
        return DEFAULT_THEME;
    }
}

sub as_latex {
    my $self = shift;
    my $color_theme = $self->color_theme;
    my $theme = $self->theme;
    my $string = "\\usetheme{${theme}}\n\\usecolortheme{${color_theme}}\n";
    return $string;
}

1;

__END__
