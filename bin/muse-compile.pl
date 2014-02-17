#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Getopt::Long;
use Data::Dumper;
use Text::Amuse::Compile;
use File::Path qw/mkpath/;
use File::Spec::Functions qw/catfile/;

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
            'ttdir=s',
            'output-templates',
           );


my %args;

my $output_templates = delete $options{'output-templates'};

foreach my $k (keys %options) {
    my $newk = $k;
    $newk =~ s/-/_/g;
    $args{$newk} = $options{$k};
}

if ($output_templates and exists $options{ttdir}) {
    if (! -d $options{ttdir}) {
        mkpath($options{ttdir}) or die "Couldn't create $options{ttdir} $!";
    }
}

my $compiler = Text::Amuse::Compile->new(%args);

print $compiler->version;

if ($output_templates) {
    my $viewdir = $compiler->templates->ttdir;
    if (defined $viewdir) {
        foreach my $template ($compiler->templates->names) {
            my $target = catfile($viewdir, $template . '.tt');
            if (-f $target) {
                warn "Refusing to overwrite $target\n";
            }
            else {
                warn "Creating $target\n";
                open (my $fh, '>:encoding(utf-8)', $target)
                  or die "Couldn't open $target $!";
                print $fh ${ $compiler->templates->$template };
                close $fh or die "Couldn't close $target $!";
            }
        }
    }
    else {
        warn "You didn't specify a directory for the templates! Ignoring\n";
    }
}

$compiler->compile(@ARGV);
