package Text::Amuse::Compile::Templates;

use 5.010001;
use strict;
use warnings FATAL => 'all';
use utf8;

use File::Spec::Functions qw/catfile/;

=head1 NAME

Text::Amuse::Compile::Templates - Built-in templates for Text::Amuse::Compile

=head1 METHODS

=head2 new(ttdir => 'mytemplates')

Costructor. Options:

=over 4

=item ttdir

The directory where to search for templates.

B<Disclaimer>: some things are needed for a correct
layout/compilation. It's strongly reccomended to use the existing one
(known to work as expected) as starting point for a custom template.

=back

=head2 TEMPLATES

The following methods return a B<reference> to a scalar with the
templates. It should be self-evident which kind of template they
return.

=head3 html

=head3 css

The default CSS, with some minor templating.

=head3 bare_html

The HTML fragment with the B<body> of the text (no HTML headers, no
Muse headers).

=head3 minimal_html

Minimal (but valid) XHTML template, with a link to C<stylesheet.css>.
Meant to be used in the EPUB generation.

=head3 title_page_html

Minimal XHTML template for a title page in the EPUB generation.

=head3 bare_latex

Minimal and uncomplete LaTeX chunck, meant to be used when merging
files.

=head3 latex

The LaTeX template, with dimension conditional.

The built-in LaTeX template supports the following options, which are
picked up from the C<extra> constructor of L<Text::Amuse::Compile>.

The template itself uses two hashrefs with tokens: C<options> and
C<safe_options>. The C<options> contains tokens which are interpreted
as L<Text::Amuse> strings from the C<extra> constructor. The
C<safe_options> ones contains validate copies of the C<options> for
places where it make sense, plus some internal things like the
languages and additional strings to get the LaTeX code right.

All the values from C<options> and C<safe_options>, because of the
markup interpretation, are (hopefully) safely escaped (so you can pass
even LaTeX commands, and they will be escaped).

=head4 Globals

=over 4

=item safe_options.nocoverpage

If the text doesn't require a toc, this options set the class to
komascript's article. Ignored if there is a toc.

=item safe_options.notoc

Do not generate a table of contents, even if the document requires
one.

=item safe_options.papersize

Paper size, like a4, a5 or 210mm:11in. The width and heigth are
swapped in some komascript version. Just keep this in mind and do some
trial and error if you need custom dimensions.

=item safe_options.division

The DIV of the C<typearea> package. Defaults to 12. Go and read the doc.

=item safe_options.opening

On which pages the chapters should open: right, left, any. Default:
right. The left one will probably lead to unexpected results (the PDF
will start with an empty page), so use it at your own peril.

=item safe_options.bcor

The BCOR of the C<typearea> package. Defaults to 0mm. Go and read the doc.
It expects a TeX dimension like 10mm or 1in or 1.2cm.

B<Please note that this has no effect on the plain PDF output>, as we,
opinionately, force BCOR=0mm and oneside=true for this kind of output.
But, of course, it does affect the imposed output.

=item safe_options.fontsize

The font size in point (should be an integer). Defaults to 10.

=item safe_options.mainfont

The system font name, such as C<Linux Libertine O> or C<Charis SIL>.
This implementation uses XeLaTeX, so we can use system fonts. Defaults
to C<Linux Libertine O>. This is just a copy of C<options.mainfont>,
as we can't know which font is installed.

=item options.oneside

Set it to a true value to have a oneside document. Default is true.

=item options.twoside

Set it to a true value to have a twosided document. Default is false.

B<Please note that this has no effect on the plain PDF output>, as we,
opinionately, force BCOR=0mm and oneside=true for this kind of output.
But, of course, it does affect the imposed output.

=item safe_options.paging

The merging of C<options.oneside> and C<options.twoside> results in
this token. If both or none are true, will default to C<oneside>.

=back

=head4 Cover

=over 4

=item options.cover

When this option is set to a true value, skip the creation of the
title page with \maketitle, and instead build a custome one, with the
cover placed in the middle of the page.

The value can be an absolute path, or a bare filename, which can be
found by C<kpsewhich>. If the path is not valid and sane (from the
LaTeX point of view: no spaces, no strange chars), the value is
ignored.

=item safe_options.coverwidth

