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

=cut

sub new {
    my ($class, %args) = @_;
    my $files = delete $args{files};
    die "Missing files" unless $files && @$files;
    my @docs;
    foreach my $file (@$files) {
        push @docs, Text::Amuse->new(file => $file);
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
                tt      => Template->new,
                templates => Text::Amuse::Compile::Templates->new,
               };
    bless $self, $class;
}

=head2 as_latex

Return the latex body

=cut

sub as_latex {
    my $self = shift;
    my @out;
    foreach my $doc ($self->docs) {
        my $output = '';
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

