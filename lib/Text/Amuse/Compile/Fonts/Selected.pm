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

=cut

has mono => (is => 'ro', required => 1, isa => InstanceOf['Text::Amuse::Compile::Fonts::Family']);
has sans => (is => 'ro', required => 1, isa => InstanceOf['Text::Amuse::Compile::Fonts::Family']);
has main => (is => 'ro', required => 1, isa => InstanceOf['Text::Amuse::Compile::Fonts::Family']);
has size => (is => 'ro', default => sub { 10 }, isa => Enum[9..14]);

sub compose_polyglossia_fontspec_stanza {
    my ($self, %args) = @_;
    my @others = @{ $args{others} || [] };

    my @out = ("\\usepackage{fontspec}");
    push @out, "\\usepackage{polyglossia}";

    # main language
    my $orig_lang = $args{lang} || 'english';

    my %aliases = (
                   macedonian => 'russian',
                   serbian => 'croatian',
                  );
    my $lang = $aliases{$orig_lang} || $orig_lang;
    push @out, "\\setmainlanguage{$lang}";

    foreach my $slot (qw/main mono sans/) {
        # original lang
        push @out, "\\set${slot}font" . $self->_fontspec_args($slot => $lang);
    }

    my %langs = ($lang => 1, map { $aliases{$_} || $_  => 1 } @others );
    foreach my $l (keys %langs) {
        push @out, "\\newfontfamily\\${l}font" . $self->_fontspec_args(main => $l);
    }

    delete $langs{$lang};
    if (my @other_langs = sort keys %langs) {
        push @out, sprintf('\\setotherlanguages{%s}', join(",", @other_langs));
    }

    # special cases.
    my %toc_names = (
                     macedonian => 'Содржина',
                    );

    if (my $toc_name = $toc_names{$orig_lang}) {
        push @out, sprintf('\\renewcaptionname{%s}{\\contentsname}{%s}',
                           $lang, $toc_names{$orig_lang});
    }
    if ($args{bidi}) {
        push @out, '\\usepackage{bidi}';
    }
    return join("\n", @out);
}

sub shape_mapping {
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

            my %map = %{$self->shape_mapping};
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
                  );
    my $def = $self->definitions->{$slot} or die "bad usage, can't find $slot";
    my $script = $scripts{$language} || 'Latin';
    my @list = ("Script=$script");
    my @shapes = sort values %{ $self->shape_mapping };
    foreach my $att (qw/Scale Path/, @shapes) {
        if (my $v = $def->{attr}->{$att}) {
            push @list, "$att=$v";
        }
    }
    return sprintf('{%s}[%s]', $def->{name}, join(",%\n ", @list));
}

1;
