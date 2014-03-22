package Text::Amuse::Compile::Merged;

use 5.010001;
use strict;
use warnings;
use utf8;
use Text::Amuse;
use Text::Amuse::Functions qw/muse_format_line/;
use Text::Amuse::Compile::Templates;
use Template;

=encoding utf8

=head1 NAME

Text::Amuse::Compile::Merged - Merging muse files together.

=head2 

=head1 SYNOPSIS

  my $doc = Text::Amuse::Compile::Merged->new( files => ([ file1, file2, ..]);
  $doc->as_html;
  $doc->as_splat_html;
  $doc->as_latex;
  $doc->header_as_html;
  $doc->header_as_latex;

This module emulates a L<Text::Amuse> document merging files together,
and so it can be passed to Text::Amuse::Compile::File and have the
thing produced seemlessly.

=head1 METHODS

=head2 new(files => [qw/file1 file2/], title => 'blabl', ...)

The constructor requires the C<files> argument. Any other option is
considered part of the header of this virtual L<Text::Amuse> document.

On creation, the module will store in the object a list of
L<Text::Amuse> objects, which will be merged together.

When asking for header_as_html, you get the constructor options (save
for the C<files> option) properly formatted.

The headers of the individual merged files go into the body.

The first file determine the main language of the whole document.

Anyway, if it's a multilanguage text, hyphenation is supposed to
switch properly.

=cut

sub new {
    my ($class, %args) = @_;
    my $files = delete $args{files};
    die "Missing files" unless $files && @$files;
    my @docs;
    my (%languages, %language_codes);
    my ($main_lang, $main_lang_code);
    foreach my $file (@$files) {
        my $doc = Text::Amuse->new(file => $file);
        push @docs, $doc;

        my $current_lang_code = $doc->language_code;
        my $current_lang      = $doc->language;

        # the first file determine the main language
        $main_lang      ||= $current_lang;
        $main_lang_code ||= $current_lang_code;

        if ($main_lang ne $current_lang) {
            $languages{$current_lang}++;
            $language_codes{$current_lang_code}++;
        }
    }
    my (%html_headers, %latex_headers);
    foreach my $k (keys %args) {
        $html_headers{$k} = muse_format_line(html => $args{$k});
        $latex_headers{$k} = muse_format_line(ltx => $args{$k});
    }

    my $self = {
                headers => { %args },
                html_headers  => \%html_headers,
                latex_headers => \%latex_headers,
                files   => [ @$files ],
                docs    => \@docs,
                language      => $main_lang,
                language_code => $main_lang_code,
                other_languages => \%languages,
                other_language_codes => \%language_codes,
                tt      => Template->new,
                templates => Text::Amuse::Compile::Templates->new,
               };
    bless $self, $class;
}

=head2 language

Return the english name of the main language

=head2 language_code

Return the code of the main language

=head2 other_languages

If it's a multilingual merged text, return an arrayref of the other
language names, undef otherwise.

=head2 other_language_codes

If it's a multilingual merged text, return an arrayref of the other
language codes, undef otherwise.

=cut

sub language {
    return shift->{language};
}

sub language_code {
    return shift->{language_code},
}

sub other_language_codes {
    my $self = shift;
    my %langs = %{ $self->{other_language_codes} };
    if (%langs) {
        return [ keys %langs ];
    }
    else {
        return;
    }
}

sub other_languages {
    my $self = shift;
    my %langs = %{ $self->{other_languages} };
    if (%langs) {
        return [ keys %langs ];
    }
    else {
        return;
    }
}

=head2 as_latex

Return the latex body

=cut

sub as_latex {
    my $self = shift;
    my @out;
    my $current_language = $self->language;
    my %lang_aliases = (
                        macedonian => 'russian',
                        serbian    => 'croatian',
                       );
    foreach my $doc ($self->docs) {
        my $output = "\n\n";

        my $doc_language = $doc->language;
        if (my $alias = $lang_aliases{$doc_language}) {
            $doc_language = $alias;
        }

        if ($doc_language ne $current_language) {
            $output = sprintf('\selectlanguage{%s}', $doc_language) . "\n\n";
            $current_language = $doc_language;
        }

        $self->tt->process($self->templates->bare_latex,
                           { doc => $doc },
                           \$output) or die $self->tt->error;
        push @out, $output;
    }
    return join("\n\n", @out, "\n");
}


=head2 wants_toc

Always returns true

=cut

sub wants_toc {
    return 1;
}

=head2 is_deleted

Always returns false

=cut

sub is_deleted {
    return 0;
}


=head2 header_as_latex

Returns an hashref with the LaTeX-formatted info (passed to the constructor).

=head2 header_as_html

Same as above, but with HTML format.

=cut

sub header_as_latex {
    return { %{ shift->{latex_headers} } };
}

sub header_as_html {
    return { %{ shift->{html_headers} } };
}


=head1 INTERNALS

=head2 docs

Accessor to the list of L<Text::Amuse> objects.

=head2 files

Accessor to the list of files.

=head3 headers

Accessor to the headers.

=head3 tt

Accessor to the L<Template> object.

=head3 templates

Accesso to the L<Text::Amuse::Compile::Templates> object.

=cut

sub docs {
    return @{ shift->{docs} };
}

sub files {
    return @{ shift->{files} };
}

sub headers {
    return %{ shift->{headers} };
}

sub tt {
    return shift->{tt};
}

sub templates {
    return shift->{templates};
}


1;

