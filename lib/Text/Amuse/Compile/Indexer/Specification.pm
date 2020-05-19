package Text::Amuse::Compile::Indexer::Specification;

use strict;
use warnings;
use Moo;
use Types::Standard qw/Str ArrayRef StrMatch HashRef/;
use Data::Dumper;


has index_name => (is => 'ro',
                   required => 1,
                   isa => StrMatch[qr{\A[a-z]+\z}],
                  );

has index_label => (is => 'ro',
                   required => 1,
                   isa => Str,
                  );

has patterns => (is => 'ro',
                 required => 1,
                 isa => ArrayRef[Str]);

has matches => (is => 'lazy', isa => ArrayRef[HashRef]);

has total_found => (is => 'rw', default => sub { 0 });

sub _build_matches {
    my $self = shift;
    my @patterns = @{$self->patterns};
    my @pairs;
    foreach my $str (@patterns) {
        my ($match, $label) = split(/\s*:\s*/, $str, 2);
        # default to label
        $label ||= $match;
        push @pairs, {
                      match => $match,
                      tokens => [ explode_line($match) ],
                      label => $label,
                     };
    }
    return [ sort { @{$b->{tokens}} <=> @{$a->{tokens}} or $a->{match} cmp $b->{match} } @pairs ];
}

sub explode_line {
    my $l = shift;
    return grep { length($_) } map { split(/(\s+)/, $_) } split(/\b/, $l);
}

1;
