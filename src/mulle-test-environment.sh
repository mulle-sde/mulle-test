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
MULLE_TEST_ENVIRONMENT_SH='included'


test::environment::setup_compiler()
{
   log_entry "test::environment::setup_compiler" "$@"

   local platform="$1"
   local language="${2:-c}"
   local dialect="${3:-c}"
   local objc_dialect="${4:-mulle-objc}"

   # Handle shell scripts specially
   case "${language}" in
      'sh')
         PROJECT_EXTENSIONS="${PROJECT_EXTENSIONS:-sh}"
         return   # early return!!
      ;;
   esac

   # Set project extensions based on dialect
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

               # Set MAKE for mulle-objc on mingw/windows
               case "${platform}" in
                  mingw)
                     MAKE="${MAKE:-make}"
                  ;;
                  windows)
                     MAKE="${MAKE:-ninja.exe}"
                  ;;
               esac
            ;;
         esac
      ;;

      *)
         fail "unsupported \"${language}\" dialect \"${dialect}\""
      ;;
   esac

   # Note: We no longer query mulle-platform for compiler selection or flags.
   # mulle-test only needs to know file extensions (PROJECT_EXTENSIONS) to find test files.
   # All compilation is delegated to mulle-platform compiler run command which handles:
   # - Compiler selection (CC, CXX)
   # - Compiler flags (optimization, debug symbols, sanitizers, SDK paths, etc.)
   # - Platform-specific quirks

   # Platform-specific adjustments for mingw
   case "${platform}" in
      'mingw')
         include "platform::mingw"

         case "${MAKE}" in
            'nmake')
               CMAKE_GENERATOR="NMake Makefiles"
            ;;

            'make'|'ming32-make'|"")
               # Compiler already set by mulle-platform
            ;;

            *)
               CMAKE_GENERATOR="${CMAKE_GENERATOR:-Unix Makefiles}"
            ;;
         esac
      ;;
   esac
}


test::environment::setup_execution_platform()
{
   log_entry "test::environment::setup_execution_platform" "$@"

   local platform="$1"

   #
   # for purposes of .gitignore and sublime it is easier to have a .exe
   # extensions on all platforms:
   #
   EXE_EXTENSION=".exe"
   DEBUG_EXE_EXTENSION=".debug.exe"

   case "${platform}" in
      'windows')
         CRLFCAT="dos2unix"
      ;;

      'mingw'|'msys')
         CRLFCAT="dos2unix"
      ;;

      "")
         fail "platform not set"
      ;;

      *)
         CRLFCAT="cat"
      ;;
   esac

   if ! exe="$(command -v "${CRLFCAT}")"
   then
      fail "Please install ${C_RESET_BOLD}${CRLFCAT}${C_ERROR} for tests"
   fi

   log_setting "CRLFCAT             : ${CRLFCAT}"
   log_setting "EXE_EXTENSION       : ${EXE_EXTENSION}"
   log_setting "DEBUG_EXE_EXTENSION : ${DEBUG_EXE_EXTENSION}"
}


test::environment::setup_environment()
{
   log_entry "test::environment::setup_environment" "$@"

   test::run::r_suppress_crashdumping
   RESTORE_CRASHDUMP="${RVAL}"

   MAKEFLAGS="${MAKEFLAGS:-${DEFAULT_MAKEFLAGS}}"

   trap 'test::run::trace_ignore "${RESTORE_CRASHDUMP}"' 0 5 6
}


test::environment::setup_development_platform()
{
   log_entry "test::environment::setup_development_platform" "$@"

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
   local _suffix_object
   local _suffix_executable
   local _r_path_mangler

   local target_platform 

   target_platform="${TEST_PLATFORM}"

   platform::environment::__get_fix_definitions "${target_platform}"

   SHAREDLIB_PREFIX="${_prefix_lib}"
   SHAREDLIB_EXTENSION="${_suffix_dynamiclib}"

   STATICLIB_PREFIX="${_prefix_lib}"
   STATICLIB_EXTENSION="${_suffix_staticlib}"
}


