package Text::Amuse::Compile::File;

use strict;
use warnings;
use utf8;

use Template;
use Text::Amuse;
use Text::Amuse::Functions qw/muse_fast_scan_header/;
use PDF::Imposition;


=encoding utf8

=head1 NAME

Text::Amuse::Compile::File - Object for file scheduled for compilation

=head1 SYNOPSIS

Everything here is pretty much private. It's used by
Text::Amuse::Compile in a forked and chdir'ed environment.

=head1 ACCESSORS AND METHODS

=head2 new(name => $basename, suffix => $suffix, templates => $templates)

Constructor.

=head1 INTERNALS

=over 4

=item name

=item suffix

=item templates

=item is_deleted

=item complete_file

=item mark_as_closed

=item mark_as_open

=item purged_extensions

=item lockfile

=item muse_file

=item document

The L<Text::Amuse> object

=item tt

The L<Template> object

=back

=cut

sub new {
    my ($class, @args) = @_;
    die "Wrong number or args" if @args % 2;
    my $self = { @args };
    foreach my $k (qw/name suffix templates/) {
        die "Missing $k" unless $self->{$k};
    }
    bless $self, $class;
}

sub name {
    return shift->{name};
}

sub suffix {
    return shift->{suffix};
}

sub templates {
    return shift->{templates};
}

sub lockfile {
    return shift->name . '.lock';
}

sub muse_file {
    my $self = shift;
    return $self->name . $self->suffix;
}

sub complete_file {
    return shift->name . '.ok';
}

sub is_deleted {
    return shift->{is_deleted};
}

sub _set_is_deleted {
    my $self = shift;
    $self->{is_deleted} = shift;
}

sub tt {
    my $self = shift;
    unless ($self->{tt}) {
        $self->{tt} = Template->new;
    }
    return $self->{tt};
}

sub document {
    my $self = shift;
    # prevent parsing of deleted, bad file
    return if $self->is_deleted;
    unless ($self->{document}) {
        my $doc = Text::Amuse->new(file => $self->muse_file);
        $self->{document} = $doc;
    }
    return $self->{document};
}

sub mark_as_open {
    my $self = shift;
    my $lockfile = $self->lockfile;
    if ($self->_lock_is_valid) {
        warn "Locked: $lockfile\n";
        return 0;
    }
    else {
        my $header = muse_fast_scan_header($self->muse_file);
        die "Not a muse file!" unless $header && %$header;
        $self->_write_file($lockfile, $$ . ' ' . localtime . "\n");
        $self->purge;
        $self->_set_is_deleted($header->{DELETED});
        return 1;
    }
}

sub mark_as_closed {
    my $self = shift;
    my $lockfile = $self->lockfile;
    unlink $lockfile or die "Couldn't unlink $lockfile!";
    $self->_write_file($self->complete_file, $$ . ' ' . localtime . "\n");
}

=head2 purge

Remove all the output files related to basename

=cut

sub purged_extensions {
    my $self = shift;
    my @exts = (qw/.pdf .a4.pdf .lt.pdf
                   .tex .log .aux .toc.
                   .html .bare.html .epub/);
    return @exts;
}

sub purge {
    my $self = shift;
    my $basename = $self->name;
    foreach my $ext ($self->purged_extensions) {
        my $target = $basename . $ext;
        if (-f $target) {
            warn "Removing $target\n";
            unlink $target or die "Couldn't unlink $target $!";
        }
    }
}



sub _write_file {
    my ($self, $target, @strings) = @_;
    open (my $fh, ">:encoding(utf-8)", $target)
      or die "Couldn't open $target $!";

    print $fh @strings;

    close $fh or die "Couldn't close $target";
    return;
}

sub _lock_is_valid {
    my $self = shift;
    my $lockfile = $self->lockfile;
    return unless -f $lockfile;
    open (my $fh, '<', $lockfile) or die $!;
    my $pid;
    my $string = <$fh>;
    if ($string =~ m/^(\d+)/) {
        $pid = $1;
    }
    else {
        die "Bad lockfile!\n";
    }
    close $fh;
    return unless $pid;
    if (kill 0, $pid) {
        return 1;
    }
    else {
        return;
    }
}

=head1 METHODS

=head2 html

=head2 bare_html

=head2 tex

=cut

sub html {
    my $self = shift;
    $self->tt->process($self->templates->html,
                       {
                        doc => $self->document,
                        css => ${ $self->templates->css },
                       },
                       $self->name . '.html',
                       { binmode => ':encoding(utf-8)' });

};

sub bare_html {
    my $self = shift;
    $self->tt->process($self->templates->bare_html,
                       {
                        doc => $self->document,
                       },
                       $self->name . '.bare.html',
                       { binmode => ':encoding(utf-8)' });
};

sub tex { };


1;