Option to control the cover width, when is set (ignored otherwise).
Defaults to the full text width (i.e., 1). You have to pass a float
here with the ratio to the text width, like C<0.5>, C<1>.

=back


=head4 Colophon

In the last page the built in template supports the following options

=over 4

=item options.sitename

At the top of the page

=item options.siteslogan

At the top, under sitename

=item options.logo

At the top, under siteslogan

=item options.site

At the bottom of the page

=back

=head2 INTERNALS

=head3 ttref($name)

Return the scalar ref associated to the given template file, if any.

=head3 names

Return the list of methods for template generation

=cut


sub new {
    my ($class, @args) = @_;
    die "Wrong usage" if @args % 2;
    my %params = @args;
    my $self = {};

    # argument parsing
    foreach my $k (qw/ttdir/) {
        if (exists $params{$k}) {
            $self->{$k} = delete $params{$k};
        }
    }
    die "Unrecognized options: " . join(" ", keys %params) if %params;

    $self->{tt_subrefs} = {};
    if (exists $self->{ttdir} and defined $self->{ttdir}) {

        if (-d $self->{ttdir}) {
            my $dir = $self->{ttdir};
            opendir (my $dh, $dir) or die "Couldn't open $dir $!";
            my @templates = grep { -f catfile($dir, $_) 
                                    and
                                       /^(((bare|minimal)[_.-])?html|
                                            (bare[_.-])?latex     |
                                            css)
                                        (\.tt2?)?/x
                               } readdir($dh);
            closedir $dh;

            foreach my $t (@templates) {
                my $target = catfile($dir, $t); 
                open (my $fh, '<:encoding(utf-8)', $target)
                  or die "Can't open $target $!";
                local $/ = undef;
                my $content = <$fh>;
                close $fh;

                # manipulate the subref name
                $t =~ s/\.(tt|tt2)//;
                $t =~ s/[\.-]/_/g;

                # populate the object with closures.
                $self->{tt_subrefs}->{$t} = sub {
                    # copy the content, otherwise we return
                    # a ref that can be modified
                    my $string = $content;
                    return \$string;
                };
            }
        }
        else {
            die "$self->{ttdir} is not a directory!\n";
        }
    }
    bless $self, $class;
}

sub ttdir {
    return shift->{ttdir};
}

sub names {
    return (qw/html minimal_html bare_html
               css latex bare_latex
              /);
}

sub ttref {
    my ($self, $name) = @_;
    return unless $name;
    if (exists $self->{tt_subrefs}->{$name}) {
        return $self->{tt_subrefs}->{$name}->();
    }
    return;
}

sub html {
    my $self = shift;
    if (my $ref = $self->ttref('html')) {
        return $ref;
    }
    my $html = <<'EOF';
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="[% doc.language_code %]" lang="[% doc.language_code %]">
<head>
  <meta http-equiv="Content-type" content="application/xhtml+xml; charset=UTF-8" />
  <title>[% doc.header_as_html.title %]</title>
  <style type="text/css">
 <!--/*--><![CDATA[/*><!--*/
[% css %]
  /*]]>*/-->
    </style>
</head>
<body>
 <div id="page">
  [% IF doc.header_defined.author %]
  <h2 class="amw-text-author">[% doc.header_as_html.author %]</h2>
  [% END %]
  <h1 class="amw-text-title">[% doc.header_as_html.title %]</h1>
  [% IF doc.header_defined.subtitle %]
  <h2>[% doc.header_as_html.subtitle %]</h2>
  [% END  %]
  [% IF doc.header_defined.date %]
  <h3 class="amw-text-date">[% doc.header_as_html.date %]</h3>
  [% END  %]
  [% IF doc.toc_as_html %]
  <div class="table-of-contents">
  [% doc.toc_as_html %]
  </div>
  [% END %]
 <div id="thework">
[% doc.as_html %]
 </div>
  <hr />
  <div id="impressum">
    [% IF doc.header_defined.source %]
    <div class="amw-text-source" id="source">
    [% doc.header_as_html.source %]
    </div>
    [% END %]
    [% IF doc.header_defined.notes %]
    <div class="amw-text-notes" id="notes">
    [% doc.header_as_html.notes %]
    </div>
    [% END %]
  </div>
</div>
</body>
</html>

EOF
    return \$html;
}

