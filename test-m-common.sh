#! /bin/sh

SOURCE_EXTENSION=".m .aam"
STANDALONE_SUFFIX="Standalone"

DEFAULT_GCC_CFLAGS="-w -O0 -g"
DEFAULT_CL_CFLAGS="-/W /O0"

CC="${CC:-mulle-clang}"
CXX="${CXX:-mulle-clang}"
