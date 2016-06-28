package Text::Amuse::Compile;

use strict;
use warnings FATAL => 'all';

use constant {
    DEBUG => $ENV{AMW_DEBUG},
};

use File::Basename;
use File::Temp;
use File::Find;
use File::Spec;

use Text::Amuse::Functions qw/muse_fast_scan_header/;
use Text::Amuse::Compile::Templates;
use Text::Amuse::Compile::Webfonts;
use Text::Amuse::Compile::File;
use Text::Amuse::Compile::Merged;
use Text::Amuse::Compile::MuseHeader;
use Text::Amuse::Compile::FileName;

use Cwd;
use Fcntl qw/:flock/;
use Moo;
use Types::Standard qw/Maybe Bool Str HashRef CodeRef Object ArrayRef/;

=head1 NAME

Text::Amuse::Compile - Compiler for Text::Amuse

=head1 VERSION

Version 0.65

=cut

our $VERSION = '0.65';

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

Remove auxiliary files after compilation (.status)

=item webfontsdir

If you want to embed fonts in the EPUB, pass the directory with the
fonts and the specification file (see
L<Text::Amuse::Compile::Webfonts>) in this option.

=item luatex

Use lualatex instead of xelatex.

=item tex

LaTeX output. Compatible with C<xelatex> and C<lualatex> (see below
for the packages needed).

=item pdf

Plain PDF without any imposition.

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

=item sl_tex

The Beamer LaTeX output, if the muse headers say so.

=item sl_pdf

The Beamer PDF output, if the muse headers say so.

If the header has a C<#slides> header with some value (e.g., 1, yes,
ok, whatever) and if there some sectioning, create a pdf presentation
out of it.

E.g., the following will not produce slides:

  #title Foo
  #slides

But this would

  #title Foo
  #slides 1

The value of the header is totally insignificant, as long is not
C<false> or C<no> or C<0> or empty, which disable them.

Sections which contain the comment C<; noslide> are ignored. LaTeX
source is left in the tree with C<.sl.tex> extension, and the output
will have C<.sl.pdf> extension.

=item slides

Alias for sl_pdf.

=item extra_opts

An hashref of key/value pairs to pass to each template in the
C<options> namespace. This is internal

=item extra

In the constructor arguments, a shallow copy will be stored in
C<extra_opts>. Using it as an accessor will return an hash with the
copy of C<extra_opts>

=item standalone

Do not force bcor=0 and oneside for plain tex and pdf

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

has sl_tex => (is => 'ro', isa => Bool, default => sub { 0 });
has sl_pdf => (is => 'ro', isa => Bool, default => sub { 0 });
has luatex => (is => 'ro', isa => Bool, default => sub { 0 });
has zip    => (is => 'ro', isa => Bool, default => sub { 0 });
has tex    => (is => 'ro', isa => Bool, default => sub { 0 });
has pdf    => (is => 'ro', isa => Bool, default => sub { 0 });
has a4_pdf => (is => 'ro', isa => Bool, default => sub { 0 });
has lt_pdf => (is => 'ro', isa => Bool, default => sub { 0 });
has epub   => (is => 'ro', isa => Bool, default => sub { 0 });
has html   => (is => 'ro', isa => Bool, default => sub { 0 });
has bare_html => (is => 'ro', isa => Bool, default => sub { 0 });

has cleanup   => (is => 'ro', isa => Bool, default => sub { 0 });

has ttdir     => (is => 'ro',   isa => Maybe[Str]);
has templates => (is => 'lazy', isa => Object);

has webfontsdir => (is => 'ro', isa => Maybe[Str]);
has webfonts  => (is => 'lazy', isa => Maybe[Object]);
has standalone => (is => 'lazy', isa => Bool);
has extra_opts => (is => 'ro', isa => HashRef, default => sub { +{} });

sub slides {
    return shift->sl_pdf;
}

sub BUILDARGS {
    my ($class, %params) = @_;
    $params{extra_opts} = { %{ delete $params{extra} || {} } };
    my $all = 1;
    if (exists $params{slides}) {
        my $slides = delete $params{slides};
        $params{sl_pdf} ||= $slides;
    }
    foreach my $format ($class->available_methods) {
        if (exists $params{$format}) {
            $all = 0;
            last;
        }
    }
    if ($all) {
        foreach my $format ($class->available_methods) {
            $params{$format} = 1;
        }
    }
    foreach my $dir (qw/ttdir webfontsdir/) {
        if (exists $params{$dir} and defined $params{$dir} and -d $params{$dir}) {
            my $abs = File::Spec->rel2abs($params{$dir});
            $params{$dir} = $abs;
        }
    }
    return \%params;
}

