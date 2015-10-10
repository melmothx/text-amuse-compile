package Text::Amuse::Compile::File;

use strict;
use warnings;
use utf8;

# core
# use Data::Dumper;
use File::Copy qw/move/;
use Encode qw/decode_utf8/;

# needed
use Template::Tiny;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use EBook::EPUB::Lite;
use File::Copy;
use File::Spec;
use IO::Pipe;

# ours
use PDF::Imposition;
use Text::Amuse;
use Text::Amuse::Functions qw/muse_fast_scan_header
                              muse_format_line/;

use Text::Amuse::Compile::TemplateOptions;
use Types::Standard qw/Str Bool Object Maybe CodeRef HashRef/;
use Moo;

=encoding utf8

=head1 NAME

Text::Amuse::Compile::File - Object for file scheduled for compilation

=head1 SYNOPSIS

Everything here is pretty much private. It's used by
Text::Amuse::Compile in a forked and chdir'ed environment.

=head1 ACCESSORS AND METHODS

=head2 new(name => $basename, suffix => $suffix, templates => $templates)

Constructor. Accepts the following named parameters:

=over 4

=item name

=item noslides

Do not create slides when calling c<pdf>

=item virtual

If it's a virtual file which doesn't exit on the disk (a merged one)

=item suffix

=item templates

=item standalone

When set to true, the tex output will obey bcor and twoside/oneside.

=item options

An hashref with the options to pass to the templates.

=item webfonts

The L<Text::Amuse::Compile::Webfonts> object (or undef).

=back

=head1 INTERNALS

=over 4

=item is_deleted

=item status_file

=item check_status

=item purged_extensions

=item muse_file

=item document

The L<Text::Amuse> object

=item tt

The L<Template::Tiny> object

=item logger

The logger subroutine set in the constructor.

=item cleanup

Remove auxiliary files (like the complete file and the status file)

=item luatex

Use luatex instead of xetex

=back

=cut

has luatex => (is => 'ro', isa => Bool, default => sub { 0 });
has noslides => (is => 'ro', isa => Bool, default => sub { 0 });
has name => (is => 'ro', isa => Str, required => 1);
has suffix => (is => 'ro', isa => Str, required => 1);
has templates => (is => 'ro', isa => Object, required => 1);
has virtual => (is => 'ro', isa => Bool, default => sub { 0 });
has standalone => (is => 'ro', isa => Bool, default => sub { 0 });
has is_deleted => (is => 'rwp', isa => Bool, default => sub { 0 });
has tt => (is => 'ro', isa => Object, default => sub { Template::Tiny->new });
has logger => (is => 'ro', isa => Maybe[CodeRef]);
has webfonts => (is => 'ro', isa => Maybe[Object]);
has document => (is => 'lazy', isa => Object);
has options => (is => 'ro', isa => HashRef, default => sub { +{} });
has tex_options => (is => 'lazy', isa => HashRef);
has html_options => (is => 'lazy', isa => HashRef);

sub _build_document {
    my $self = shift;
    return Text::Amuse->new(file => $self->muse_file);
}

sub _build_tex_options {
    my $self = shift;
    return $self->_escape_options_hashref(ltx => $self->options);
}

sub _build_html_options {
    my $self = shift;
    return $self->_escape_options_hashref(html => $self->options);
}

sub _escape_options_hashref {
    my ($self, $format, $ref) = @_;
    die "Wrong usage of internal method" unless $format && $ref;
    my %out;
    foreach my $k (keys %$ref) {
        if (defined $ref->{$k}) {
            if ($k eq 'logo' or $k eq 'cover') {
                if (my $checked = $self->_looks_like_a_sane_name($ref->{$k})) {
                    $out{$k} = $checked;
                }
            }
            else {
                $out{$k} = muse_format_line($format, $ref->{$k});
            }
        }
        else {
            $out{$k} = undef;
        }
    }
    return \%out;
}


sub muse_file {
    my $self = shift;
    return $self->name . $self->suffix;
}

sub status_file {
    return shift->name . '.status';
}

sub check_status {
    my $self = shift;
    my $deleted;
    # it could be virtual
    if (!$self->virtual) {
        my $header = muse_fast_scan_header($self->muse_file);
        $self->log_fatal("Not a muse file!") unless $header && %$header;
        $deleted = $header->{DELETED};
        # TODO maybe use storable?
    }
    $self->purge_all if $deleted;
    $self->_set_is_deleted(!!$deleted);
}


