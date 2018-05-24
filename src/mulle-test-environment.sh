#! /usr/bin/env bash
#
#   Copyright (c) 2018 Nat! - Mulle kybernetiK
#   All rights reserved.
#
#   Redistribution and use in source and binary forms, with or without
#   modification, are permitted provided that the following conditions are met:
#
#   Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
#   Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
#   Neither the name of Mulle kybernetiK nor the names of its contributors
#   may be used to endorse or promote products derived from this software
#   without specific prior written permission.
#
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
#   ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
#   LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
#   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
#   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
#   INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
#   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
#   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
#   POSSIBILITY OF SUCH DAMAGE.
#
MULLE_TEST_ENVIRONMENT_SH="included"


# this is crap and needs some kind of plugin interface

setup_language()
{
   log_entry "setup_language" "$@"

   local platform="$1"
   local language="${2:-c}"
   local dialect="${3:-c}"

   case "${language}" in
      c)
         case "${dialect}" in
            c)
               PROJECT_EXTENSIONS="${PROJECT_EXTENSIONS:-c}"
               STANDALONE_SUFFIX="-standalone"

               OPTIMIZED_GCC_CFLAGS="-w -O3 -g"
               DEBUG_GCC_CFLAGS="-w -O0 -g"

               # http://stackoverflow.com/questions/3007312/resolving-lnk4098-defaultlib-msvcrt-conflicts-with
               # we link vs. cmake generated stuff, that is usually a DLL or will be wrapped into a DLL
               # so we compile with /MD
               RELEASE_CL_CFLAGS="-O2 -MD -wd4068" #-/W /O0"
               DEBUG_CL_CFLAGS="-Zi -DEBUG -MDd -Od -wd4068" #-/W /O0"
            ;;

            objc)
               case "${dialect}" in
                  Apple|GNUStep)
                  ;;

                  *)
                     case "${platform}" in
                        mingw*)
                           CC="mulle-clang-cl"
                           CXX="mulle-clang-cl"

                           # nmake doesn't work ? /questionable!
                           MAKE="make"
                        ;;

                        darwin)
                           APPLE_SDKPATH="`xcrun --show-sdk-path`"
                           [ -z "${APPLE_SDKPATH}" ] && fail "Could not figure out sdk path with xcrun"

                           CC="mulle-clang"
                           CXX="mulle-clang"
                        ;;

                        *)
                           CC="mulle-clang"
                           CXX="mulle-clang"
                        ;;
                     esac
                  ;;
               esac

               PROJECT_EXTENSIONS="${PROJECT_EXTENSIONS:-m:aam}"
               STANDALONE_SUFFIX="-standalone"

               RELEASE_GCC_CFLAGS="-w -O3 -g"
               DEBUG_GCC_CFLAGS="-w -O0 -g"

               RELEASE_CL_CFLAGS="-O2  -MD -wd4068" #-/W /O0"
               DEBUG_CL_CFLAGS="-Od -MDd -wd4068" #-/W /O0"
            ;;

            *)
               fail "unsupported \"${language}\" dialect \"${dialect}\""
            ;;
         esac
      ;;

      *)
         fail "unsupported language \"${language}\""
      ;;
   esac
}


setup_library_type()
{
   log_entry "setup_library_type" "$@"

   local libtype="${1:-standalone}"

   case "${libtype}" in
      "shared")
         [ -z "${SHAREDLIB_PREFIX}"    ] && fail "SHAREDLIB_PREFIX undefined"
         [ -z "${SHAREDLIB_EXTENSION}" ] && fail "SHAREDLIB_EXTENSION undefined"

         LIB_PREFIX="${SHAREDLIB_PREFIX}"
         LIB_EXTENSION="${SHAREDLIB_EXTENSION}"
         LIB_SUFFIX="${LIB_SUFFIX}"
         return
      ;;

      "standalone")
         [ -z "${SHAREDLIB_PREFIX}"    ] && fail "SHAREDLIB_PREFIX undefined"
         [ -z "${SHAREDLIB_EXTENSION}" ] && fail "SHAREDLIB_EXTENSION undefined"
         [ -z "${STANDALONE_SUFFIX}"   ] && fail "STANDALONE_SUFFIX undefined"

         LIB_PREFIX="${SHAREDLIB_PREFIX}"
         LIB_EXTENSION="${SHAREDLIB_EXTENSION}"
         LIB_SUFFIX="${STANDALONE_SUFFIX}"
         return
      ;;

      "static")
         [ -z "${STATICLIB_EXTENSION}" -a -z "${STATICLIB_PREFIX}" ] && fail "STATICLIB variables undefined"

         LIB_PREFIX="${STATICLIB_PREFIX}"
         LIB_EXTENSION="${STATICLIB_EXTENSION}"
         LIB_SUFFIX="${LIB_SUFFIX}"
      ;;

      *)
         fail "unsupported library type \"$1\""
      ;;
   esac
}