sub available_methods {
    return (qw/bare_html
               html
               epub
               a4_pdf
               lt_pdf
               tex
               zip
               pdf
               sl_tex
               sl_pdf
              /);
}
sub compile_methods {
    my $self = shift;
    return grep { $self->$_ } $self->available_methods;
}



sub extra {
    return %{ shift->extra_opts };
}


sub _build_standalone {
    my $self = shift;
    if ($self->a4_pdf || $self->lt_pdf) {
        return 0;
    }
    else {
        return 1;
    }
}

sub _build_templates {
    my $self = shift;
    return Text::Amuse::Compile::Templates->new(ttdir => $self->ttdir);
}

sub _build_webfonts {
    my $self = shift;
    return Text::Amuse::Compile::Webfonts->new(webfontsdir => $self->webfontsdir);
}

has logger => (is => 'rw',
               isa => CodeRef,
               default => sub { return sub { print @_ }; });

has report_failure_sub => (is => 'rw',
                           isa => CodeRef,
                           default => sub {
                               return sub {
                                   print "Failure to compile $_[0]\n";
                               }
                           });
has errors => (is => 'rwp', isa => ArrayRef, default => sub { [] });


=head2 BUILDARGS routine

The C<extra> key is passed instead to C<extra_opts>. Directories are
made absolute. If no formats are required explicitely, set them all to
true.

=cut

=head2 METHODS

=head3 templates

The L<Text::Amuse::Compile::Templates> object, which will provide the
templates string references.

=head3 webfonts

The L<Text::Amuse::Compile::Webfonts> object, constructed from the the
C<webfontsdir> option.

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
            eval { $self->_compile_virtual_file($file); };
        }
        else {
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
    $self->logger->("Working on virtual file in " . getcwd(). "\n");
    my @filelist = map { Text::Amuse::Compile::FileName->new($_) } @$files;
    my $doc = Text::Amuse::Compile::Merged->new(files => \@filelist, %virtual);
    my $muse = Text::Amuse::Compile::File->new(
                                               name => $name,
                                               suffix => $suffix,
                                               luatex => $self->luatex,
                                               templates => $self->templates,
                                               options => { $self->extra },
                                               document => $doc,
                                               logger => $self->logger,
                                               virtual => 1,
                                               standalone => $self->standalone,
                                               webfonts => $self->webfonts,
                                              );
    $self->_muse_compile($muse);
}


sub _compile_file {
    my ($self, $file) = @_;
    my $fileobj = Text::Amuse::Compile::FileName->new($file);
    die "$file is not a file" unless $fileobj && -f $fileobj->full_path;

    if (my $path = $fileobj->path) {
        chdir $path or die "Cannot chdir into $path from " . getcwd() . "\n" ;
    };

    my $filename = $fileobj->filename;
    $self->logger->("Working on $filename file in " . getcwd(). "\n");

    my %args = (
                name => $fileobj->name,
                suffix => $fileobj->suffix,
                templates => $self->templates,
                options => { $self->extra },
                logger => $self->logger,
                standalone => $self->standalone,
                webfonts => $self->webfonts,
                luatex => $self->luatex,
                fileobj => $fileobj,
               );

    my $muse = Text::Amuse::Compile::File->new(%args);
    $self->_muse_compile($muse);
}

# write the  status file and unlock it after that.

sub _write_status_file {
    my ($self, $fh, $status) = @_;
    my $localtime = localtime();
    my %avail = (
                 FAILED => 1,
                 DELETED => 1,
                 OK => 1,
                );
    die unless $avail{$status};
    print $fh "$status $$ $localtime\n";
    flock($fh, LOCK_UN) or die "Cannot unlock status file\n";
    close $fh;
}