test::environment::setup_debugger()
{
   log_entry "test::environment::setup_debugger" "$@"

   local platform="$1"
   # local language="$2"
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



test::environment::r_get_test_datafile()
{
   local varname="$1"
   local name="$2"
   local fallback="$3"

   [ -z "${TEST_SDK}" ] && _internal_fail "TEST_PLATFORM is empty"
   [ -z "${TEST_PLATFORM}" ] && _internal_fail "TEST_PLATFORM is empty"
   [ -z "${TEST_CONFIGURATION}" ] && _internal_fail "TEST_PLATFORM is empty"

   local triplet

   r_concat "${TEST_PLATFORM}" "${TEST_CONFIGURATION}" '-'
   triplet="${RVAL}"

   r_concat "${TEST_SDK}" "${triplet}" '-'
   triplet="${RVAL}"

   local first
   local third

   # avoid multiple "empty" loops
   local thirds

   r_concat "${triplet}" "${TEST_SDK}"
   r_concat "${RVAL}" "${TEST_PLATFORM}"
   r_concat "${RVAL}" "${TEST_CONFIGURATION}"
   r_concat "${RVAL}" "${MULLE_ARCH}"
   thirds="${RVAL}"

   #
   # not sure a glob an subsequent filter is really faster, because glob
   # has to make a lot of system calls too or ?
   #
   for first in "${name}" 'default'
   do
      for third in ${thirds} ''
      do
         if [ ! -z "${third}" -a "${third}" != "${MULLE_ARCH}" ]
         then
            RVAL="${first}.${varname}.${third}.${MULLE_ARCH}"
            if [ -f "${RVAL}" ]
            then
               log_debug "Found \"${RVAL}\""
               return 0
            fi
            log_debug "\"${RVAL}\" not present"
         fi

         r_concat "${first}.${varname}" "${third}" '.'
         if [ -f "${RVAL}" ]
         then
            log_debug "Found \"${RVAL}\""
            return 0
         fi
         log_debug "\"${RVAL}\" not present"
      done
   done

   log_debug "Returning fallback \"${fallback}\""
   RVAL="${fallback}"
   return 2
}


test::environment::r_get_environmentfile()
{
   local varname="$1"
   local name="$2"
   local fallback="$3"

   if test::environment::r_get_test_datafile "${varname}" "${name}"
   then
      return
   fi

   RVAL="${fallback}"
   if [ -z "${RVAL}" ]
   then
      log_debug "No fallback given"
      return 1
   fi

   if [ ! -f "${RVAL}" ]
   then
      log_debug "Fallback \"${RVAL}\" not present"
      RVAL=
      return 1
   fi

   log_debug "Fallback \"${RVAL}\" found!"
   return
}


test::environment::setup_development_environment()
{
   log_entry "test::environment::setup_development_environment" "$@"

   local uname="$1"
   local platform="${2:-${uname}}"

   #
   # MULLE_TEST_OBJC_DIALECT to be set in environment
   #
   eval `mulle-platform environment --platform "${platform}" --build-tools`

#   test::environment::setup_tooling     "${uname}" "${PROJECT_LANGUAGE}" "${PROJECT_DIALECT}"
   test::environment::setup_development_platform "${platform}"
   test::environment::setup_compiler    "${uname}" "${PROJECT_LANGUAGE}" "${PROJECT_DIALECT}" "${MULLE_TEST_OBJC_DIALECT}"
   test::environment::setup_debugger    "${uname}" "${PROJECT_LANGUAGE}" "${PROJECT_DIALECT}" # after tooling
   test::environment::setup_environment "${uname}" "${PROJECT_LANGUAGE}" "${PROJECT_DIALECT}" # after tooling

   log_setting "DEBUGGER            : ${DEBUGGER}"
   log_setting "DEBUG_EXE_EXTENSION : ${DEBUG_EXE_EXTENSION}"
   log_setting "EXE_EXTENSION       : ${EXE_EXTENSION}"
   log_setting "PROJECT_EXTENSIONS  : ${PROJECT_EXTENSIONS}"
   log_setting "SHAREDLIB_EXTENSION : ${SHAREDLIB_EXTENSION}"
   log_setting "SHAREDLIB_PREFIX    : ${SHAREDLIB_PREFIX}"
   log_setting "STATICLIB_EXTENSION : ${STATICLIB_EXTENSION}"
   log_setting "STATICLIB_PREFIX    : ${STATICLIB_PREFIX}"
}



test::environment::include_required()
{
   log_entry "test::environment::include_required" "$@"

   include "path"
   include "file"


   include "test::cmake"
   include "test::compiler"
   include "test::execute"
   include "test::link-parser"
   include "test::locate"
   include "test::logging"
   include "test::regex"
}

