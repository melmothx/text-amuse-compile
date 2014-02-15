#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Getopt::Long;
use Data::Dumper;
use Text::Amuse::Compile;


binmode STDOUT, ':encoding(utf-8)';
binmode STDERR, ':encoding(utf-8)';

my %options;
GetOptions (\%options,
            'epub',
            'html',
            'bare-html',
            'a4-pdf',
            'lt-pdf',
            'tex',
            'pdf',
           );


my %args;
foreach my $k (keys %options) {
    my $newk = $k;
    $newk =~ s/-/_/g;
    $args{$newk} = $options{$k};
}


my $compiler = Text::Amuse::Compile->new(%args);

print $compiler->version;
$compiler->compile(@ARGV);
