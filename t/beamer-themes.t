#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 8;
use_ok('Text::Amuse::Compile::BeamerThemes');

my $themes = Text::Amuse::Compile::BeamerThemes->new(theme => 'radalkjsdf',
                                                     color_theme => 'kalsdjf');

is ($themes->theme, "default", "invalid theme becomes default");
is ($themes->color_theme, "default", "invalid color theme becomes default");

my @themes = $themes->themes;
my @color_themes = $themes->color_themes;
ok(@themes > 5, "themes returns the themes");
ok(@color_themes > 5, "color_themes returns the color themes");
  
$themes = Text::Amuse::Compile::BeamerThemes->new(theme => 'JuanLesPins',
                                                  color_theme => 'rose');

is ($themes->theme, "JuanLesPins", "Theme is valid");
is ($themes->color_theme, "rose", "Color theme is valid");
is ($themes->as_latex, "\\usetheme{JuanLesPins}\n\\usecolortheme{rose}\n", "latex code ok");

