#! /usr/bin/env bash

case "`uname -s`" in
	MINGW*)
		CC="${CC:-mulle-clang-cl}"
		CXX="${CXX:-mulle-clang-cl}"

      # nmake doesn't work ? /questionable!
      MAKE=make
   ;;

   *)
      CC="${CC:-mulle-clang}"
      CXX="${CXX:-mulle-clang}"
   ;;
esac

echo "CC is ${CC}" >&2
echo "CXX is ${CC}" >&2

SOURCE_EXTENSION=".m .aam"
STANDALONE_SUFFIX="Standalone"

RELEASE_GCC_CFLAGS="-w -O3 -g"
DEBUG_GCC_CFLAGS="-w -O0 -g"

RELEASE_CL_CFLAGS="-O2  -MD -wd4068" #-/W /O0"
DEBUG_CL_CFLAGS="-Od -MDd -wd4068" #-/W /O0"