setup_tooling()
{
   log_entry "setup_tooling" "$@"

   local platform="$1"

   case "$1" in
      mingw)
         CC="`mingw_mangle_compiler_exe "${CC}" "CC"`"
         CXX="`mingw_mangle_compiler_exe "${CXX}" "CXX"`"
         CMAKE="${CMAKE:-cmake}"
         MAKE="${MAKE:-nmake}"

         case "${MAKE}" in
            nmake)
               CMAKE_GENERATOR="NMake Makefiles"
            ;;

            make|ming32-make|"")
               CC="${CC:-cl}"
               CXX="${CXX:-cl}"
               CMAKE="mulle-mingw-cmake.sh"
               MAKE="mulle-mingw-make.sh"
               CMAKE_GENERATOR="MinGW Makefiles"
               FILEPATH_DEMANGLER="mingw_demangle_path"
            ;;

            *)
               CMAKE_GENERATOR="${CMAKE_GENERATOR:-Unix Makefiles}"
            ;;
         esac
      ;;

      "")
         fail "platform not set"
      ;;

      *)
         CMAKE_GENERATOR="${CMAKE_GENERATOR:-Unix Makefiles}"
         CMAKE="${CMAKE:-cmake}"
         MAKE="${MAKE:-make}"
         CC="${CC:-cc}"
         CXX="${CXX:-c++}"
      ;;
   esac

   case "${CC}" in
      *-cl|*-cl.exe|cl.exe|cl)
         DEBUG_CFLAGS="${DEBUG_CL_CFLAGS}"
         RELEASE_CFLAGS="${RELEASE_CL_CFLAGS}"
      ;;

      *)
         DEBUG_CFLAGS="${DEBUG_GCC_CFLAGS}"
         RELEASE_CFLAGS="${RELEASE_GCC_CFLAGS}"
      ;;
   esac
}


setup_platform()
{
   log_entry "setup_platform" "$@"

   local platform="$1"

   case "$1" in
      mingw)
         SHAREDLIB_PREFIX=""
         SHAREDLIB_EXTENSION="${SHAREDLIB_EXTENSION:-.lib}" # link with extension
         STATICLIB_PREFIX=""
         STATICLIB_EXTENSION="${STATICLIB_EXTENSION:-.lib}" # link with extension
         EXE_EXTENSION=".exe"
         DEBUG_EXE_EXTENSION=".debug.exe"
         ;;

      darwin)
         SHAREDLIB_PREFIX="lib"
         SHAREDLIB_EXTENSION="${SHAREDLIB_EXTENSION:-.dylib}" # link with extension
         STATICLIB_PREFIX="lib"
         STATICLIB_EXTENSION="${STATICLIB_EXTENSION:-.a}" # link with extension
         EXE_EXTENSION=""
         DEBUG_EXE_EXTENSION=".debug"
         ;;

      *)
         SHAREDLIB_PREFIX="lib"
         SHAREDLIB_EXTENSION="${SHAREDLIB_EXTENSION:-.so}" # link with extension
         STATICLIB_PREFIX="lib"
         STATICLIB_EXTENSION="${STATICLIB_EXTENSION:-.a}" # link with extension
         EXE_EXTENSION=""
         DEBUG_EXE_EXTENSION=".debug"
      ;;
   esac


   case "$1" in
      mingw)
         CRLFCAT="dos2unix"
      ;;

      darwin)
         case "${CC}" in
            mulle-cl*)
               # do nuthing
            ;;

            *)
               LDFLAGS="${LDFLAGS} -framework Foundation"  ## harmles and sometimes useful
            ;;
         esac
         CRLFCAT="cat"
      ;;

      linux)
         LDFLAGS="${LDFLAGS} -ldl -lpthread"  # weak and lame
         CRLFCAT="cat"
      ;;

      "")
         log_fail "platform not set"
      ;;

      *)
         CRLFCAT="cat"
      ;;
   esac
 }


