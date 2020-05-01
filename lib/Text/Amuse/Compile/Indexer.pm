package Text::Amuse::Compile::Indexer;

use strict;
use warnings;
use Moo;
use Types::Standard qw/Str ArrayRef/;

has latex_body => (is => 'ro', required => 1, isa => Str);
has index_specs => (is => 'ro', required => 1, isa => ArrayRef[Str]);

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
    my @lines = split(/\n/, $self->latex_body);
    return join("\n", @lines);
}

1;
