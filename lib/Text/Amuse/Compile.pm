package Text::Amuse::Compile;

use 5.010001;
use strict;
use warnings FATAL => 'all';

use File::Basename;
use File::Temp;

use Text::Amuse::Compile::Templates;
use Text::Amuse::Compile::File;
use Text::Amuse::Compile::Merged;
use Cwd;
use IO::Pipe;

=head1 NAME

Text::Amuse::Compile - Compiler for Text::Amuse

=head1 VERSION

Version 0.11

=cut

our $VERSION = '0.11';

=head1 SYNOPSIS

    use Text::Amuse::Compile;
    my $compiler = Text::Amuse::Compile->new;
    $compiler->compile($file1, $file2, $file3)

=head1 METHODS/ACCESSORS

=head2 CONSTRUCTOR

=head3 new(ttdir => '.', pdf => 1, ...);

Constructor. It will accept the following options

Format options (by default all of them are activated);

=over 4

=item tex

LaTeX output

=item pdf

Plain PDF without any imposition

=item a4_pdf

PDF imposed on A4 paper

=item lt_pdf

PDF imposed on Letter paper

=item html

Full HTML output

=item epub

The EPUB

=item bare_html

The bare HTML, non <head>

=item zip

The zipped sources

=item extra

An hashref of key/value pairs to pass to each template in the
C<options> namespace.

=back

Template directory:

=over 4

=item ttdir

The directory where to look for templates, named as format.tt

=back

You can retrieve the value by calling them on the object.

=cut

sub new {
    my ($class, @args) = @_;
    # available options by default
    die "Wrong usage" if @args % 2;

    my $self = {
                pdf   => 1,
                a4_pdf => 1,
                lt_pdf => 1,
                epub  => 1,
                html  => 1,
                tex   => 1,
                bare_html  => 1,
                zip => 1,
               };

    my %params = @args;

    $self->{templates} =
      Text::Amuse::Compile::Templates->new(ttdir => delete($params{ttdir}));

    $self->{report_failure_sub} = delete $params{report_failure_sub};

    if (my $extraref = delete $params{extra}) {
        $self->{extra} = { %$extraref };
    }

    # options passed, null out and reparse the params
    if (%params) {
        foreach my $k (qw/pdf a4_pdf lt_pdf epub html bare_html tex zip/) {
            $self->{$k} = delete $params{$k};
        }

        die "Unrecognized options: " . join(", ", keys %params)
          if %params;
    }

    bless $self, $class;
}

sub zip {
    return shift->{zip};
}

sub tex {
    return shift->{tex};
}
sub pdf {
    return shift->{pdf};
}
sub a4_pdf {
    return shift->{a4_pdf};
}
sub lt_pdf {
    return shift->{lt_pdf};
}
sub epub {
    return shift->{epub};
}
sub html {
    return shift->{html};
}
sub bare_html {
    return shift->{bare_html};
}

sub templates {
    return shift->{templates};
}

sub extra {
    my $self = shift;
    my $hashref = $self->{extra};
    my %out;
    # do a shallow copy before returning
    if ($hashref) {
        %out = %$hashref;
    }
    return %out;
}

=head2 METHODS

=head3 templates

The L<Text::Amuse::Compile::Templates> object, which will provide the
templates string references.

=head3 version

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

=head3 logger

Subroutine reference stored in the object when forking itself to
compile the file. The parent process has this to undef. The child
store a sub which then passes to L<Text::Amuse::Compile::File>

=cut

sub logger {
    my ($self, $sub) = @_;
    if (@_ > 1) {
        $self->{logger} = $sub;
    }
    return $self->{logger};
}

=head3 compile($file1, $file2, ...);

Main method to get the job done, passing the list of muse files. You
can inspect the errors calling C<errors>. It does produce some output.

The file may also be an hash reference. In this case, the compile will
act on a list of files and will merge them. Beware that so far only
the C<pdf> and C<tex> options will work, while the other html methods
will throw exceptions or (worse probably) produce empty files. This
will be fixed soon. This feature is marked as B<experimental> and
could change in the future.

=head4 virtual file hashref

The hash reference should have those mandatory fields:

=over 4

=item files

An B<arrayref> of filenames without extension.

=item path

A mandatory directory where to find the above files.

=back

Optional keys

=over 4

=item name

Default to virtual. This is the basename of the files which will be
produced. It's up to you to provide a sensible name we don't do any
check on that.

=item suffix

Defaults to '.muse' and you have no reason to change this.

=back

Every other key is the metadata of the new document, so usually you
want to set C<title> and optionally C<author>.

Example:

  $c->compile({
               # mandatory
               path  => File::Spec->catdir(qw/t merged-dir/),
               files => [qw/first second/],

               # recommended
               name  => 'my-new-test',
               title => 'My new shiny test',

               # optional
               subtitle => 'Another one',
               date => 'Today!',
               source => 'Text::Amuse::Compile',
              });

You can pass as many hashref you want.

=cut