=head2 purge_all

Remove all the output files related to basename

=head2 purge_latex

Remove files left by previous latex compilation

=head2 purge('.epub', ...)

Remove the files associated with this file, by extension.

=cut

sub _slides_extensions {
    return qw/.sl.tex .sl.pdf
              .sl.log .sl.nav .sl.toc .sl.aux
              .sl.nav .sl.snm .sl.out/;

}

sub purged_extensions {
    my $self = shift;
    my @exts = (qw/.pdf .a4.pdf .lt.pdf
                   .tex .log .aux .toc .ok
                   .html .bare.html .epub
                   .zip
                  /,
                $self->_slides_extensions);
    return @exts;
}

sub purge {
    my ($self, @exts) = @_;
    my $basename = $self->name;
    foreach my $ext (@exts) {
        $self->log_fatal("wtf?") if ($ext eq '.muse');
        my $target = $basename . $ext;
        if (-f $target) {
            # $self->log_info("Removing $target\n");
            unlink $target or $self->log_fatal("Couldn't unlink $target $!");
        }
    }
}

sub purge_all {
    my $self = shift;
    $self->purge($self->purged_extensions);
}

sub purge_latex {
    my $self = shift;
    $self->purge(qw/.log .aux .toc .pdf/);
}

sub purge_slides {
    my $self = shift;
    $self->purge($self->_slides_extensions);
}

sub _write_file {
    my ($self, $target, @strings) = @_;
    open (my $fh, ">:encoding(utf-8)", $target)
      or $self->log_fatal("Couldn't open $target $!");

    print $fh @strings;

    close $fh or $self->log_fatal("Couldn't close $target");
    return;
}


=head1 METHODS

=head2 Formats

Emit the respective format, saving it in a file. Return value is
meaningless, but exceptions could be raised.

=over 4

=item html

=item bare_html

=item pdf

=item epub

=item lt_pdf

=item a4_pdf

=item zip

The zipped sources. Beware that if you don't call html or tex before
this, the attachments (if any) are ignored if both html and tex files
exist. Hence, the muse-compile.pl scripts forces the --tex and --html
switches.

=cut

sub _render_css {
    my ($self, %tokens) = @_;
    my $out = '';
    $self->tt->process($self->templates->css, \%tokens, \$out);
    return $out;
}


sub html {
    my $self = shift;
    $self->purge('.html');
    my $outfile = $self->name . '.html';
    $self->_process_template($self->templates->html,
                             {
                              doc => $self->document,
                              css => $self->_render_css(html => 1),
                              options => { %{$self->html_options} },
                             },
                             $outfile);
}

sub bare_html {
    my $self = shift;
    $self->purge('.bare.html');
    my $outfile = $self->name . '.bare.html';
    $self->_process_template($self->templates->bare_html,
                             {
                              doc => $self->document,
                              options => { %{$self->html_options} },
                             },
                             $outfile);
}

sub a4_pdf {
    my $self = shift;
    $self->_compile_imposed('a4');
}

sub lt_pdf {
    my $self = shift;
    $self->_compile_imposed('lt');
}

sub _compile_imposed {
    my ($self, $size) = @_;
    $self->log_fatal("Missing size") unless $size;
    # the trick: first call tex with an argument, then pdf, then
    # impose, then rename.
    $self->tex(papersize => "half-$size");
    my $pdf = $self->pdf(noslides => 1);
    my $outfile = $self->name . ".$size.pdf";
    if ($pdf) {
        my $imposer = PDF::Imposition->new(
                                           file => $pdf,
                                           schema => '2up',
                                           signature => '40-80',
                                           cover => 1,
                                           outfile => $outfile
                                          );
        $imposer->impose;
    }
    else {
        $self->log_fatal("PDF was not produced!");
    }
    return $outfile;
}


=item tex

This method is a bit tricky, because it's called with arguments
internally by C<lt_pdf> and C<a4_pdf>, and with no arguments before
C<pdf>.

With no arguments, this method enforces the options C<twoside=true>
and C<bcor=0mm>, effectively ignoring the global options which affect
the imposed output, unless C<standalone> is set to true.

This means that the twoside and binding correction options follow this
logic: if you have some imposed format, they are ignored for the
standalone PDF but applied for the imposed ones. If you have only
the standalone PDF, they are applied to it.

