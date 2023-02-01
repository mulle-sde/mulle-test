# shellcheck shell=bash
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


#
# thi sets up make/cmake and other tools
#
test::environment::setup_tooling()
{
   log_entry "test::environment::setup_tooling" "$@"

   local platform="$1"

   case "${platform}" in
      mingw)
         include "platform::mingw"

         platform::mingw::r_mangle_compiler_exe "${CC}" "CC"
         CC="${RVAL}"
         platform::mingw::r_mangle_compiler_exe "${CXX}" "CXX"
         CXX="${RVAL}"
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
               # unused
               # FILEPATH_DEMANGLER="platform::mingw::demangle_path"
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

      *bsd|dragonfly)
         CMAKE_GENERATOR="${CMAKE_GENERATOR:-Unix Makefiles}"
         CMAKE="${CMAKE:-cmake}"
         MAKE="${MAKE:-make}"
         CC="${CC:-clang}"
         CXX="${CXX:-clang++}"
      ;;

      sunos)
         CMAKE_GENERATOR="${CMAKE_GENERATOR:-Unix Makefiles}"
         CMAKE="${CMAKE:-cmake}"
         MAKE="${MAKE:-make}"
         CC="${CC:-gcc}"
         CXX="${CXX:-g++}"
      ;;

      *)
         CMAKE_GENERATOR="${CMAKE_GENERATOR:-Unix Makefiles}"
         CMAKE="${CMAKE:-cmake}"
         MAKE="${MAKE:-make}"
         CC="${CC:-cc}"
         CXX="${CXX:-c++}"
      ;;
   esac

   #
   #
   #
   MAKEFLAGS="${MAKEFLAGS:-${DEFAULT_MAKEFLAGS}}"
}



# this is crap and needs some kind of plugin interface
# this sets up the compiler and linker and flags
#
test::environment::setup_compiler()
{
   log_entry "test::environment::setup_compiler" "$@"

   local platform="$1"
   local language="${2:-c}"
   local dialect="${3:-c}"
   local objc_dialect="${4:-mulle-objc}"

   case "${language}" in
      c)
         RELEASE_GCC_CFLAGS="-O2 -g -DNDEBUG -DNS_BLOCK_ASSERTIONS"
         DEBUG_GCC_CFLAGS="-O0 -g"

         case "${platform}" in
            'mingw')
               RELEASE_CL_CFLAGS="-O2 -MD -wd4068 -DNDEBUG -DNS_BLOCK_ASSERTIONS" #-/W /O0"
               # http://stackoverflow.com/questions/3007312/resolving-lnk4098-defaultlib-msvcrt-conflicts-with
               # we link vs. cmake generated stuff, that is usually a DLL or will be wrapped into a DLL
               # so we compile with /MD
               DEBUG_CL_CFLAGS="-Zi -DEBUG -MDd -Od -wd4068" #-/W /O0"
            ;;

            'windows')
               RELEASE_CL_CFLAGS="/O2 /MD /wd4068 /DNDEBUG /DNS_BLOCK_ASSERTIONS" #-/W /O0"
               # http://stackoverflow.com/questions/3007312/resolving-lnk4098-defaultlib-msvcrt-conflicts-with
               # we link vs. cmake generated stuff, that is usually a DLL or will be wrapped into a DLL
               # so we compile with /MD
               DEBUG_CL_CFLAGS="/Zi /DEBUG /MDd /Od /wd4068" #-/W /O0"
            ;;
         esac

         case "${dialect}" in
            'c')
               PROJECT_EXTENSIONS="${PROJECT_EXTENSIONS:-c}"
               STANDALONE_SUFFIX="-standalone"
            ;;

            'objc')
               case "${objc_dialect}" in
                  [Aa]pple|[Gg][Nn][Uu][Ss]tep)
                     PROJECT_EXTENSIONS="${PROJECT_EXTENSIONS:-m}"
                  ;;

                  mulle-objc)
                     PROJECT_EXTENSIONS="${PROJECT_EXTENSIONS:-m:aam}"
                     STANDALONE_SUFFIX="-standalone"

                     case "${platform}" in
                        mingw)
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
                           include "platform::sdkpath"

                           if ! platform::sdkpath::r_darwin_sdkpath
                           then
                              fail "Could not figure out SDK path"
                           fi
                           APPLE_SDKPATH="${RVAL}"

                           if [ "${MULLE_TEST_OBJC_DIALECT:-mulle-objc}" = "mulle-objc" ]
                           then
                              CC="mulle-clang"
                              CXX="mulle-clang"
                           else
                              CC="cc"
                              CXX="cc"
                           fi
                        ;;

                        *)
                           CC="mulle-clang"
                           CXX="mulle-clang"
                        ;;
                     esac
                  ;;
               esac

               DEBUG_CL_CFLAGS="-DEBUG -MDd -Od -wd4068" #-/W /O0"
            ;;

            *)
               fail "unsupported \"${language}\" dialect \"${dialect}\""
            ;;
         esac
      ;;

      'sh')
         PROJECT_EXTENSIONS="${PROJECT_EXTENSIONS:-sh}"
         CC=true
         CXX=true
         return   # early return!!
      ;;

      *)
         fail "unsupported language \"${language}\""
      ;;
   esac

   case "${platform}" in
      'mingw') # assume msys is more gcc oriented
          include "platform::mingw"

