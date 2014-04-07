#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Getopt::Long;
use Data::Dumper;
use Text::Amuse::Compile;
use File::Path qw/mkpath/;
use File::Spec::Functions qw/catfile/;
use Pod::Usage;
use File::Slurp qw/append_file/;
use Encode;

binmode STDOUT, ':encoding(utf-8)';
binmode STDERR, ':encoding(utf-8)';

my %options;
GetOptions (\%options,
            qw/epub
               html
               bare-html
               a4-pdf
               lt-pdf
               tex
               pdf
               zip
               ttdir=s
               output-templates
               log=s
               extra=s%
               no-cleanup
               recursive=s
               dry-run
               help/);

if ($options{help}) {
    pod2usage("Using Text::Amuse::Compile version " .
              $Text::Amuse::Compile::VERSION . "\n");
    exit 2;
}

=encoding utf8

=head1 NAME

muse-compile.pl -- format your muse document using Text::Amuse

=head1 SYNOPSIS

  muse-compile.pl [ options ] file1.muse [ file2.muse  , .... ]

This program uses Text::Amuse to produce usable output in HTML, EPUB,
LaTeX and PDF format.

By default, all formats will be generated. You can specify which
format you want using one or more of the following options:

=over 4

=item --html

Full HTML output.

=item --epub

Full EPUB output.

=item --bare-html

HTML body alone (wrapped in a C<div> tag)

=item --tex

LaTeX output

=item --zip

Pack the tex, the source and the html with the attachments in a zip
file.

=item --pdf

PDF output.

=item --a4-pdf

PDF imposed on A4 paper, with a variable signature in the range of 40-80

=item --lt-pdf

As above, but on Letter paper.

=item --ttdir

The directory with the templates.

=item --output-templates

Option to populated the above directory with the built-in templates.

=item --log <file>

A file where we can append the report failures

=item --no-cleanup

Prevent the removing of the status file. This is turned on if you use
--recursive, to prevent multiple runs to compile everything again.

=item --extra key:value

This option can be repeated at will. The key/value pairs will be
passed to every template we process, regardless of the type, even if
only the built-in LaTeX template support them.

The input is assumed to be UTF-8 (if you pass non-ascii characters)

Example:

  muse-compile --extra site=http://anarhija.net \
               --extra papersize=a6 --extra division=15 --extra twoside=true \
               --extra bcor=10mm --extra mainfont="Charis SIL" \
               --extra sitename="Testsite" \
               --extra siteslogan="Anticopyright" \
               --extra logo=mylogo file.muse

Keep in mind that in this case C<mylogo> has to be or an absolute
filename (not reccomended, because the full path will remain in the
.tex source), or a basename (even without extension) which can be
found by C<kpsewhich>.

=item --recursive <directory>

Using this options, the target directory and a recursive compiling is
started, finding all the .muse files without a newer status file, and
compiling them accordingly to the options.

No target files can be specified.

=item --dry-run

For recursive compile, you can pass this option to just list the files
which would be compiled.

=back

=cut

my %args;

my $output_templates = delete $options{'output-templates'};
my $logfile = delete $options{log};

if ($options{extra}) {
    my $extras = delete $options{extra};
    foreach my $k (keys %$extras) {
        $extras->{$k} = decode('utf-8', $extras->{$k});
    }
    $args{extra} = $extras;
}

# manage some dependencies

if ($options{zip}) {
    $options{tex} = $options{html} = 1;
}

if ($options{pdf}) {
    $options{tex} = 1;
}

my $recursive  = delete $options{recursive};
my $cleanup = 1;
my $dry_run = delete $options{'dry-run'};

if ($dry_run && !$recursive) {
    die "dry-run is supported only for recursive compile\n";
}


if (delete($options{'no-cleanup'}) || $recursive) {
    $cleanup = 0;
}

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

my $compiler = Text::Amuse::Compile->new(%args, cleanup => $cleanup);

if ($logfile) {
    if ($logfile !~ m/\.log$/) {
        warn "Appending .log to $logfile\n";
    }
    print "Using $logfile to report errors\n";

    $compiler->report_failure_sub(sub {
                                      my @errors = @_;
                                      append_file($logfile, @errors);
                                  });
}

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

if ($recursive) {
    die "Too many arguments passed with compile!" if @ARGV;
    die "$recursive is not a directory" unless -d $recursive;
    print "Starting recursive compilation against $recursive\n";
    my @results;
    if ($dry_run) {
        @results = $compiler->find_new_muse_files($recursive);
        print "[dry-run mode, nothing will be done]\n";
    }
    else {
        @results = $compiler->recursive_compile($recursive);
    }
    if (@results) {
        print "Found and compiled the following files:\n"
          . join("\n", @results) . "\n";
    }
    else {
        print "Nothing to do\n";
    }
}
else {
    $compiler->compile(@ARGV);
}

if ($compiler->errors) {
    $logfile ||= "above";
    die "Compilation finished with errors, see $logfile!\n";
}
