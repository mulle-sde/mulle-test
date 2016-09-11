#! /bin/sh

# nmake doesn't work
MAKE=make
CC="${CC:-mulle-clang}"
CXX="${CXX:-mulle-clang}"

SOURCE_EXTENSION=".m .aam"
STANDALONE_SUFFIX="Standalone"

DEFAULT_GCC_CFLAGS=""
RELEASE_GCC_CFLAGS="-w -O3 -g"
DEBUG_GCC_CFLAGS="-w -O0 -g"

DEFAULT_CL_CFLAGS="-wd4068" #-/W /O0"
RELEASE_CL_CFLAGS="-O2 -wd4068" #-/W /O0"
DEBUG_CL_CFLAGS="-Od -wd4068" #-/W /O0"
