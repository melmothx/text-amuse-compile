#!/bin/bash

set -e

/usr/bin/perl -I lib -I ../PDF-Imposition/lib -I ../Text-Amuse/lib -I ~/amw/EBook-EPUB/lib t/merged.t

/usr/bin/perl -I lib -I ../PDF-Imposition/lib -I ../Text-Amuse/lib -I ~/amw/EBook-EPUB/lib t/epub-toc.t

/usr/bin/perl -I lib -I ../PDF-Imposition/lib -I ../Text-Amuse/lib -I ~/amw/EBook-EPUB/lib t/compile-merged.t


perl Makefile.PL
TEST_WITH_LATEX=0 RELEASE_TESTING=1 make test
TEST_WITH_LATEX=1 RELEASE_TESTING=1 make test


