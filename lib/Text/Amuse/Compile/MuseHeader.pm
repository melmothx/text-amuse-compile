package Text::Amuse::Compile::MuseHeader;

use Moo;
use Types::Standard qw/HashRef Bool Str/;

=head1 NAME

Text::Amuse::Compile::MuseHeader - Module to parse muse metadata

=head1 DESCRIPTION

This class is still a work in progress.

=head1 METHODS

=head2 new(\%header)

Constructor. It accepts only one mandatory argument with the output of
muse_fast_scan_header (an hashref).

=head2 wants_slides

Return true if slides are needed. False if C<#slides> is not present
or "no" or "false".

=head2 header

The cleaned and lowercased header. Directives with underscores are
ignored.

=head2 language

Defaults to en if not present.

=head1 INTERNALS

=head2 BUILDARGS

Moo-ifies the constructor.

=cut

sub BUILDARGS {
    my ($class, $hash) = @_;
    if ($hash) {
        die "Argument must be an hashref" unless ref($hash) eq 'HASH';
    }
    else {
        die "Missing argument";
    }
    my $directives = { %$hash };
    my %lowered;
  DIRECTIVE:
    foreach my $k (keys %$directives) {
        if ($k =~ m/_/) {
            warn "Ignoring $k directive with underscore\n";
            next DIRECTIVE;
        }
        my $lck = lc($k);
        if (exists $lowered{$lck}) {
            warn "Overwriting $lck, directives are case insensitive!\n";
        }
        $lowered{$lck} = $directives->{$k};
    }

    return { header => { %lowered } };
}

has header => (is => 'ro', isa => HashRef[Str]);

has language => (is => 'lazy', isa => Str);

sub _build_language {
    my $self = shift;
    my $lang = 'en';
    # language treatment
    if (my $lang_orig = $self->header->{lang}) {
        if ($lang_orig =~ m/([a-z]{2,3})/) {
            $lang = $1;
        }
        else {
            warn qq[Garbage $lang_orig found in #lang, using "en" instead\n];
        }
    }
    else {
        warn "No language found, assuming english\n";
    }
    return $lang;
}

has wants_slides => (is => 'lazy', isa => Bool);

sub _build_wants_slides {
    my $self = shift;
    my $bool = 0;
    if (my $slides = $self->header->{slides}) {
        if (!$slides or $slides =~ /^\s*(no|false)\s*$/si) {
            $bool = 0;
        }
        else {
            $bool = 1;
        }
    }
    return $bool;
}

has is_deleted => (is => 'lazy', isa => Bool);

sub _build_is_deleted {
    return !!shift->header->{deleted};
}

1;
