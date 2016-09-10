#! /bin/sh

SOURCE_EXTENSION=".m .aam"
STANDALONE_SUFFIX="Standalone"

DEFAULT_GCC_CFLAGS="-w -O0 -g"
DEFAULT_CL_CFLAGS="-Od -wd4068" #-/W /O0"

# nmake doesn't work
MAKE=make
CC="${CC:-mulle-clang}"
CXX="${CXX:-mulle-clang}"
