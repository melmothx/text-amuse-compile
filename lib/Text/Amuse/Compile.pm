package Text::Amuse::Compile;

use 5.010001;
use strict;
use warnings FATAL => 'all';

use File::Basename;
use File::Temp;
use File::Find;
use File::Spec;

use Text::Amuse::Compile::Templates;
use Text::Amuse::Compile::File;
use Text::Amuse::Compile::Merged;
use Cwd;

=head1 NAME

Text::Amuse::Compile - Compiler for Text::Amuse

=head1 VERSION

Version 0.17

=cut

our $VERSION = '0.17';

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

=item cleanup

Remove auxiliary files after compilation (.status, .ok)

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

=head3 available_methods

Return a list of all the available compilation methods

=head3 compile_methods

Return the list of the methods which are going to be used.

=cut

sub available_methods {
    return (qw/bare_html html
               epub
               a4_pdf lt_pdf
               tex zip
               pdf/);
}

sub compile_methods {
    my $self = shift;
    my @out;
    foreach my $m ($self->available_methods) {
        if ($self->$m) {
            push @out, $m;
        }
    }
    return @out;
}

sub new {
    my ($class, @args) = @_;
    # available options by default
    die "Wrong usage" if @args % 2;

    my $self = { map { $_ => 1 } $class->available_methods };

    my %params = @args;

    $self->{templates} =
      Text::Amuse::Compile::Templates->new(ttdir => delete($params{ttdir}));

    $self->{report_failure_sub} = delete $params{report_failure_sub};
    $self->{logger} = delete $params{logger};

    if (my $extraref = delete $params{extra}) {
        $self->{extra} = { %$extraref };
    }

    $self->{cleanup} = delete $params{cleanup};

    # options passed, null out and reparse the params
    if (%params) {
        foreach my $k ($class->available_methods) {
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

sub cleanup {
    return shift->{cleanup};
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

=head3 logger($sub)

Accessor/setter for the subroutine which will handle the logging.
Defaults to printing to the standard output.

=cut

sub logger {
    my ($self, $sub) = @_;
    if (@_ > 1) {
        $self->{logger} = $sub;
    }
    elsif (!$self->{logger}) {
        $self->{logger} = sub { print @_ };
    }
    return $self->{logger};
}

=head3 recursive_compile($directory)

Compile recursive a directory, comparing the timestamps of the status
file with the muse file. If the status file is newer, the file is
ignored.

Return a list of absolute path to the files processed. To infer the
success or the failure of each file look at the status file or at the
logs.

=head3 find_muse_files($directory)

Return a sorted list of files with extension .muse excluding illegal
names (including hidden files and directories).

=head3 find_new_muse_files($directory)

As above, but check the age of the status file and skip already
processed files.

=cut

sub find_muse_files {
    my ($self, $dir) = @_;
    my @files;
    die "$dir is not a dir" unless ($dir && -d $dir);
    find( sub {
              my $file = $_;
              # file only
              return unless -f $file;
              return unless $file =~ m/^[0-9a-z][0-9a-z-]+[0-9a-z]+\.muse$/;
              # exclude hidden directories
              if ($File::Find::dir =~ m/\./) {
                  my @dirs = File::Spec->splitdir($File::Find::dir);

                  # for the purpose of filtering, the leading . is harmless
                  if (@dirs && $dirs[0] && $dirs[0] eq '.') {
                      shift(@dirs);
                  }

                  my @dots = grep { m/^\./ } @dirs;
                  return if @dots;
              }
              push @files, File::Spec->rel2abs($file);
          }, $dir);
    return sort @files;
}

sub find_new_muse_files {
    my ($self, $dir) = @_;
    my @candidates = $self->find_muse_files($dir);
    my @newf;
    my $mtime = 9;
    while (@candidates) {
        my $f = shift(@candidates);
        die "I was expecting a file here" unless $f && -f $f;
        my $status = $f;
        $status =~ s/\.muse$/.status/;
        if (! -f $status) {
            push @newf, $f;
        }
        elsif ((stat($f))[$mtime] > (stat($status))[$mtime]) {
            push @newf, $f;
        }
    }
    return @newf;
}

sub recursive_compile {
    my ($self, $dir) = @_;
    return $self->compile($self->find_new_muse_files($dir));
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
    my $cwd = getcwd;
    my @compiled;
    foreach my $file (@files) {
        chdir $cwd or die "Couldn't chdir into $cwd $!";
        if (ref($file)) {
            $self->logger->("Working on virtual file in " . getcwd(). "\n");
            eval { $self->_compile_virtual_file($file); };
        }
        else {
            $self->logger->("Working on $file in " . getcwd() . "\n");
            eval { $self->_compile_file($file); };
        }
        my $fatal = $@;
        chdir $cwd or die "Couldn't chdir into $cwd $!";
        if ($fatal) {
            $self->logger->($fatal);
            $self->add_errors("$file $fatal");
            $self->report_failure_sub->($file);
        }
        else {
            push @compiled, $file;
        }
    }
    return @compiled;
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
                                               virtual => 1,
                                              );
    $self->_muse_compile($muse);
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
    $self->_muse_compile($muse);
}

sub _muse_compile {
    my ($self, $muse) = @_;
    die "Couldn't acquire lock on " . $muse->name . $muse->suffix . '!'
      unless $muse->mark_as_open;
    my @fatals;

    unless ($muse->is_deleted) {
        foreach my $method ($self->compile_methods) {
            eval {
                $muse->$method;
            };
            if ($@) {
                push @fatals, $@;
                last;
            }
            else {
                my $output = $muse->name . $self->_suffix_for_method($method);
                $self->logger->("* Created $output\n");
            }
        }
    }
    if (@fatals) {
        die join(" ", @fatals);
    }
    $muse->mark_as_closed;
    $muse->cleanup if $self->cleanup;
}

sub _suffix_for_method {
    my ($self, $method) = @_;
    return unless $method;
    my $ext = $method;
    $ext =~ s/_/./g;
    $ext = '.' . $ext;
    return $ext;
}

=head3 file_needs_compilation

Returns true if the file has already been compiled, false if some
output file is missing or stale.

=cut

sub file_needs_compilation {
    my ($self, $file) = @_;
    die "Bad usage" unless $file;
    die "$file is not a file" unless -f $file;
    my ($name, $path, $suffix) = fileparse($file, '.muse');
    die "Bad usage, not a muse file" unless $suffix;
    my $need = 0;
    my $mtime = 9;
    foreach my $m ($self->compile_methods) {
        my $outsuffix = $self->_suffix_for_method($m);
        my $outfile = File::Spec->catfile($path, $name . $outsuffix);
        if (-f $outfile and (stat($outfile))[$mtime] > (stat($file))[$mtime]) {
            next;
        }
        else {
            $need = 1;
            last;
        }
    }
    return $need;
}

=head3 report_failure_sub(sub { push @problems, $_[0] });

You can set the sub to be used to report problems using this accessor.
It will receive as first argument the file which led to failure.

The actual errors are logged by the C<logger> sub.

=cut

sub report_failure_sub {
    my ($self, $sub) = @_;
    if (@_ > 1) {
        $self->{report_failure_sub} = $sub;
    }
    elsif (!$self->{report_failure_sub}) {
        $self->{report_failure_sub} = sub {
            print "Failure to compile $_[0]\n";
        };
    }
    return $self->{report_failure_sub};
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