#         CC="`platform::mingw::mangle_compiler_exe "${CC}" "CC"`"
#         CXX="`platform::mingw::mangle_compiler_exe "${CXX}" "CXX"`"
#
         case "${MAKE}" in
            'nmake')
               CMAKE_GENERATOR="NMake Makefiles"
            ;;

            'make'|'ming32-make'|"")
               CC="${CC:-cl}"
               CXX="${CXX:-cl}"
            ;;

            *)
               CMAKE_GENERATOR="${CMAKE_GENERATOR:-Unix Makefiles}"
            ;;
         esac
      ;;

#      windows)
#         CC="${CC:-cl.exe}"
#         CXX="${CXX:-cl.exe}"
#      ;;
#
#      "")
#         fail "platform not set"
#      ;;
#
#      *)
#         CC="${CC:-cc}"
#         CXX="${CXX:-c++}"
#      ;;
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


test::environment::setup_platform()
{
   log_entry "test::environment::setup_platform" "$@"

   local platform="$1"

   #
   # for purposes of .gitignore and sublime it is easier to have a .exe
   # extensions on all platforms:
   #
   EXE_EXTENSION=".exe"
   DEBUG_EXE_EXTENSION=".debug.exe"

   include "platform::environment"

   local _option_frameworkpath
   local _option_libpath
   local _option_link_mode
   local _option_linklib
   local _option_rpath
   local _prefix_framework
   local _prefix_lib
   local _suffix_dynamiclib
   local _suffix_framework
   local _suffix_staticlib
   local _r_path_mangler

   platform::environment::__get_fix_definitions

   SHAREDLIB_PREFIX="${_prefix_lib}"
   SHAREDLIB_EXTENSION="${_suffix_dynamiclib}"

   STATICLIB_PREFIX="${_prefix_lib}"
   STATICLIB_EXTENSION="${_suffix_staticlib}"

   case "${platform}" in
      'windows')
         CRLFCAT="dos2unix"
      ;;

      'mingw'|'msys')
         CRLFCAT="dos2unix"
      ;;

      'darwin')
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

      'windows'|'linux')
#         LDFLAGS="${LDFLAGS} -ldl -lpthread"  # weak and lame
         CRLFCAT="cat"
      ;;

      "")
         fail "platform not set"
      ;;

      *)
         CRLFCAT="cat"
      ;;
   esac
}


test::environment::setup_environment()
{
   log_entry "test::environment::setup_environment" "$@"

   test::run::r_suppress_crashdumping
   RESTORE_CRASHDUMP="${RVAL}"

   trap 'test::run::trace_ignore "${RESTORE_CRASHDUMP}"' 0 5 6
}


test::environment::setup_debugger()
{
   log_entry "test::environment::setup_debugger" "$@"

   local platform="$1"
   local dialect="$3"

   case "${language}" in
      sh)
         return
      ;;
   esac

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


test::environment::include_required()
{
   log_entry "test::environment::include_required" "$@"

   if [ -z "${MULLE_PATH_SH}" ]
   then
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-path.sh"
   fi
   if [ -z "${MULLE_FILE_SH}" ]
   then
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-file.sh"
   fi

   . "${MULLE_TEST_LIBEXEC_DIR}/mulle-test-cmake.sh"
   . "${MULLE_TEST_LIBEXEC_DIR}/mulle-test-compiler.sh"
   . "${MULLE_TEST_LIBEXEC_DIR}/mulle-test-execute.sh"
   . "${MULLE_TEST_LIBEXEC_DIR}/mulle-test-flagbuilder.sh"
   . "${MULLE_TEST_LIBEXEC_DIR}/mulle-test-locate.sh"
   . "${MULLE_TEST_LIBEXEC_DIR}/mulle-test-logging.sh"
   . "${MULLE_TEST_LIBEXEC_DIR}/mulle-test-regex.sh"
}


test::environment::setup_project()
{
   log_entry "test::environment::setup_project" "$@"

   local platform="$1"

   #
   # MULLE_TEST_OBJC_DIALECT to be set in environment
   #
   test::environment::setup_tooling     "${platform}" "${PROJECT_LANGUAGE}" "${PROJECT_DIALECT}"
   test::environment::setup_compiler    "${platform}" "${PROJECT_LANGUAGE}" "${PROJECT_DIALECT}" "${MULLE_TEST_OBJC_DIALECT}"
   test::environment::setup_platform    "${platform}" "${PROJECT_LANGUAGE}" "${PROJECT_DIALECT}" # after tooling
   test::environment::setup_debugger    "${platform}" "${PROJECT_LANGUAGE}" "${PROJECT_DIALECT}" # after tooling
   test::environment::setup_environment "${platform}" "${PROJECT_LANGUAGE}" "${PROJECT_DIALECT}" # after tooling

   log_setting "CC                  : ${CC}"
   log_setting "CXX                 : ${CXX}"
   log_setting "CFLAGS              : ${CFLAGS}" # environment only!
   log_setting "DEBUGGER            : ${DEBUGGER}"
   log_setting "DEBUG_CFLAGS        : ${DEBUG_CFLAGS}"
   log_setting "DEBUG_EXE_EXTENSION : ${DEBUG_EXE_EXTENSION}"
   log_setting "EXE_EXTENSION       : ${EXE_EXTENSION}"
   log_setting "PROJECT_EXTENSIONS  : ${PROJECT_EXTENSIONS}"
   log_setting "RELEASE_CFLAGS      : ${RELEASE_CFLAGS}"
   log_setting "SHAREDLIB_EXTENSION : ${SHAREDLIB_EXTENSION}"
   log_setting "SHAREDLIB_PREFIX    : ${SHAREDLIB_PREFIX}"
   log_setting "STATICLIB_EXTENSION : ${STATICLIB_EXTENSION}"
   log_setting "STATICLIB_PREFIX    : ${STATICLIB_PREFIX}"
}

