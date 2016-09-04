#! /bin/sh

SOURCE_EXTENSION=".m .aam"
STANDALONE_SUFFIX="Standalone"

DEFAULTCFLAGS="-w -O0 -g -fobjc-runtime=mulle"

CC="${CC:-mulle-clang}"
CXX="${CXX:-mulle-clang}"
