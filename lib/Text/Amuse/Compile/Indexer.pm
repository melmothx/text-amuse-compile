package Text::Amuse::Compile::Indexer;

use strict;
use warnings;
use Moo;
use Types::Standard qw/Str ArrayRef Object/;
use Data::Dumper;
use Text::Amuse::Compile::Indexer::Specification;
use Text::Amuse::Functions qw/muse_format_line/;

has latex_body => (is => 'ro', required => 1, isa => Str);
has index_specs => (is => 'ro', required => 1, isa => ArrayRef[Str]);
has specifications => (is => 'lazy', isa => ArrayRef[Object]);
has language_code => (is => 'ro');

sub _build_specifications {
    my $self = shift;
    my @specs;
    my $lang = $self->language_code;
    my $escape = sub {
        return muse_format_line(ltx => $_[0], $lang);
    };
    foreach my $str (@{$self->index_specs}) {
        my ($first, @lines) = split(/\n+/, $str);
        if ($first =~ m/^INDEX ([a-z]+): (.+)/) {
            my ($name, $label) = ($1, $2);
            my @patterns;
            # remove the comments and the white space
            foreach my $str (@lines) {
                $str =~ s/\A\s*//g;
                $str =~ s/\s*\z//g;
                push @patterns, $escape->($str) if $str;
            }
            push @specs, Text::Amuse::Compile::Indexer::Specification->new(
                                                                           index_name => $escape->($name),
                                                                           index_label => $escape->($label),
                                                                           patterns => \@patterns,
                                                                          );
        }
        else {
            die "Invalid index specification $first, expecting INDEX <name>: <label>";
        }
    }
    return \@specs;
}

sub indexed_tex_body {
    my $self = shift;
    if (@{$self->index_specs}) {
        return $self->interpolate_indexes;
    }
    else {
        return $self->latex_body;
    }
}

sub interpolate_indexes {
    my $self = shift;
    my $full_body = $self->latex_body;
    # remove the index themself
    $full_body =~ s/\\begin\{comment\}
                    \s*
                    INDEX
                    .*?
                    \\end\{comment\}//gsx;

    my @lines = split(/\n/, $full_body);
    my @outlines;
  LINE:
    foreach my $l (@lines) {
        # we index the inline comments as well, so we can index
        # what we want, where we want.
        my $is_comment = $l =~ m/^%/;
        my @prepend;
        my @out;
        my @words = split(/\b/, $l);
        my $last_word = $#words;
        my $i = 0;
      WORD:
        while ($i <= $last_word) {
          SPEC:
            foreach my $spec (@{$self->specifications}) {
                my $index_name = $spec->index_name;
              MATCH:
                foreach my $m (@{ $spec->matches }) {
                    # print Dumper([\@words, $m]);
                    my @search = @{$m->{tokens}};
                    my $add_to_index = $#search;
                    next MATCH unless @search;
                    my $last_i = $i + $add_to_index;
                    if ($last_word >= $last_i) {
                        if (join('', @search) eq
                            join('', @words[$i..$last_i])) {
                            $spec->total_found($spec->total_found + 1);
                            # print join("", @search) . " at " . join("", @words[$i..$last_i]) . "\n";
                            my $index_str = "\\index[$index_name]{$m->{label}}";
                            if ($is_comment) {
                                push @prepend, $index_str;
                            }
                            else {
                                push @out, $index_str;
                            }
                            push @out, @words[ $i .. $last_i];
                            # advance
                            $i = $last_i + 1;
                            next WORD;
                        }
                    }
                }
            }
            push @out, $words[$i];
            $i++;
        }
        if (@prepend) {
            push @prepend, "\n";
        }
        push @outlines, join('', @prepend, @out);
    }
    return join("\n", @outlines);
}

1;
