#!/bin/bash

set -e
perl Makefile.PL
make clean
perl Makefile.PL
TEST_WITH_LATEX=0 RELEASE_TESTING=1 make test
TEST_WITH_LATEX=1 RELEASE_TESTING=1 make test
make dist