sub css {
    my $self = shift;
    if (my $ref = $self->ttref('css')) {
        return $ref;
    }
    my $css = <<'EOF';
[% IF epub %]
@page { margin: 5pt; }
[% END %]

html,body {
	margin:0;
	padding:0;
	border: none;
 	background: transparent;
	font-family: serif;
	font-size: 10pt;
}

[% IF epub %]
div#page > p {
   margin: 0;
   text-indent: 1em;
   text-align: justify;
}

blockquote > p, li > p {
   margin-top: 5pt;
   text-indent: 0em;
   text-align: justify;
}

a {
   color:#000000;
   text-decoration: underline
}
[%  END %]

[% IF html %]
div#page {
   margin:20px;
   padding:20px;
}
[% END %]

pre, code {
    font-family: Consolas, courier, monospace;
}
/* invisibles */
span.hiddenindex, span.commentmarker, .comment, span.tocprefix, #hitme {
    display: none
}

h1 {
    font-size: 200%;
    margin: .67em 0
}
h2 {
    font-size: 180%;
    margin: .75em 0
}
h3 {
    font-size: 150%;
    margin: .83em 0
}
h4 {
    font-size: 130%;
    margin: 1.12em 0
}
h5 {
    font-size: 115%;
    margin: 1.5em 0
}
h6 {
    font-size: 100%;
    margin: 0;
}

sup, sub {
    font-size: 8pt;
    line-height: 0;
}

/* invisibles */
span.hiddenindex, span.commentmarker, .comment, span.tocprefix, #hitme {
    display: none
}

.comment {
    background: rgb(255,255,158);
}

.verse {
    margin: 24px 48px;
    overflow: auto;
}

table, th, td {
    border: solid 1px black;
    border-collapse: collapse;
}
td, th {
    padding: 2px 5px;
}

hr {
    margin: 24px 0;
    color: #000;
    height: 1px;
    background-color: #000;
}

table {
    margin: 24px auto;
}

td, th { vertical-align: top; }
th {font-weight: bold;}

caption {
    caption-side:bottom;
}

img.embedimg {
    max-width:90%;
}
div.image, div.float_image_f {
    margin: 1em;
    text-align: center;
    padding: 3px;
    background-color: white;
}

div.float_image_r {
    float: right;
}

div.float_image_l {
    float: left;
}

div.float_image_f {
    clear: both;
    margin-left: auto;
    margin-right: auto;

}

.biblio p, .play p {
  margin-left: 1em;
  text-indent: -1em;
}

div.biblio, div.play {
  padding: 24px 0;
}

div.caption {
    padding-bottom: 1em;
}

div.center {
    text-align: center;
}

div.right {
    text-align: right;
}

.toclevel1 {
	font-weight: bold;
	font-size:11pt;
}	

.toclevel2 {
	font-weight: bold;
	font-size: 10pt;
    padding-left: 1em;
}

.toclevel3 {
	font-weight: normal;
	font-size: 9pt;
    padding-left: 2em;
}

.toclevel4 {
	font-weight: normal;
	font-size: 8pt;
    padding-left: 3em;
}


/* footnotes */

a.footnote, a.footnotebody {
    font-size: 8pt;
    line-height: 0;
    vertical-align: super;
}

* + p.fnline {
    margin-top: 3em;
    border-top: 1px solid black;
    padding-top: 2em;
}

p.fnline + p.fnline {
    margin-top: 1em;
    border-top: none;
    padding-top: 0;
}

p.fnline {
    font-size: 8pt;
}
/* end footnotes */

EOF
    return \$css;
}

sub bare_html {
    my $self = shift;
    if (my $ref = $self->ttref('bare_html')) {
        return $ref;
    }
    my $html = <<'EOF';
[% IF doc.toc_as_html %]
<div class="table-of-contents">
[% doc.toc_as_html %]
</div>
[% END %]
<div id="thework">
[% doc.as_html %]
</div>
EOF
    return \$html;
}

