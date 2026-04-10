# shellcheck shell=bash
#
#   Copyright (c) 2024 Nat! - Mulle kybernetiK
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
MULLE_TEST_OPTIONS_SH='included'


# Parse common flags for both craft and run commands
# Returns shift count in RVAL
# Caller must initialize OPTION_ variables before calling
#
# local OPTION_ALL
# local OPTION_CONFIGURATION
# local OPTION_COVERAGE
# local OPTION_EXTENSIONS
# local OPTION_GDB
# local OPTION_GOLDEN_STDOUT
# local OPTION_LENIENT
# local OPTION_MAXJOBS
# local OPTION_OUTPUT_ASSEMBLER
# local OPTION_OUTPUT_ASSEMBLER_IR
# local OPTION_PARALLEL
# local OPTION_PATH_PREFIX
# local OPTION_PLATFORM
# local OPTION_POSTPROCESS
# local OPTION_PRINT_EXE
# local OPTION_PROJECT_DIALECT
# local OPTION_PROJECT_EXTENSIONS
# local OPTION_PROJECT_LANGUAGE
# local OPTION_REMOVE_EXE
# local OPTION_RERUN
# local OPTION_REUSE_EXE
# local OPTION_RUN_SCRIPT
# local OPTION_RUN_TEST
# local OPTION_SANITIZER
# local OPTION_STANDALONE
# local OPTION_TIMEOUT
# local OPTION_VALGRIND
#
test::options::r_parse()
{
   log_entry "test::options::r_parse" "$@"
   local shifts=0
   local rc

   rc=0
   while [ $# -ne 0 ]
   do
      case "$1" in
         -a|--all)
            OPTION_ALL='YES'
            shifts=$((shifts + 1))
         ;;

         -g|--gdb)
            OPTION_GDB='YES'
            shifts=$((shifts + 1))
         ;;

         -j|--jobs)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift
            OPTION_MAXJOBS="$1"
            shifts=$((shifts + 2))
         ;;

         -l|--lenient)
            OPTION_LENIENT='YES'
            shifts=$((shifts + 1))
         ;;

         -V)
            DEFAULT_MAKEFLAGS="VERBOSE=1"
            MULLE_FLAG_LOG_EXEKUTOR='YES'
            shifts=$((shifts + 1))
         ;;

         --assembler)
            OPTION_OUTPUT_ASSEMBLER='YES'
            shifts=$((shifts + 1))
         ;;

         --configuration)
            [ $# -lt 2 ] && fail "Missing argument for $1"
            shift
            OPTION_CONFIGURATION="$1"
            shifts=$((shifts + 2))
         ;;

         --coverage)
            OPTION_COVERAGE='YES'
            shifts=$((shifts + 1))
         ;;

         --debug)
            OPTION_CONFIGURATION='Debug'
            shifts=$((shifts + 1))
         ;;

         --extensions)
            [ $# -lt 2 ] && fail "Missing argument for $1"
            shift
            OPTION_EXTENSIONS="$1"
            shifts=$((shifts + 2))
         ;;

         --golden-stdout)
            OPTION_GOLDEN_STDOUT='YES'
            shifts=$((shifts + 1))
         ;;

         --ir|--llvm-ir)
            OPTION_OUTPUT_ASSEMBLER_IR='YES'
            shifts=$((shifts + 1))
         ;;

         --keep-exe)
            OPTION_REMOVE_EXE='NO'
            shifts=$((shifts + 1))
         ;;

         --no-parallel|--serial)
            OPTION_PARALLEL='NO'
            shifts=$((shifts + 1))
         ;;

         --no-postprocess)
            OPTION_POSTPROCESS='NO'
            shifts=$((shifts + 1))
         ;;

         --no-run-script)
            OPTION_RUN_SCRIPT='NO'
            shifts=$((shifts + 1))
         ;;

         --no-run-test)
            OPTION_RUN_TEST='NO'
            shifts=$((shifts + 1))
         ;;

         --only-postprocess|--postprocess-only)
            OPTION_POSTPROCESS='ONLY'
            shifts=$((shifts + 1))
         ;;

         --parallel)
            if [ "${MULLE_TEST_PARALLEL}" = 'NO' ]
            then
               fail "Can't use --parallel when MULLE_TEST_PARALLEL is set to NO (MULLE_TEST_PARALLEL)"
            fi
            OPTION_PARALLEL='YES'
            shifts=$((shifts + 1))
         ;;

         --parsed-argument-count)
            printf "%d\n" "${shifts}"
         ;;

         --path-prefix)
            [ $# -lt 2 ] && fail "Missing argument for $1"
            shift
            OPTION_PATH_PREFIX="$1"
            shifts=$((shifts + 2))
         ;;

         --platform)
            [ $# -lt 2 ] && fail "Missing argument for $1"
            shift
            OPTION_PLATFORM="$1"
            shifts=$((shifts + 2))
         ;;

         --postprocess)
            OPTION_POSTPROCESS='YES'
            shifts=$((shifts + 1))
         ;;

         --print-exe)
            OPTION_PRINT_EXE='YES'
            shifts=$((shifts + 1))
         ;;

         --project-dialect)
            [ $# -lt 2 ] && fail "Missing argument for $1"
            shift
            OPTION_PROJECT_DIALECT="$1"
            shifts=$((shifts + 2))
         ;;

         --project-extensions)
            [ $# -lt 2 ] && fail "Missing argument for $1"
            shift
            OPTION_PROJECT_EXTENSIONS="$1"
            shifts=$((shifts + 2))
         ;;

         --project-language)
            [ $# -lt 2 ] && fail "Missing argument for $1"
            shift
            OPTION_PROJECT_LANGUAGE="$1"
            shifts=$((shifts + 2))
         ;;

         --release)
            OPTION_CONFIGURATION='Release'
            shifts=$((shifts + 1))
         ;;

         --rerun|--rerun-failed)
            OPTION_RERUN='YES'
            shifts=$((shifts + 1))
         ;;

         --reuse-exe)
            # this passed "silently" to mulle-test-execute... ugly
            OPTION_REUSE_EXE='YES'
            OPTION_REMOVE_EXE='NO'
            shifts=$((shifts + 1))
         ;;

         --sanitize-address)
            OPTION_SANITIZER='address'
            shifts=$((shifts + 1))
         ;;

         --sanitize-leak)
            OPTION_SANITIZER='leak'
            shifts=$((shifts + 1))
         ;;

         --sanitize-thread)
            OPTION_SANITIZER='thread'
            shifts=$((shifts + 1))
         ;;

         --sanitize-undefined)
            OPTION_SANITIZER='undefined'
            shifts=$((shifts + 1))
         ;;

         --standalone)
            OPTION_STANDALONE='YES'
            shifts=$((shifts + 1))
         ;;

         --timeout)
            [ $# -lt 2 ] && fail "Missing argument for $1"
            shift
            OPTION_TIMEOUT="$1"
            shifts=$((shifts + 2))
         ;;

         --valgrind)
            OPTION_VALGRIND='YES'
            shifts=$((shifts + 1))
         ;;

         --)
            shifts=$((shifts + 1))
            break
         ;;

         -h*|--help|help)
            # dont consume
            rc=2
            break
         ;;

         -*)
            fail "Unknown option: $1"
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   log_debug "parsed ${shifts} arguments, $# remain"
   RVAL=${shifts}
}

:
