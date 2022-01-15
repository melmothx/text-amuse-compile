package Text::Amuse::Compile::Fonts::Selected;
use utf8;
use strict;
use warnings;
use Moo;
use Types::Standard qw/InstanceOf Enum/;

=head1 NAME

Text::Amuse::Compile::Fonts::Selected - simple class to hold selected fonts

=head1 ACCESSORS

All are read-only instances of L<Text::Amuse::Compile::Fonts::Family>.

=head2 main

=head2 sans

=head2 mono

=head2 size

=head1 METHODS

=head2 compose_polyglossia_fontspec_stanza(lang => 'english', others => [qw/russian farsi/], bidi => 1)

The place to produce this stanza is a bit weird, but fontspec and
polyglossia are tighly coupled.

Named arguments:

=over 4

=item lang

The main language.

=item others

The other languages as arrayref

=item bidi

Boolean if bidirectional

=item is_slide

Boolean if for beamer

=back

=head2 families

Return an arrayref with the C<mono>, C<sans> and C<main> objects.

=cut

has mono => (is => 'ro', required => 1, isa => InstanceOf['Text::Amuse::Compile::Fonts::Family']);
has sans => (is => 'ro', required => 1, isa => InstanceOf['Text::Amuse::Compile::Fonts::Family']);
has main => (is => 'ro', required => 1, isa => InstanceOf['Text::Amuse::Compile::Fonts::Family']);
has size => (is => 'ro', default => sub { 10 }, isa => Enum[9..14]);

sub compose_polyglossia_fontspec_stanza {
    my ($self, %args) = @_;

    my @out;

    push @out, <<'STANDARD';
\usepackage{microtype}
\usepackage{graphicx}
\usepackage{alltt}
\usepackage{verbatim}
\usepackage[shortlabels]{enumitem}
\usepackage{tabularx}
\usepackage[normalem]{ulem}
\def\hsout{\bgroup \ULdepth=-.55ex \ULset}
% https://tex.stackexchange.com/questions/22410/strikethrough-in-section-title
% Unclear if \protect \hsout is needed. Doesn't looks so
\DeclareRobustCommand{\sout}[1]{\texorpdfstring{\hsout{#1}}{#1}}
\usepackage{wrapfig}

% avoid breakage on multiple <br><br> and avoid the next [] to be eaten
\newcommand*{\forcelinebreak}{\strut\\*{}}

\newcommand*{\hairline}{%
  \bigskip%
  \noindent \hrulefill%
  \bigskip%
}

% reverse indentation for biblio and play

\newenvironment*{amusebiblio}{
  \leftskip=\parindent
  \parindent=-\parindent
  \smallskip
  \indent
}{\smallskip}

\newenvironment*{amuseplay}{
  \leftskip=\parindent
  \parindent=-\parindent
  \smallskip
  \indent
}{\smallskip}

\newcommand*{\Slash}{\slash\hspace{0pt}}

STANDARD

    unless($args{is_slide}) {
        push @out, <<'HYPERREF';
% http://tex.stackexchange.com/questions/3033/forcing-linebreaks-in-url
\PassOptionsToPackage{hyphens}{url}\usepackage[hyperfootnotes=false,hidelinks,breaklinks=true]{hyperref}
\usepackage{bookmark}
HYPERREF
    }
    my %use_polyglossia = (
                           afrikaans       => 1,
                           albanian        => 1,
                           amharic         => 1,
                           arabic          => 1,
                           armenian        => 1,
                           asturian        => 1,
                           basque          => 1,
                           belarusian      => 1,
                           bengali         => 1,
                           bosnian         => 1,
                           breton          => 1,
                           bulgarian       => 1,
                           catalan         => 1,
                           coptic          => 1,
                           croatian        => 1,
                           czech           => 1,
                           danish          => 1,
                           divehi          => 1,
                           dutch           => 1,
                           english         => 1,
                           esperanto       => 1,
                           estonian        => 1,
                           finnish         => 1,
                           french          => 1,
                           friulian        => 1,
                           gaelic          => 1,
                           galician        => 1,
                           georgian        => 1,
                           german          => 1,
                           greek           => 1,
                           hebrew          => 1,
                           hindi           => 1,
                           hungarian       => 1,
                           magyar          => 1,
                           icelandic       => 1,
                           interlingua     => 1,
                           italian         => 1,
                           japanese        => 0,
                           kannada         => 1,
                           khmer           => 1,
                           korean          => 0,
                           kurdish         => 1,
                           lao             => 1,
                           latin           => 1,
                           latvian         => 1,
                           lithuanian      => 1,
                           macedonian      => 1,
                           malay           => 1,
                           malayalam       => 1,
                           marathi         => 1,
                           mongolian       => 1,
                           nko             => 1,
                           norwegian       => 1,
                           norsk           => 1,
                           occitan         => 1,
                           persian         => 1,
                           farsi           => 1,
                           piedmontese     => 1,
                           polish          => 1,
                           portuguese      => 1,
                           portuges        => 1,
                           romanian        => 1,
                           romansh         => 1,
                           russian         => 1,
                           sami            => 1,
                           sanskrit        => 1,
                           serbian         => 1,
                           slovak          => 1,
                           slovenian       => 1,
                           sorbian         => 1,
                           spanish         => 1,
                           swedish         => 1,
                           syriac          => 1,
                           tamil           => 1,
                           telugu          => 1,
                           thai            => 0,
                           tibetan         => 1,
                           turkish         => 1,
                           turkmen         => 1,
                           ukrainian       => 1,
                           urdu            => 1,
                           uyghur          => 1,
                           vietnamese      => 1,
                           welsh           => 1,
                          );
    my %cjk = (
               japanese => 1,
               korean => 1,
               chinese => 1,
              );

    # for our purposes it's the same.
    my %aliases = (
                   serbian => 'croatian',
                  );

    my $lang = $args{lang} || 'english';
    if (my $aliased = $aliases{$lang}) {
        $lang = $aliased;
    }

    push @out, "\\usepackage{fontspec}";


#  right now we’re using Song for sans and Kai for sf
# https://github.com/adobe-fonts/source-han-serif/releases/download/2.000R/SourceHanSerifCN.zip
# https://github.com/adobe-fonts/source-han-sans/releases/download/2.004R/SourceHanSansCN.zip

    if ($cjk{$lang}) {
        # these will die with luatex. Too bad.
        push @out, "\\usepackage[$lang, provide=*]{babel}";
        push @out, "\\usepackage{xeCJK}";
        foreach my $slot (qw/main mono sans/) {
            # original lang
            push @out, "\\setCJK${slot}font" . $self->_fontspec_args($slot => $lang);
        }
        my %fallback = (
                        main => "DejaVu Serif",
                        sans => "DejaVu Sans",
                        mono => "DejaVu Sans Mono",
                       );
        foreach my $slot (sort keys %fallback) {
            push @out, "\\set${slot}font{" . $fallback{$slot} . "}";
        }
    }
    elsif (!$use_polyglossia{$lang}) {
        # for these languages at the moment we can't combine langs.
        push @out, "\\usepackage[$lang, provide=*]{babel}";
        foreach my $slot (qw/main mono sans/) {
            # original lang
            push @out, "\\set${slot}font" . $self->_fontspec_args($slot => $lang);
        }
    }
    else {
        push @out, "\\usepackage{polyglossia}";
        my %langs = ($lang => 1, map { $aliases{$_} || $_  => 1 } @{ $args{others} || [] } );
        push @out, "\\setmainlanguage{$lang}";
        if (my @other_langs = sort grep { $_ ne $lang } keys %langs) {
            push @out, sprintf('\\setotherlanguages{%s}', join(",", @other_langs));
        }

        foreach my $slot (qw/main mono sans/) {
            # original lang
            push @out, "\\set${slot}font" . $self->_fontspec_args($slot => $lang);
        }

        foreach my $l (sort keys %langs) {
            push @out, "\\newfontfamily\\${l}font" . $self->_fontspec_args(main => $l);
        }

        if ($args{bidi}) {
            push @out, '\\usepackage{bidi}';
        }
    }
    push @out, '';
    return join("\n", @out);
}

sub _shape_mapping {
    return +{
             bold => 'BoldFont',
             italic => 'ItalicFont',
             bolditalic => 'BoldItalicFont',
            };
}

has definitions => (is => 'lazy');

sub _build_definitions {
    my $self = shift;
    my %definitions;
    foreach my $slot (qw/mono sans main/) {
        my $font = $self->$slot;
        my %definition = (
                          name => $font->name,
                          attr => { $slot eq 'main' ? () : (Scale => 'MatchLowercase' ) },
                         );
        if ($font->has_files) {
            $definition{name} = $font->regular->basename_and_ext;

            my $dirname = $font->regular->dirname;

            # if $dirname have spaces, etc., skip it, and let's hope
            # tex will find them anyway.
            if ($font->regular->dirname  =~ m/\A([A-Za-z0-9\.\/_-]+)\z/) {
                $definition{attr}{Path} = $1;
            }
            else {
                warn $font->regular->dirname . " does not look like a path which can be embedded." .
                  " Please make sure the fonts are installed in a standard TeX location\n";
            }

            my %map = %{$self->_shape_mapping};
            foreach my $method (keys %map) {
                $definition{attr}{$map{$method}} = $font->$method->basename_and_ext;
            }
        }
        $definitions{$slot} = \%definition;
    }
    return \%definitions;
}

sub _fontspec_args {
    my ($self, $slot, $language) = @_;
    $language ||= 'english';
    my %scripts = (
                   macedonian => 'Cyrillic',
                   russian    => 'Cyrillic',
                   farsi      => 'Arabic',
                   arabic     => 'Arabic',
                   hebrew     => 'Hebrew',
                   greek      => 'Greek',
                  );
    my $def = $self->definitions->{$slot} or die "bad usage, can't find $slot";
    my $script = $scripts{$language} || 'Latin';
    my @list = ("Script=$script", "Ligatures=TeX");
    my @shapes = sort values %{ $self->_shape_mapping };
    foreach my $att (qw/Scale Path/, @shapes) {
        if (my $v = $def->{attr}->{$att}) {
            push @list, "$att=$v";
        }
    }
    return sprintf('{%s}[%s]', $def->{name}, join(",%\n ", @list));
}

sub families {
    my $self = shift;
    return [ $self->main, $self->mono, $self->sans ];
}

1;