sub title_page_html {
    my $self = shift;
    if (my $ref = $self->ttref('title_page_html')) {
        return $ref;
    }
    my $html = <<'EOF';
<div id="first-page-title-page">
  [% IF doc.header_defined.author %]
  <h2 class="amw-text-author">[% doc.header_as_html.author %]</h2>
  [% END %]
  <h1 class="amw-text-title">[% doc.header_as_html.title %]</h1>
  [% IF doc.header_defined.subtitle %]
  <h2 class="amw-text-subtitle">[% doc.header_as_html.subtitle %]</h2>
  [% END  %]
  [% IF doc.header_defined.date %]
  <h3 class="amw-text-date">[% doc.header_as_html.date %]</h3>
  [% END  %]
</div>
<hr />
<div id="impressum-title-page">
  [% IF doc.header_defined.source %]
  <div class="amw-text-source" id="source">
  [% doc.header_as_html.source %]
  </div>
  [% END %]
  [% IF doc.header_defined.notes %]
  <div class="amw-text-notes" id="notes">
  [% doc.header_as_html.notes %]
  </div>
  [% END %]
</div>
EOF
    return \$html;
}

sub minimal_html {
    my $self = shift;
    if (my $ref = $self->ttref('minimal_html')) {
        return $ref;
    }
    my $html = <<'EOF';
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <title>[% title %]</title>
    <link href="stylesheet.css" type="text/css" rel="stylesheet" />
  </head>
  <body>
    <div id="page">
      [% text %]
    </div>
  </body>
</html>
EOF
    return \$html;
}


sub latex {
    my $self = shift;
    if (my $ref = $self->ttref('latex')) {
        return $ref;
    }
    my $latex = <<'EOF';
\documentclass[DIV=[% safe_options.division %],%
               BCOR=[% safe_options.bcor %],%
               footinclude=false,[% IF safe_options.opening %]open=[% safe_options.opening %],[% END %]%
               fontsize=[% safe_options.fontsize %]pt,%
               [% safe_options.paging %],%
               paper=[% safe_options.papersize %]]%
               {[% safe_options.class %]}
\usepackage{fontspec}
\usepackage{polyglossia}
\setmainfont[Mapping=tex-text]{[% safe_options.mainfont %]}
% these are not used but prevents XeTeX to barf
\setsansfont[Mapping=tex-text,Scale=MatchLowercase]{DejaVu Sans}
\setmonofont[Mapping=tex-text,Scale=MatchLowercase]{DejaVu Sans Mono}
\setmainlanguage{[% safe_options.lang %]}
[% safe_options.mainlanguage_script %]

[% IF safe_options.other_languages %]
\setotherlanguages{[% safe_options.other_languages %]}
[% END %]
[% IF safe_options.other_languages_additional %]
[% safe_options.other_languages_additional %]
[% END %]

[% IF safe_options.mainlanguage_toc_name %]
\renewcaptionname{[% safe_options.lang %]}{\contentsname}{[% safe_options.mainlanguage_toc_name %]}
[% END %]

\usepackage{microtype} % you need an *updated* texlive 2012, but harmless
\usepackage{graphicx}
\usepackage{alltt}
\usepackage{verbatim}
% http://tex.stackexchange.com/questions/3033/forcing-linebreaks-in-url
\PassOptionsToPackage{hyphens}{url}\usepackage[hyperfootnotes=false,hidelinks,breaklinks=true]{hyperref}
\usepackage{bookmark}
\usepackage[stable]{footmisc}
\usepackage{enumerate}
\usepackage{tabularx}
\usepackage[normalem]{ulem}
\usepackage{wrapfig}
\usepackage{indentfirst}
% remove the numbering
\setcounter{secnumdepth}{-2}

% remove labels from the captions
\renewcommand*{\captionformat}{}
\renewcommand*{\figureformat}{}
\renewcommand*{\tableformat}{}
\KOMAoption{captions}{belowfigure,nooneline}
\addtokomafont{caption}{\centering}

% avoid breakage on multiple <br><br> and avoid the next [] to be eaten
\newcommand*{\forcelinebreak}{\strut\\{}}

\newcommand*{\hairline}{%
  \bigskip%
  \noindent \hrulefill%
  \bigskip%
}

% reverse indentation for biblio and play

\newenvironment*{amusebiblio}{
  \leftskip=\parindent
  \parindent=-\parindent
  \smallskip
  \indent
}{\smallskip}

\newenvironment*{amuseplay}{
  \leftskip=\parindent
  \parindent=-\parindent
  \smallskip
  \indent
}{\smallskip}

\newcommand*{\Slash}{\slash\hspace{0pt}}

% global style
\pagestyle{plain}
\addtokomafont{disposition}{\rmfamily}
% forbid widows/orphans
\frenchspacing
\sloppy
\clubpenalty=10000
\widowpenalty=10000

% given that we said footinclude=false, this should be safe
\setlength{\footskip}{2\baselineskip}

\title{[% doc.header_as_latex.title %]}
\date{[% doc.header_as_latex.date %]}
\author{[% doc.header_as_latex.author %]}
\subtitle{[% doc.header_as_latex.subtitle %]}

\begin{document}
[% IF doc.hyphenation %]
\hyphenation{ [% doc.hyphenation %] }
[% END %]

[% IF options.cover %]
  \thispagestyle{empty}
  \strut\bigskip
  \begin{center}
    [% IF doc.header_defined.author %]
    {\Large\textbf{[% doc.header_as_latex.author %]}\\[\baselineskip]}
    [% END %]
    {\LARGE\textbf{[% doc.header_as_latex.title %]\\[\baselineskip]}}
    [% IF doc.header_defined.subtitle %]
      {\Large\textbf{[% doc.header_as_latex.subtitle %]}\\[\baselineskip]}
    [% END %]
    \vfill
    \includegraphics[width=[% safe_options.coverwidth %]\textwidth]{[% options.cover %]}
    \vfill
    [% IF doc.header_defined.date %]
    {\large [% doc.header_as_latex.date %]}
    [% END %]
    \strut
  \end{center}
[% ELSE %]
\maketitle
[% END %]
[% UNLESS safe_options.nocoverpage %]
\cleardoublepage
[% END %]

[% IF safe_options.wants_toc %]
\tableofcontents
% start a new right-handed page
\cleardoublepage
[% END %]

[% doc.as_latex %]

\clearpage
% new page for the colophon

\thispagestyle{empty}

\begin{center}
[% IF options.sitename %]
[% options.sitename %]
[% END %]

[% IF options.siteslogan %]
\smallskip
[% options.siteslogan %]
[% END %]

[% IF options.logo %]
\bigskip
\includegraphics[width=0.25\textwidth]{[% options.logo %]}
\bigskip
[% ELSE %]
\strut
[% END %]
\end{center}

\strut

\vfill

\begin{center}

[% doc.header_as_latex.author     %]

[% doc.header_as_latex.title      %]

[% doc.header_as_latex.subtitle   %]

[% doc.header_as_latex.date       %]

\bigskip

[% doc.header_as_latex.source     %]

[% doc.header_as_latex.notes      %]

[% IF options.site %]
\bigskip
\textbf{[% options.site %]}
[% END %]

\end{center}

\end{document}

EOF
    return \$latex;
}

