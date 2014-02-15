package Text::Amuse::Compile;

use 5.010001;
use strict;
use warnings FATAL => 'all';

use File::Basename;
use File::Temp;

use Text::Amuse::Compile::Templates;
use Text::Amuse::Compile::File;
use Cwd;


=head1 NAME

Text::Amuse::Compile - Helper for Text::Amuse

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

    use Text::Amuse::Compile;
    my $compiler = Text::Amuse::Compile->new;
    $compiler->compile($file1, $file2, $file3)

=head1 SUBROUTINES/METHODS

=head2 new(ttdir => '.', pdf => 1, ...);

Constructor. It will accept the following options

Format options (by default all of them are activated);

=over 4

=item pdf

Plain PDF without any imposition

=item pdfa4

PDF imposed on A4 paper

=item pdflt

PDF imposed on Letter paper

=item html

Full HTML output

=item epub

The EPUB

=item bare

The bare HTML, non <head>

=back

Template directory:

=over 4

=item ttdir

The directory where to look for templates, named as format.tt

=back

=cut

sub new {
    my ($class, @args) = @_;
    # available options by default
    die "Wrong usage" if @args % 2;

    my $self = {
                pdf   => 1,
                pdfa4 => 1,
                pdflt => 1,
                epub  => 1,
                html  => 1,
                bare  => 1,
               };

    my %params = @args;

    $self->{templates} =
      Text::Amuse::Compile::Templates->new(ttdir => delete($params{ttdir}));

    # options passed, null out and reparse the params
    if (%params) {
        foreach my $k (qw/pdf pdfa4 pdflt epub html bare/) {
            $self->{$k} = delete $params{$k};
        }

        die "Unrecognized options: " . join(", ", keys %params)
          if %params;
    }

    bless $self, $class;
}

sub pdf {
    return shift->{pdf};
}
sub pdfa4 {
    return shift->{pdfa4};
}
sub pdflt {
    return shift->{pdflt};
}
sub epub {
    return shift->{pdflt};
}
sub html {
    return shift->{html};
}
sub bare {
    return shift->{bare};
}

sub templates {
    return shift->{templates};
}

=head1 ACCESSORS

=head2 templates

The L<Text::Amuse::Compile::Templates> object, which will provide the
templates string references.

=cut

=head1 METHODS

=head2 version

Report version information

=cut

sub version {
    my $self = shift;
    my $musev = $Text::Amuse::VERSION;
    my $selfv = $VERSION;
    my $pdfv  = $PDF::Imposition::VERSION;
    return "Using Text::Amuse $musev, Text::Amuse::Compiler $selfv, " .
      "PDF::Imposition $pdfv\n";
}

=head2 compile($file1, $file2, ...);

=cut

sub compile {
    my ($self, @files) = @_;
    foreach my $file (@files) {
        # fork here before we change dir
        my $pid = open(my $kid, "-|");
        defined $pid or die "can't fork $!";
        if ($pid) {
            while (<$kid>) {
                print;
                # push @report, $_;
            }
            close $kid or warn "Failure to compile $file $!\n";
            # print getcwd . "\n";
        }
        else {
            open(STDERR, ">&STDOUT") or die "can't dup stdout: $!";
            $self->_compile_file($file);
            exit 0;
        }
    }
}

sub _compile_file {
    # this is called from a fork, so print to STDOUT to report.
    # STDERR is duped to STDOUT so warn/print/die is the same.
    my ($self, $file) = @_;

    # parse the filename and chdir there.
    my ($name, $path, $suffix) = fileparse($file, '.muse', '.txt');

    if ($path) {
        chdir $path or die "Cannot chdir into $path\n";
    };

    # first and foremost, see if we can deal with it.
    my $filename = $name . $suffix;

    my %args = (
                name => $name,
                suffix => $suffix,
                templates => $self->templates,
               );

    my $muse = Text::Amuse::Compile::File->new(%args);
    die "Couldn't acquire lock on $name$suffix!" unless $muse->mark_as_open;

}



=head1 AUTHOR

Marco Pessotto, C<< <melmothx at gmail.com> >>

=head1 BUGS

Please mail the author and provide a minimal example to add to the
test suite.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::Amuse::Compile

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1; # End of Text::Amuse::Compile