sub compile {
    my ($self, @files) = @_;
    $self->reset_errors;
    foreach my $file (@files) {
        # print "pid: $$\n";
        # fork here before we change dir
        my $pipe = IO::Pipe->new;
        my $pid = fork();
        defined $pid or die "can't fork $!";
        if ($pid) {
            $pipe->reader;
            # print "$$ Kid is $pid, I'm in " . getcwd() . "\n";
            my @report;
            while (<$pipe>) {
                print '# ' . $_;
                push @report, $_;
            }
            wait;
            if ($? != 0) {
                $self->report_failure(@report,
                                      "Failure to compile $file $!\n");
            }
        }
        else {
            $pipe->writer;
            $pipe->autoflush(1);
            # here we are in another process, which will compile one
            # thing and exit.
            my $logger = sub {
                print $pipe @_ if @_;
            };
            $self->logger($logger);
            if (ref($file)) {
                $self->logger->("Working on virtual file in " . getcwd(). "\n");
                # those eval are needed if some parent eval catch the exception
                # and never reaching the exit;
                eval { $self->_compile_virtual_file($file); };
            }
            else {
                $self->logger->("Working on $file in " . getcwd() . "\n");
                eval { $self->_compile_file($file); };
            }
            print $pipe $@ if $@;
            $@ ? exit 2 : exit 0;
        }
    }
}

sub _compile_virtual_file {
    my ($self, $vfile) = @_;
    # check if the reference is good
    die "Virtual file is not a hashref" unless ref($vfile) eq 'HASH';
    my %virtual = %$vfile;
    my $files = delete $virtual{files};
    die "No file list found" unless $files && @$files;
    my $path  = delete $virtual{path};
    die "No directory path" unless $path && -d $path;
    chdir $path or die "Couldn't chdir into $path $!";
    my $suffix = delete($virtual{suffix}) || '.muse';
    my $name =   delete($virtual{name})   || 'virtual';

    my @filelist = map { $_ . $suffix } @$files;
    my $doc = Text::Amuse::Compile::Merged->new(files => \@filelist, %virtual);
    my $muse = Text::Amuse::Compile::File->new(
                                               name => $name,
                                               suffix => $suffix,
                                               templates => $self->templates,
                                               options => { $self->extra },
                                               document => $doc,
                                               logger => $self->logger,
                                              );
    $self->_muse_compile($muse);
    exit;
}


sub _compile_file {
    # this is called from a fork, so print to STDOUT to report.
    # STDERR is duped to STDOUT so warn/print/die is the same.
    my ($self, $file) = @_;

    # parse the filename and chdir there.
    my ($name, $path, $suffix) = fileparse($file, '.muse', '.txt');

    if ($path) {
        chdir $path or die "Cannot chdir into $path from " . getcwd() . "\n" ;
    };

    my $filename = $name . $suffix;

    my %args = (
                name => $name,
                suffix => $suffix,
                templates => $self->templates,
                options => { $self->extra },
                logger => $self->logger,
               );

    my $muse = Text::Amuse::Compile::File->new(%args);
    die "Couldn't acquire lock on $name$suffix!" unless $muse->mark_as_open;
    $self->_muse_compile($muse);
    # leave the thing open
    $muse->mark_as_closed;
    exit;
}

sub _muse_compile {
    my ($self, $muse) = @_;
    my @fatals;

    unless ($muse->is_deleted) {
        foreach my $method (qw/bare_html
                               html
                               epub
                               a4_pdf
                               lt_pdf
                               tex
                               zip
                               pdf/) {
            if ($self->$method) {
                eval {
                    $muse->$method;
                };
                if ($@) {
                    push @fatals, $@;
                    last;
                }
                else {
                    my $ext = $method;
                    $ext =~ s/_/./g;
                    $ext = '.' . $ext;
                    $self->logger->("Created " . $muse->name . $ext . "\n");
                }
            }
        }
    }
    if (@fatals) {
        die join(" ", @fatals);
    }
}

=head3 report_failure($message1, $message2, ...)

This method is called when the compilation of a file raises an
exception, so it's for internal usage.

It passes the arguments along to C<report_failure_sub> as a list if
you set that to a sub, otherwise it prints to the standard error.

=head3 report_failure_sub(sub { my @problems = @_ ; print @problems });

You can set the sub to be used to report problems using this accessor,
which is supposed to receive the list of messages. 

=cut

sub report_failure_sub {
    my ($self, $sub) = @_;
    if ($sub) {
        if (ref($sub) eq 'CODE') {
            $self->{report_failure_sub} = $sub;
        }
        else {
            die "First argument must be a sub!";
        }
    }
    return $self->{report_failure_sub};
}

sub report_failure {
    my ($self, @args) = @_;
    $self->add_errors(@args);
    if ($self->report_failure_sub) {
        $self->report_failure_sub->(@args);
    }
}

=head3 errors

Accessor to the catched errors. It returns a list of strings.

=head3 add_errors($error1, $error2,...)

Add an error. [Internal]

=head3 reset_errors

Reset the errors

=cut

sub add_errors {
    my ($self, @args) = @_;
    $self->{errors} ||= [];
    push @{$self->{errors}}, @args;
}

sub reset_errors {
    my $self = shift;
    $self->{errors} = [];
}

sub errors {
    my $self = shift;
    if ($self->{errors}) {
        return @{$self->{errors}};
    }
    else {
        return;
    }
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
