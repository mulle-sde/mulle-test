#! /usr/bin/env bash

#
# OBJC_DIALECT is by default empty
#
case "${OBJC_DIALECT}" in
   Apple|GNUStep)
   ;;

   *)
      case "`uname -s`" in
      	MINGW*)
      		CC="mulle-clang-cl"
      		CXX="mulle-clang-cl"

            # nmake doesn't work ? /questionable!
            MAKE=make
         ;;

         *)
            CC="mulle-clang"
            CXX="mulle-clang"
         ;;
      esac
   ;;
esac

SOURCE_EXTENSION=".m .aam"
STANDALONE_SUFFIX="Standalone"

RELEASE_GCC_CFLAGS="-w -O3 -g"
DEBUG_GCC_CFLAGS="-w -O0 -g"

RELEASE_CL_CFLAGS="-O2  -MD -wd4068" #-/W /O0"
DEBUG_CL_CFLAGS="-Od -MDd -wd4068" #-/W /O0"
