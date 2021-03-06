#!perl

use utf8;
use strict;
use warnings;
use Text::Amuse::Compile;
use Path::Tiny;
use Data::Dumper;
use Test::More tests => 1;

my $muse = <<'MUSE';
#title My title

Test

; :c8: \thispagestyle{empty}
; :c8: \thispagestyle{emptyx}
; :c8: \\thispagestyle{empty}
;  :c8:   \vskip 8cm
;  :c8:   \sloppy
;  :c8:   \fussy
Test
;  :c8:   \strut
;  :c8:   \newpage
;  :c8:   \vskip 20mm
;  :c8:   \vskip -3em
; :c8: \markboth{test{escape}and}{test\me}
; :c8: \markboth{test teća}{Đavo}
; :c8: \pagestyle{myheadings}
; :c8: \markright{Teća Đavo}
; :c8: \markright{Teća {Đavo}}
; :c8:  \enlargethispage{10em}
; :c8:  \enlargethispage{-10mm}
; :c8:  \flushbottom
; :c8:  \raggedbottom
Test

; :c8: \looseness=1

Loose + 1

; :c8: \looseness=-1

Loose - 1

MUSE

my $exp = <<'EXP';
\thispagestyle{empty}
% :c8: \textbackslash{}thispagestyle\{emptyx\}
% :c8: \textbackslash{}\textbackslash{}thispagestyle\{empty\}
\vskip 8cm
\sloppy
\fussy

Test

\strut
\newpage
\vskip 20mm
\vskip -3em
% :c8: \textbackslash{}markboth\{test\{escape\}and\}\{test\textbackslash{}me\}
\markboth{test teća}{Đavo}
\pagestyle{myheadings}
\markright{Teća Đavo}
% :c8: \textbackslash{}markright\{Teća \{Đavo\}\}
\enlargethispage{10em}
\enlargethispage{-10mm}
\flushbottom
\raggedbottom

Test

\looseness=1
Loose + 1

\looseness=-1
Loose - 1

EXP

my $wd = Path::Tiny->tempdir(CLEANUP => !$ENV{NOCLEANUP});
{
    my $file = $wd->child("text.muse");
    $file->spew_utf8($muse);
    my $c = Text::Amuse::Compile->new(
                                      tex => 1,
                                      pdf => $ENV{TEST_WITH_LATEX},
                                      extra => { format_id => 'c8' }
                                     );
    $c->compile("$file");
    my $tex = $wd->child("text.tex")->slurp_utf8;
    # normalize both to quick fix win32 tests
    $exp =~ s/\r//gs;
    $tex =~ s/\r//gs;
    like $tex, qr{\Q$exp\E};
}