sub bare_latex {
    my $self = shift;
    if (my $ref = $self->ttref('bare_latex')) {
        return $ref;
    }
    my $latex =<<'LATEX';
[% IF doc.hyphenation %]
\hyphenation{ [% doc.hyphenation %] }
[% END %]

\cleardoublepage

\thispagestyle{empty}

\strut

\phantomsection
\addcontentsline{toc}{part}{[% doc.header_as_latex.title %]}

\vspace{0.1\textheight}

\begin{center}
\huge{\textbf{[% doc.header_as_latex.title %]}\par}
\bigskip
[% IF doc.header_defined.subtitle %]
\LARGE{\textbf{[% doc.header_as_latex.subtitle %]}\par}
\bigskip
[% END %]
[% IF doc.header_defined.author %]
\Large{[% doc.header_as_latex.author %]\par}
\bigskip
[% END %]
[% IF doc.header_defined.date %]
\large{[% doc.header_as_latex.date %]}
[% END %]

\end{center}

\vfill

[% IF doc.header_defined.source %]
\begin{center}
[% doc.header_as_latex.source     %]
\end{center}
[% END %]

[% IF doc.header_defined.notes %]
\begin{center}
[% doc.header_as_latex.notes      %]
\end{center}
[% END %]

\cleardoublepage

[% doc.as_latex %]

LATEX
    return \$latex;
}

=head1 EXPORT

None.

=cut

1;
