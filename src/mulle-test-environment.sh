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



r_darwin_sdkpath()
{
   # on 10.6 this will fail as --show-sdk-path ain't there
   RVAL="`xcrun --show-sdk-path 2> /dev/null`"
   if [ -z "${RVAL}" ]
   then
      RVAL="`xcode-select -print-path`"
      if [ ! -d "${RVAL}" ]
      then
         return 1
      fi
   fi
}

# this is crap and needs some kind of plugin interface

test_setup_language()
{
   log_entry "test_setup_language" "$@"

   local platform="$1"
   local language="${2:-c}"
   local dialect="${3:-c}"

   case "${language}" in
      c)
         RELEASE_GCC_CFLAGS="-O3 -g -DNDEBUG -DNS_BLOCK_ASSERTIONS"
         DEBUG_GCC_CFLAGS="-O0 -g"

         case "${platform}" in
            mingw*)
               RELEASE_CL_CFLAGS="-O2 -MD -wd4068 -DNDEBUG -DNS_BLOCK_ASSERTIONS" #-/W /O0"
               # http://stackoverflow.com/questions/3007312/resolving-lnk4098-defaultlib-msvcrt-conflicts-with
               # we link vs. cmake generated stuff, that is usually a DLL or will be wrapped into a DLL
               # so we compile with /MD
               DEBUG_CL_CFLAGS="-Zi -DEBUG -MDd -Od -wd4068" #-/W /O0"
            ;;

            windows)
               RELEASE_CL_CFLAGS="/O2 /MD /wd4068 /DNDEBUG /DNS_BLOCK_ASSERTIONS" #-/W /O0"
               # http://stackoverflow.com/questions/3007312/resolving-lnk4098-defaultlib-msvcrt-conflicts-with
               # we link vs. cmake generated stuff, that is usually a DLL or will be wrapped into a DLL
               # so we compile with /MD
               DEBUG_CL_CFLAGS="/Zi /DEBUG /MDd /Od /wd4068" #-/W /O0"
            ;;
         esac

         case "${dialect}" in
            c)
               PROJECT_EXTENSIONS="${PROJECT_EXTENSIONS:-c}"
               STANDALONE_SUFFIX="-standalone"
            ;;

            objc)
               case "${objc_dialect}" in
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

                        windows)
                           CC="mulle-clang-cl.exe"
                           CXX="mulle-clang-cl.exe"

                           # nmake doesn't work ? /questionable!
                           MAKE="ninja.exe"
                        ;;

                        darwin)
                           if ! r_darwin_sdkpath
                           then
                              fail "Could not figure out sdk path with xcrun"
                           fi
                           APPLE_SDKPATH="${RVAL}"

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

               DEBUG_CL_CFLAGS="-DEBUG -MDd -Od -wd4068" #-/W /O0"
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


test_setup_tooling()
{
   log_entry "test_setup_tooling" "$@"

   local platform="$1"

   case "$1" in
      mingw*)
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

      windows)
         CC="${CC:-cl.exe}"
         CXX="${CXX:-cl.exe}"
         MAKE="${MAKE:-ninja.exe}"

         case "${MAKE}" in
            nmake*)
               CMAKE_GENERATOR="NMake Makefiles"
            ;;

            ninja*)
               CMAKE_GENERATOR="Ninja"
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


