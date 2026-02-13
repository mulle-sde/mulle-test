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
      fail "Please install dos2unix for tests"
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

   target_platform="${MULLE_PLATFORM}"
   target_platform="${target_platform:-MULLE_CRAFT_PLATFORMS%%:*}"
   target_platform="${target_platform:-${MULLE_UNAME}}"

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



test::environment::r_get_environmentfile()
{
   local name="$1"
   local varname="$2"
   local fallback="$3"

   RVAL="${name}.${varname}.${MULLE_PLATFORM}.${MULLE_ARCH}"
   if [ ! -f "${RVAL}" ]
   then
      log_debug "\"${RVAL}\" not present"
      RVAL="${name}.${varname}.${MULLE_PLATFORM}"
      if [ ! -f "${RVAL}" ]
      then
         log_debug "\"${RVAL}\" not present"
         RVAL="${name}.${varname}.${MULLE_ARCH}"
         if [ ! -f "${RVAL}" ]
         then
            log_debug "\"${RVAL}\" not present"
            RVAL="${name}.${varname}"
            if [ ! -f "${RVAL}" ]
            then
               log_debug "\"${RVAL}\" not present"
               RVAL="default.${varname}.${MULLE_PLATFORM}.${MULLE_ARCH}"
               if [ ! -f "${RVAL}" ]
               then
                  log_debug "\"${RVAL}\" not present"
                  RVAL="default.${varname}.${MULLE_PLATFORM}"
                  if [ ! -f "${RVAL}" ]
                  then
                     log_debug "\"${RVAL}\" not present"
                     RVAL="default.${varname}.${MULLE_ARCH}"
                     if [ ! -f "${RVAL}" ]
                     then
                        log_debug "\"${RVAL}\" not present"
                        RVAL="default.${varname}"
                        if [ ! -f "${RVAL}" ]
                        then
                           log_debug "\"${RVAL}\" not present"
                           RVAL="${fallback}"
                           if [ -z "${RVAL}" ]
                           then
                              return 1
                           fi
                           if [ ! -f "${RVAL}" ]
                           then
                              log_debug "\"${RVAL}\" not present"
                              RVAL=
                              return 1
                           fi
                        fi
                     fi
                  fi
               fi
            fi
         fi
      fi
   fi

   log_debug "\"${RVAL}\" found!"
   return 0
}


test::environment::r_get_test_datafile()
{
   local varname="$1"
   local name="$2"
   local fallback="$3"

   RVAL="${name}.${varname}.${MULLE_PLATFORM}.${MULLE_ARCH}"
   if [ ! -f "${RVAL}" ]
   then
      log_debug "\"${RVAL}\" not present"
      RVAL="${name}.${varname}.${MULLE_PLATFORM}"
      if [ ! -f "${RVAL}" ]
      then
         log_debug "\"${RVAL}\" not present"
         RVAL="${name}.${varname}.${MULLE_ARCH}"
         if [ ! -f "${RVAL}" ]
         then
            log_debug "\"${RVAL}\" not present"
            RVAL="${name}.${varname}"
            if [ ! -f "${RVAL}" ]
            then
               log_debug "\"${RVAL}\" not present"
               RVAL="default.${varname}.${MULLE_PLATFORM}.${MULLE_ARCH}"
               if [ ! -f "${RVAL}" ]
               then
                  log_debug "\"${RVAL}\" not present"
                  RVAL="default.${varname}.${MULLE_PLATFORM}"
                  if [ ! -f "${RVAL}" ]
                  then
                     log_debug "\"${RVAL}\" not present"
                     RVAL="default.${varname}.${MULLE_ARCH}"
                     if [ ! -f "${RVAL}" ]
                     then
                        log_debug "\"${RVAL}\" not present"
                        RVAL="default.${varname}"
                        if [ ! -f "${RVAL}" ]
                        then
                           log_debug "\"${RVAL}\" not present, returning \"${fallback}\""
                           RVAL="${fallback}"
                        fi
                     fi
                  fi
               fi
            fi
         fi
      fi
   fi
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
   . "${MULLE_TEST_LIBEXEC_DIR}/mulle-test-link-parser.sh"
   . "${MULLE_TEST_LIBEXEC_DIR}/mulle-test-locate.sh"
   . "${MULLE_TEST_LIBEXEC_DIR}/mulle-test-logging.sh"
   . "${MULLE_TEST_LIBEXEC_DIR}/mulle-test-regex.sh"
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

