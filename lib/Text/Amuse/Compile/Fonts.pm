package Text::Amuse::Compile::Fonts;
use utf8;
use strict;
use warnings;
use Types::Standard qw/ArrayRef InstanceOf/
use JSON::MaybeXS qw/decode_json/;
use Text::Amuse::Compile::Fonts::Family;
use Moo;

has list => (is => ArrayRef[InstanceOf['Text::Amuse::Compile::Fonts::Family']]);

sub BUILDARGS {
    my ($class, $file) = @_;
}

1;