test_setup_platform()
{
   log_entry "test_setup_platform" "$@"

   local platform="$1"

   #
   # for purposes of .gitignore and sublime it is easier to have a .exe
   # extensions on all platforms:
   #
   EXE_EXTENSION=".exe"
   DEBUG_EXE_EXTENSION=".debug.exe"

   case "${platform}" in
      windows|mingw)
         SHAREDLIB_PREFIX=""
         SHAREDLIB_EXTENSION="${SHAREDLIB_EXTENSION:-.lib}" # link with extension
         STATICLIB_PREFIX=""
         STATICLIB_EXTENSION="${STATICLIB_EXTENSION:-.lib}" # link with extension
         ;;

      darwin)
         SHAREDLIB_PREFIX="lib"
         SHAREDLIB_EXTENSION="${SHAREDLIB_EXTENSION:-.dylib}" # link with extension
         STATICLIB_PREFIX="lib"
         STATICLIB_EXTENSION="${STATICLIB_EXTENSION:-.a}" # link with extension
         ;;

      *)
         SHAREDLIB_PREFIX="lib"
         SHAREDLIB_EXTENSION="${SHAREDLIB_EXTENSION:-.so}" # link with extension
         STATICLIB_PREFIX="lib"
         STATICLIB_EXTENSION="${STATICLIB_EXTENSION:-.a}" # link with extension
      ;;
   esac


   case "${platform}" in
      windows)
         CRLFCAT="dos2unix.exe"
      ;;

      mingw)
         CRLFCAT="dos2unix"
      ;;

      darwin)
         case "${CC}" in
            mulle-cl*)
               # do nuthing
            ;;

            *)
               # LDFLAGS="${LDFLAGS} -framework Foundation"  ## harmless and sometimes useful
            ;;
         esac
         CRLFCAT="cat"
      ;;

      windows|linux)
#         LDFLAGS="${LDFLAGS} -ldl -lpthread"  # weak and lame
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


test_setup_environment()
{
   log_entry "test_setup_environment" "$@"

   local platform="$1"
   local dialect="$3"

   #
   #
   #
   r_suppress_crashdumping
   RESTORE_CRASHDUMP="${RVAL}"
   trap 'trace_ignore "${RESTORE_CRASHDUMP}"' 0 5 6

   #
   #
   #
   MAKEFLAGS="${MAKEFLAGS:-${DEFAULT_MAKEFLAGS}}"

   #
   # Find debugger, clear variable if not installed
   #
   case "${dialect}" in
      objc)
         case "${MULLE_UNAME}" in
            darwin)
               # darwin is just not a good developer platform
               # too hard to get a custom debugger going
            ;;

            *)
               DEBUGGER="${DEBUGGER:-`command -v mulle-gdb`}"
               DEBUGGER="${DEBUGGER:-`command -v mulle-lldb`}"
            ;;
         esac
      ;;
   esac

   case "${MULLE_UNAME}" in
      darwin)
         DEBUGGER="${DEBUGGER:-`command -v lldb`}"
         DEBUGGER="${DEBUGGER:-`command -v gdb`}"
      ;;

      *)
         DEBUGGER="${DEBUGGER:-`command -v gdb`}"
         DEBUGGER="${DEBUGGER:-`command -v lldb`}"
      ;;
   esac
}


test_include_required()
{
   log_entry "test_include_required" "$@"

   if [ -z "${MULLE_PATH_SH}" ]
   then
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-path.sh"
   fi
   if [ -z "${MULLE_FILE_SH}" ]
   then
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-file.sh"
   fi

   . "${MULLE_TEST_LIBEXEC_DIR}/mulle-test-mingw.sh"

   . "${MULLE_TEST_LIBEXEC_DIR}/mulle-test-cmake.sh"
   . "${MULLE_TEST_LIBEXEC_DIR}/mulle-test-compiler.sh"
   . "${MULLE_TEST_LIBEXEC_DIR}/mulle-test-execute.sh"
   . "${MULLE_TEST_LIBEXEC_DIR}/mulle-test-flagbuilder.sh"
   . "${MULLE_TEST_LIBEXEC_DIR}/mulle-test-locate.sh"
   . "${MULLE_TEST_LIBEXEC_DIR}/mulle-test-logging.sh"
   . "${MULLE_TEST_LIBEXEC_DIR}/mulle-test-regexsearch.sh"
}


test_setup_project()
{
   log_entry "test_setup_project" "$@"

   local platform="$1"

   test_setup_language "${platform}" "${PROJECT_LANGUAGE}" "${PROJECT_DIALECT}"
   test_setup_tooling "${platform}" "${PROJECT_LANGUAGE}" "${PROJECT_DIALECT}"
   test_setup_platform "${platform}" "${PROJECT_LANGUAGE}" "${PROJECT_DIALECT}" # after tooling
   test_setup_environment "${platform}" "${PROJECT_LANGUAGE}" "${PROJECT_DIALECT}" # after tooling
}