=back

=cut

sub tex {
    my ($self, @args) = @_;
    my $texfile = $self->name . '.tex';
    $self->log_fatal("Wrong usage") if @args % 2;
    my %arguments = @args;
    unless (@args || $self->standalone) {
        %arguments = (
                      twoside => 0,
                      oneside => 1,
                      bcor    => '0mm',
                     );
    }
    $self->purge('.tex');
    $self->_process_template($self->templates->latex,
                             $self->_prepare_tex_tokens(%arguments),
                             $texfile);
}

sub tex_beamer {
    my ($self) = @_;
    if ($self->noslides || $self->virtual) {
        return;
    }
    # no slides for virtual files
    return if $self->virtual;
    if (my $header = muse_fast_scan_header($self->muse_file)) {
        if ($header->{slides} and $header->{slides} !~ /^\s*no\s*$/si) {
            my $texfile = $self->name . '.sl.tex';
            $self->purge('.sl.tex');
            return $self->_process_template($self->templates->slides,
                                            $self->_prepare_tex_tokens,
                                            $texfile);
        }
    }
    return;
}


sub sl_pdf {
    my $self = shift;
    $self->purge_slides;
    if ($self->noslides || $self->virtual) {
        return;
    }
    if (my $source = $self->tex_beamer) {
        if (my $out = $self->_compile_pdf($source)) {
            $self->log_info("* Created $out\n");
            return $out;
        }
    }
    return;
}

sub pdf {
    my ($self, %opts) = @_;
    # create the slides, if needed.
    unless ($opts{noslides}) {
        $self->sl_pdf;
    }
    my $source = $self->name . '.tex';
    unless (-f $source) {
        $self->tex;
    }
    $self->log_fatal("Missing source file $source!") unless -f $source;
    $self->purge_latex;
    $self->_compile_pdf($source);
}