sub _muse_compile {
    my ($self, $muse) = @_;
    my $statusfile = $muse->status_file;
    open (my $fhlock, '>:encoding(utf-8)', $statusfile)
      or die "Cannot open $statusfile\n!";
    flock($fhlock, LOCK_EX | LOCK_NB) or die "Cannot acquire lock on $statusfile";

    sleep 5 if DEBUG;

    my @fatals;
    my @warnings;

    $muse->purge_all unless DEBUG;
    if ($muse->is_deleted) {
        $self->_write_status_file($fhlock, 'DELETED');
        return;
    }
    foreach my $method ($self->compile_methods) {
        if ($method eq 'sl_pdf' or $method eq 'sl_tex') {
            unless ($muse->wants_slides) {
                $self->logger->("* Slides not required\n");
                next;
            }
        }
        my $output = eval {
            local $SIG{__WARN__} = sub {
                push @warnings, @_;
            };
            $muse->$method
        };
        if ($@) {
            push @fatals, $@;
            last;
        }
        elsif ($output) {
            $self->logger->("* Created $output\n");
        }
        else {
            $self->logger->("* $method skipped\n");
        }
    }
    if (@fatals) {
        $self->_write_status_file($fhlock, 'FAILED');
        die join(" ", @fatals);
    }
    else {
        $self->_write_status_file($fhlock, 'OK');
    }
    $muse->cleanup if $self->cleanup;
    foreach my $warn (@warnings) {
        $self->logger->("Warning: $warn") if $warn;
    }
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

=head3 parse_muse_header($file)

Return a L<Text::Amuse::Compile::MuseHeader> object for the given
file.

=cut

sub _check_file_basename {
    my ($self, $file) = @_;
    my $fileobj = Text::Amuse::Compile::FileName->new($file);
    return File::Spec->catfile($fileobj->path, $fileobj->name);
}

sub parse_muse_header {
    my ($self, $file) = @_;
    my $path = Text::Amuse::Compile::FileName->new($file)->full_path;
    return Text::Amuse::Compile::MuseHeader->new(muse_fast_scan_header($path));
}


sub file_needs_compilation {
    my ($self, $file) = @_;
    my $need = 0;
    my $mtime = 9;
    my $basename = $self->_check_file_basename($file);
    my $header = $self->parse_muse_header($file);
    foreach my $m ($self->compile_methods) {
        my $outsuffix = $self->_suffix_for_method($m);
        my $outfile = $basename . $outsuffix;
        if ($m eq 'sl_tex' or $m eq 'sl_pdf') {
            next unless $header->wants_slides;
        }
        if (-f $outfile and (stat($outfile))[$mtime] >= (stat($file))[$mtime]) {
            print "$outfile is OK\n" if DEBUG;
            next;
        }
        else {
            print "$outfile is NOT OK\n" if DEBUG;
            $need = 1;
            last;
        }
    }
    return $need;
}

=head2 purge(@files)

Remove all the files produced by the compilation of the files passed
as arguments.

=cut

sub purge {
    my ($self, @files) = @_;
    foreach my $file (@files) {
        my $basename = $self->_check_file_basename($file);
        foreach my $ext (Text::Amuse::Compile::File->purged_extensions) {
            die "?" if $ext eq '.muse';
            my $produced = $basename . $ext;
            if (-f $produced) {
                $self->logger->("Purging $produced\n");
                unlink $produced or warn "Cannot unlink $produced $!";
            }
        }
    }
}


=head3 report_failure_sub(sub { push @problems, $_[0] });

You can set the sub to be used to report problems using this accessor.
It will receive as first argument the file which led to failure.

The actual errors are logged by the C<logger> sub.

=head3 errors

Accessor to the catched errors. It returns a list of strings.

=head3 add_errors($error1, $error2,...)

Add an error. [Internal]

=head3 reset_errors

Reset the errors

=head3 has_errors

Return the number of errors (handy to use as a boolean).

=cut

sub add_errors {
    my ($self, @args) = @_;
    push @{$self->errors}, @args;
}

sub reset_errors {
    my $self = shift;
    $self->_set_errors([]);
}

sub has_errors {
    return scalar(@{ shift->errors });
}

=head1 TeX live packages needed.

You need the xetex scheme plus the following packages: fontspec,
polyglossia, pzdr, wrapfig, footmisc, ulem, microtype, zapfding.

For the luatex options, same as above plus luatex (and the lualatex
format), luatexbase, luaotfload.

The luatex option could give better microtypography results but is
slower (x4) and requires more memory (x2).

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
