#!/bin/bash

set -e

perl -I lib -I ../PDF-Imposition/lib -I ../Text-Amuse/lib -I ~/amw/EBook-EPUB-Lite/lib t/merged.t

perl -I lib -I ../PDF-Imposition/lib -I ../Text-Amuse/lib -I ~/amw/EBook-EPUB-Lite/lib t/epub-toc.t

perl -I lib -I ../PDF-Imposition/lib -I ../Text-Amuse/lib -I ~/amw/EBook-EPUB-Lite/lib t/compile-merged.t


perl Makefile.PL
TEST_WITH_LATEX=0 RELEASE_TESTING=1 make test
TEST_WITH_LATEX=1 RELEASE_TESTING=1 make test