sub _compile_pdf {
    my ($self, $source) = @_;
    my ($output, $logfile);
    if ($source =~ m/(.+)\.tex$/) {
        die "Missing $source!" unless $source;
        my $name = $1;
        $output = $name . '.pdf';
        $logfile = $name . '.log';
    }
    else {
        die "Source must be a source file\n";
    }
    # maybe a check on the toc if more runs are needed?
    # 1. create the toc
    # 2. insert the toc
    # 3. adjust the toc. Should be ok, right?
    foreach my $i (1..3) {
        my $pipe = IO::Pipe->new;
        # parent swallows the output
        my $latexname = $self->luatex ? 'LuaLaTeX' : 'XeLaTeX';
        my $latex = $self->luatex ? 'lualatex' : 'xelatex';
        $pipe->reader($latex, '-interaction=nonstopmode', $source);
        $pipe->autoflush(1);
        my $shitout;
        while (<$pipe>) {
            my $line = $_;
            if ($line =~ m/^[!#]/) {
                $shitout++;
            }
            if ($shitout) {
                $self->log_info($line);
            }
        }
        wait;
        my $exit_code = $? >> 8;
        if ($exit_code != 0) {
            $self->log_info("$latexname compilation failed with exit code $exit_code\n");
            if (-f $logfile) {
                # if we have a .pdf file, this means something was
                # produced. Hence, remove the .pdf
                unlink $output;
                $self->log_fatal("Bailing out\n");
            }
            else {
                $self->log_info("Skipping PDF generation\n");
                return;
            }
        }
    }
    $self->parse_tex_log_file($logfile);
    return $output;
}



sub zip {
    my $self = shift;
    $self->purge('.zip');
    my $zipname = $self->name . '.zip';
    my $tempdir = File::Temp->newdir;
    my $tempdirname = $tempdir->dirname;
    foreach my $todo (qw/tex html/) {
        my $target = $self->name . '.' . $todo;
        unless (-f $target) {
            $self->$todo;
        }
        $self->log_fatal("Couldn't produce $target") unless -f $target;
        copy($target, $tempdirname)
          or $self->log_fatal("Couldn't copy $target in $tempdirname $!");
    }
    copy ($self->name . '.muse', $tempdirname);

    my $text = $self->document;
    foreach my $attach ($text->attachments) {
        copy($attach, $tempdirname)
          or $self->log_fatal("Couldn't copy $attach to $tempdirname $!");
    }
    my $zip = Archive::Zip->new;
    $zip->addTree($tempdirname, $self->name) == AZ_OK
      or $self->log_fatal("Failure zipping $tempdirname");
    $zip->writeToFileNamed($zipname) == AZ_OK
      or $self->log_fatal("Failure writing $zipname");
    return $zipname;
}


sub epub {
    my $self = shift;
    $self->purge('.epub');
    my $epubname = $self->name . '.epub';

    my $text = $self->document;

    my @pieces = $text->as_splat_html;
    my @toc = $text->raw_html_toc;
    my $missing = scalar(@pieces) - scalar(@toc);
    # this shouldn't happen

    # print Dumper(\@toc);

    if ($missing > 1 or $missing < 0) {
        # $self->log_info(Dumper(\@pieces), Dumper(\@toc));
        $self->log_fatal("This shouldn't happen: missing pieces: $missing");
    }
    elsif ($missing == 1) {
        unshift @toc, {
                       index => 0,
                       level => 1,
                       string => "start body",
                      };
    }
    my $epub = EBook::EPUB::Lite->new;

    # embedded CSS
    my $css = $self->_render_css(epub => 1,
                                 webfonts => $self->webfonts );
    $epub->add_stylesheet("stylesheet.css" => $css);

    # build the title page and some metadata
    my $header = $text->header_as_html;

    my $titlepage = '';

    if ($text->header_defined->{author}) {
        my $author = $header->{author};
        $epub->add_author($self->_clean_html($author));
        $titlepage .= "<h2>$author</h2>\n";
    }

    if ($text->header_defined->{title}) {
        my $t = $header->{title};
        $epub->add_title($self->_clean_html($t));
        $titlepage .= "<h1>$t</h1>\n";
    }
    else {
        $epub->add_title('Untitled');
    }

    if ($text->header_defined->{subtitle}) {
        my $st = $header->{subtitle};
        $titlepage .= "<h2>$st</h2>\n"
    }
    if ($text->header_defined->{date}) {
        if ($header->{date} =~ m/([0-9]{4})/) {
            $epub->add_date($1);
        }
        $titlepage .= "<h3>$header->{date}</h3>"
    }

    $epub->add_language($text->language_code);

    if ($text->header_defined->{source}) {
        my $source = $header->{source};
        $epub->add_source($self->_clean_html($source));
        $titlepage .= "<p>$source</p>";
    }

    if ($text->header_defined->{notes}) {
        my $notes = $header->{notes};
        $epub->add_description($self->_clean_html($notes));
        $titlepage .= "<p>$notes</p>";
    }

    # create the front page
    my $firstpage = '';
    $self->tt->process($self->templates->minimal_html,
                       {
                        title => $self->_remove_tags($header->{title}),
                        text => $titlepage,
                        options => { %{$self->html_options} },
                       },
                       \$firstpage)
      or $self->log_fatal($self->tt->error);

    my $tpid = $epub->add_xhtml("titlepage.xhtml", $firstpage);
    my $order = 0;

    # main loop
    my @navpoints = ({
                      label => "titlepage",
                      id => $tpid,
                      content => "titlepage.xhtml",
                      play_order => ++$order,
                      level => 1,
                     });
    while (@pieces) {
        my $fi =    shift @pieces;
        my $index = shift @toc;
        my $xhtml = "";
        # print Dumper($index);
        my $filename = sprintf('piece%06d.xhtml', $index->{index});
        my $prefix = '*' x $index->{level};
        my $title = $prefix . " " . $index->{string};

        $self->tt->process($self->templates->minimal_html,
                           {
                            title => $self->_remove_tags($title),
                            options => { %{$self->html_options} },
                            text => $fi,
                           },
                           \$xhtml)
          or $self->log_fatal($self->tt->error);

        my $id = $epub->add_xhtml($filename, $xhtml);
        push @navpoints, {
                          label => $self->_clean_html($index->{string}),
                          content => $filename,
                          id => $id,
                          play_order => ++$order,
                          level => $index->{level},
                         };
    }
    $self->_epub_create_toc($epub, \@navpoints);

    # attachments
    foreach my $att ($text->attachments) {
        $self->log_fatal("$att doesn't exist!") unless -f $att;
        my $mime;
        if ($att =~ m/\.jpe?g$/) {
            $mime = "image/jpeg";
        }
        elsif ($att =~ m/\.png$/) {
            $mime = "image/png";
        }
        else {
            $self->log_fatal("Unrecognized attachment $att!");
        }
        $epub->copy_file($att, $att, $mime);
    }
    if (my $fonts = $self->webfonts) {
        foreach my $style (qw/regular italic bold bolditalic/) {
            $epub->copy_file(File::Spec->catfile($fonts->srcdir,
                                                 $fonts->$style),
                             $fonts->$style,
                             $fonts->mimetype);
        }
    }

    # finish
    $epub->pack_zip($epubname);
    return $epubname;
}

sub _epub_create_toc {
    my ($self, $epub, $navpoints) = @_;
    my %levelnavs;
    # print Dumper($navpoints);
  NAVPOINT:
    foreach my $navpoint (@$navpoints) {
        my %nav = %$navpoint;
        my $level = delete $nav{level};
        die "Shouldn't happen: false level: $level" unless $level;
        die "Shouldn't happen either: $level not 1-4" unless $level =~ m/\A[1-4]\z/;
        my $checklevel = $level - 1;

        my $current;
        while ($checklevel > 0) {
            if (my $parent = $levelnavs{$checklevel}) {
                $current = $parent->add_navpoint(%nav);
                last;
            }
            $checklevel--;
        }
        unless ($current) {
            $current = $epub->add_navpoint(%nav);
        }
        for my $clear ($level..4) {
            delete $levelnavs{$clear};
        }
        $levelnavs{$level} = $current;
    }
    # probably not needed, but let's be sure we don't leave circular
    # refs.
    foreach my $k (keys %levelnavs) {
        delete $levelnavs{$k};
    }
}

sub _remove_tags {
    my ($self, $string) = @_;
    return "" unless defined $string;
    $string =~ s/<.+?>//g;
    return $string;
}

sub _clean_html {
    my ($self, $string) = @_;
    return "" unless defined $string;
    $string =~ s/<.+?>//g;
    $string =~ s/&lt;/</g;
    $string =~ s/&gt;/>/g;
    $string =~ s/&quot;/"/g;
    $string =~ s/&#x27;/'/g;
    $string =~ s/&amp;/&/g;
    return $string;
}

=head2 Logging

While the C<logger> accessor holds a reference to a sub, but could be
very well be empty, the object uses these two methods:

=over 4

=item log_info(@strings)

If C<logger> exists, it will call it passing the strings as arguments.
Otherwise print to the standard output.

=item log_fatal(@strings)

Calls C<log_info>, remove the lock and dies.

=item parse_tex_log_file($logfile)

(Internal) Parse the produced logfile for missing characters.

=back

=cut

sub log_info {
    my ($self, @info) = @_;
    my $logger = $self->logger;
    if ($logger) {
        $logger->(@info);
    }
    else {
        print @info;
    }
}

sub log_fatal {
    my ($self, @info) = @_;
    $self->log_info(@info);
    die "Fatal exception\n";
}

sub parse_tex_log_file {
    my ($self, $logfile) = @_;
    die "Missing file argument!" unless $logfile;
    if (-f $logfile) {
        # if you're wandering why we open this in raw mode: The log
        # file produced by XeLaTeX is utf8, but it splits the output
        # at 80 bytes or so. This of course sometimes, expecially
        # working with cyrillic scripts, cut the multibyte character
        # in half, producing invalid utf8 octects.
        open (my $fh, '<:raw', $logfile)
          or $self->log_fatal("Couldn't open $logfile $!");

        my %errors;

        while (my $line = <$fh>) {
            if ($line =~ m/^missing character/i) {
                chomp $line;
                # if we get the warning, nothing we can do about it,
                # but shouldn't happen.
                $errors{$line} = 1;
            }
        }
        close $fh;
        foreach my $error (sort keys %errors) {
            $self->log_info(decode_utf8($error) . "...\n");
        }
    }
}

sub cleanup {
    my $self = shift;
    if (my $f = $self->status_file) {
        if (-f $f) {
            unlink $f or $self->log_fatal("Couldn't unlink $f $!");
        }
        else {
            $self->log_info("Couldn't find " . File::Spec->rel2abs($f));
        }
    }
}

sub _process_template {
    my ($self, $template_ref, $tokens, $outfile) = @_;
    eval {
        my $out = '';
        die "Wrong usage" unless ($template_ref && $tokens && $outfile);
        $self->tt->process($template_ref, $tokens, \$out);
        open (my $fh, '>:encoding(UTF-8)', $outfile) or die "Couldn't open $outfile $!";
        print $fh $out, "\n";
        close $fh;
    };
    if ($@) {
        $self->log_fatal("Error processing template for $outfile: $@");
    };
    return $outfile;
}


# method for options to pass to the tex template
sub _prepare_tex_tokens {
    my ($self, %args) = @_;
    my $doc = $self->document;
    my %tokens = %{ $self->tex_options };
    my $escaped_args = $self->_escape_options_hashref(ltx => \%args);
    foreach my $k (keys %$escaped_args) {
        $tokens{$k} = $escaped_args->{$k};
    }
    # now tokens have the unparsed options
    # now validate the options against the new shiny module
    my %options = (%{ $self->options }, %args);
    my $parsed = eval { Text::Amuse::Compile::TemplateOptions->new(%options) };
    unless ($parsed) {
        $parsed = Text::Amuse::Compile::TemplateOptions->new;
        warn "Validation failed: $@, setting one by one\n";
        foreach my $method ($parsed->config_setters) {
            if (exists $options{$method}) {
                eval { $parsed->$method($options{$method}) };
                if ($@) {
                    warn "Error on $method: $@\n";
                }
            }
        }
    }
    my $safe_options =
      $self->_escape_options_hashref(ltx => $parsed->config_output);

    # defaults
    my %parsed = (%$safe_options,
                  class => 'scrbook',
                  lang => 'english',
                  mainlanguage_script => '',
                  wants_toc => 0,
                 );

    # no cover page
    unless ($doc->wants_toc) {
        if ($doc->header_as_latex->{nocoverpage} || $tokens{nocoverpage}) {
            $parsed{nocoverpage} = 1;
            $parsed{class} = 'scrartcl';
            delete $parsed{opening}; # not needed for article.
        }
    }

    unless ($parsed{notoc}) {
        if ($doc->wants_toc) {
            $parsed{wants_toc} = 1;
        }
    }

    # main language
    my $orig_lang = $doc->language;
    my %lang_aliases = (
                        # bad hack, no mk hyphens...
                        macedonian => 'russian',

                        # the rationale is that polyglossia seems to
                        # go south when you load serbian with latin
                        # script, as the logs are spammed with cyrillic loading.
                        serbian    => 'croatian',
                       );
    my $lang = $parsed{lang} = $lang_aliases{$orig_lang} || $orig_lang;

    # I don't like doing this here, but here we go...
    my %scripts = (
                   russian    => 'Cyrillic',
                  );

    if (my $script = $scripts{$lang}) {
        $parsed{mainlanguage_script} = "\\newfontfamily\\" .
          $lang . 'font[Script=' . $script . ']{' . $parsed{mainfont} . "}\n";
    }

    my %toc_names = (
                     macedonian => 'Содржина',
                    );
    if (my $toc_name = $toc_names{$orig_lang}) {
        $parsed{mainlanguage_toc_name} = $toc_name;
    }

    if (my $other_langs_arrayref = $doc->other_languages) {
        my %other_languages;
        my %additional_strings;
        foreach my $olang (@$other_langs_arrayref) {

            # a bit of duplication...
            my $other_lang = $lang_aliases{$olang} || $olang;
            $other_languages{$other_lang} = 1;
            if (my $script = $scripts{$other_lang}) {
                my $additional = "\\newfontfamily\\" . $other_lang
                  . 'font[Script=' . $script . ']{' . $parsed{mainfont} . "}";
                $additional_strings{$additional} = 1;
            }
        }
        if (%other_languages) {
            $parsed{other_languages} = join(',', sort keys %other_languages);
        }
        if (%additional_strings) {
            $parsed{other_languages_additional} = join("\n", sort keys %additional_strings);
        }
    }

    return {
            options => \%tokens,
            safe_options => \%parsed,
            doc => $doc,
           };
}

sub _looks_like_a_sane_name {
    my ($self, $name) = @_;
    return unless defined $name;
    # windows thing, in case
    $name =~ s!\\!/!g;
    # is it a sensible path? those chars are not special for latex or html
    if ($name =~ m/\A[a-zA-Z0-9\-\:\/]+(\.(pdf|jpe?g|png))?\z/) {
        return $name;
    }
    else {
        return;
    }
}


1;
