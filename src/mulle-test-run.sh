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
MULLE_TEST_RUN_SH="included"



test_run_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} run [options] [test]

   You may optionally specify a source test file, to only run that specific
   test.

   Options:
      -l  : be linient, keep going if tests fail
      -q  : quiet
      -t  : shell trace
      -v  : verbose
      -V  : show commands
EOF
   exit 1
}


#
# this is system wide, not so great
# and also not trapped...
#
suppress_crashdumping()
{
   log_entry "suppress_crashdumping" "$@"

   local restore

   case "${MULLE_UNAME}" in
      darwin)
         restore="`defaults read com.apple.CrashReporter DialogType 2> /dev/null`"
         defaults write com.apple.CrashReporter DialogType none
         ;;
   esac

   echo "${restore}"
}


restore_crashdumping()
{
   log_entry "restore_crashdumping" "$@"

   local restore="$1"

   case "${MULLE_UNAME}" in
      darwin)
         if [ -z "${restore}" ]
         then
            defaults delete com.apple.CrashReporter DialogType
         else
            defaults write com.apple.CrashReporter DialogType "${restore}"
         fi
      ;;
   esac
}


trace_ignore()
{
   log_entry "trace_ignore" "$@"

   restore_crashdumping "$1"
   return 0
}


#
#
#
maybe_show_diagnostics()
{
   log_entry "maybe_show_diagnostics" "$@"

   local errput="$1"

   local contents

   contents="`head -2 "${errput}"`" 2> /dev/null
   if [ ! -z "${contents}" ]
   then
      log_info "DIAGNOSTICS:" >&2
      cat "${errput}" >&2
   fi
}


maybe_show_output()
{
   log_entry "maybe_show_output" "$@"

   local output="$1"

   local contents

   contents="`head -2 "${output}"`" 2> /dev/null
   if [ "${contents}" != "" ]
   then
      log_info "OUTPUT:"
      cat "${output}"
   fi
}


run_common_test()
{
   log_entry "run_common_test" "$@"

   local a_out="$1"; shift
   local name="$1"; shift
   local ext="$1"; shift
   local root="$1"; shift

   [ -z "${a_out}" ] && internal_fail "a_out must not be empty"
   [ -z "${name}" ] && internal_fail "name must not be empty"
   [ -z "${root}" ] && internal_fail "root must not be empty"

   local output
   local cc_errput
   local errput
   local random
   local match
   local pretty_source

   local srcfile

   srcfile="${name}${ext}"

   local cc_errput
   local random

   random="`make_tmp_file "${name}"`" || exit 1

   cc_errput="${random}.ccerr"
   r_relative_path_between "${PWD}/${srcfile}" "${root}"
   pretty_source="${RVAL}" || exit 1

   local rval
   local a_out_ext

   log_fluff "Build test ${pretty_source}"

   a_out_ext="${a_out}${EXE_EXTENSION}"

   "${TEST_BUILDER}" "${srcfile}" "${a_out_ext}" "${cc_errput}" "$@"
   rval="$?"

   check_compiler_output "${srcfile}" "${cc_errput}" "${rval}" "${pretty_source}"
   rval="$?"

   if [ "$rval" -ne 0 ]
   then
      if [ ${RVAL_EXPECTED_FAILURE} = $rval ]
      then
         return 0
      fi

      log_debug "Compiler failure returns with $rval"
      return $rval
   fi

   log_verbose "Run test ${pretty_source}"

   test_execute_main --pretty "${pretty_source}" "${a_out_ext}" "${srcfile}"

   rval=$?
   if [ ${RVAL_EXPECTED_FAILURE} = $rval ]
   then
      return 0
   fi

   if [ "${rval}" -ne 0 ]
   then
      if [ "${MULLE_TEST_CONFIGURATION}" != "Debug" ]
      then
         a_out_ext="${a_out}${DEBUG_EXE_EXTENSION}"
      fi

      "${FAIL_TEST}" "${srcfile}" "${a_out_ext}" "${ext}" "${name}" "$@"
   fi

   log_debug "Execute failure returns with $rval"
   return $rval
}


run_cmake_test()
{
   log_entry "run_cmake_test" "$@"

   local name="$1"

   local a_out

   a_out="${PWD}/${name}"

   TEST_BUILDER="run_cmake"
   FAIL_TEST="fail_test_cmake"
   run_common_test "${a_out}" "$@"
}


run_c_test()
{
   log_entry "run_c_test" "$@"

   local name="$1"
   local ext="$2"

   local a_out

   a_out="${PWD}/${name}"

   TEST_BUILDER="run_compiler"
   FAIL_TEST="fail_test_c"
   run_common_test "${a_out}" "$@"
}


run_m_test()
{
   log_entry "run_m_test" "$@"

   run_c_test "$@"
}


run_cpp_test()
{
   log_entry "run_cpp_test" "$@"

   log_error "$1: cpp testing is not available yet"
}


# we are in the test directory
#
# testname: is either the test.m or "" for Makefile
# runtest : is where the user started the search, its only used for printing
# ext     : extension of the file used for tmp filename construction
#
_run_test()
{
   log_entry "_run_test" "$@"

   local name="$1"; shift
   local ext="$1"; shift
   local root="$1"; shift

   [ -z "${name}" ] && internal_fail "name must not be empty"
   [ -z "${ext}" ] && internal_fail "ext must not be ? empty"
   [ -z "${root}" ] && internal_fail "root must not be empty"

   # this is OK since we are in a subshell here
   local envfile

   envfile=".mulle-test/etc/environment.sh"
   if [ -f "${envfile}" ]
   then
      . "${envfile}" || fail "\"${envfile}\" read failed"
      log_fluff "Read environment file \"${envfile}\" "
   fi

   case "${ext}" in
      cmake)
         run_cmake_test "${name}" "" "${root}" "$@"
      ;;

      .m|.aam)
         run_m_test "${name}" "${ext}" "${root}" "$@"
      ;;

      .c)
         run_c_test "${name}" "${ext}" "${root}" "$@"
      ;;

      .cxx|.cpp)
         run_cpp_test "${name}" "${ext}" "${root}" "$@"
      ;;
   esac
}


handle_return_value()
{
   log_entry "handle_return_value" "$@"

   local rval=$1; shift

   local directory="$1"
   local name="$2"
   local ext="$3"
   local root="$4"

   log_debug "Return value of _run_test: ${rval}"

   case "${rval}" in
      0|${RVAL_EXPECTED_FAILURE})
      ;;

      ${RVAL_INTERNAL_ERROR})
         fail "Test exited due to internal problems (assert, crasher)"
      ;;

      *)
         FAILS=$((FAILS + 1))
         if [ "${OPTION_LENIENT}" != 'YES' ]
         then
            local pretty_source

            r_relative_path_between "${PWD}/${name}" "${root}"
            pretty_source="${RVAL}"

            fail "Test \"${TEST_PATH_PREFIX}${pretty_source}\" failed ($rval)"
         fi
      ;;
   esac
}


_run_test_in_directory()
{
   log_entry "_run_test_in_directory" "$@"

   local directory="$1"; shift

   (
      cd "${directory}" &&
      _run_test "$@"
   )
}


run_test_in_directory()
{
   log_entry "run_test_in_directory" "$@"

   if [ "${MULLE_TEST_SERIAL}" = 'NO' ]
   then
      _parallel_execute _run_test_in_directory "$@"
      return 0
   fi

   RUNS="$((RUNS + 1))"
   _run_test_in_directory "$@"
   handle_return_value $? "$@"
}


run_test_matching_extensions_in_directory()
{
   log_entry "run_test_matching_extensions_in_directory" "$@"

   local directory="$1"; shift
   local filename="$1"; shift
   local extensions="$1"; shift
   local root="$1"; shift

   local name
   local ext
   local RVAL

   IFS=":"; set -f
   for ext in ${extensions}
   do
      IFS="${DEFAULT_IFS}"; set +f
      ext=".${ext}"

      case "${filename}" in
         *${ext})
            r_extensionless_basename "${filename}"
            run_test_in_directory "${directory}" \
                                  "${RVAL}" \
                                  "${ext}" \
                                  "${root}" \
                                  "$@"
            return $?
         ;;
      esac
   done
   IFS="${DEFAULT_IFS}"; set +f
}


_scan_directory()
{
   log_entry "_scan_directory" "$@"

   local root="$1"; shift
   local extensions="$1"; shift

   local RVAL

   if [ -f CMakeLists.txt ]
   then
      r_fast_basename "${PWD}"
      run_test_in_directory "${PWD}" "${RVAL}" "cmake" "${root}" "$@"
      return $?
   fi

   log_fluff "Scanning \"${PWD}\" for files with extensions \"${extensions}\"..."

   local i

   IFS="
"
   for i in `ls -1`
   do
      IFS="${DEFAULT_IFS}"

      case "${i}" in
         _*|addiction|bin|build|craftinfo|dependency|include|lib|libexec|old|stash|tmp)
            log_debug "Ignoring $i because it's surely not a test directory"
            continue
         ;;
      esac

      if [ -d "${i}" ]
      then
         if ! scan_directory "${i}" "${root}" "${extensions}" "$@"
         then
            return 1
         fi
      else
         if ! run_test_matching_extensions_in_directory "${PWD}" \
                                                        "${i}" \
                                                        "${extensions}" \
                                                        "${root}" \
                                                        "$@"
         then
            return 1
         fi
      fi
   done

   IFS="${DEFAULT_IFS}"
   return 0
}


scan_directory()
{
   log_entry "scan_directory" "$@"

   local directory="$1"; shift
   local root="$1"; shift
   local extensions="$1"; shift

   [ -z "${directory}" ] && internal_fail "directory must not be empty"
   [ ! -d "${directory}" ] && internal_fail "directory \"${directory}\" does not exist"
   [ -z "${root}" ] && internal_fail "root must not be empty"

   local old
   local rval

   # preserve shell context (no subshell here)
   old="$PWD"

   rexekutor cd "${directory}" && _scan_directory "${root}" "${extensions}" "$@"
   rval=$?

   cd "${old}"
   return $rval
}


run_all_tests()
{
   log_entry "run_all_tests" "$@"

   local RUNS
   local FAILS

   RUNS=0
   FAILS=0

   local _parallel_maxjobs
   local _parallel_jobs
   local _parallel_fails
   local _parallel_statusfile

   if [ "${MULLE_TEST_SERIAL}" = 'NO' ]
   then
      [ -z "${MULLE_PARALLEL_SH}" ] && \
         . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-parallel.sh"

      log_verbose "Parallel testing"
      _parallel_begin "${OPTION_MAXJOBS}"
   else
      log_verbose "Serial testing"
   fi

   scan_directory "${PWD}" "${MULLE_USER_PWD}" "${PROJECT_EXTENSIONS}" "$@"

   if [ "${MULLE_TEST_SERIAL}" = 'NO' ]
   then
      _parallel_end

      RUNS="${_parallel_jobs}"
      FAILS="${_parallel_fails}"
   fi

   if [ "${RUNS}" -ne 0 ]
   then
      if [ "${FAILS}" -eq 0 ]
      then
         log_info "All tests (${RUNS}) passed successfully"
      else
         log_error "${FAILS} tests out of ${RUNS} failed"
         return 1
      fi
   else
      log_warning "No tests found in ${PWD} with extensions ${PROJECT_EXTENSIONS}"
   fi
}


run_named_test()
{
   log_entry "run_named_test" "$@"

   local root="$1"; shift
   local path="$1"; shift

   local RVAL

   if ! is_absolutepath "${path}"
   then
      r_filepath_concat "${root}" "${path}"
      path="${RVAL}"
   fi

   if [ ! -e "${path}" ]
   then
      fail "Test \"${TEST_PATH_PREFIX}${path}\" not found"
   fi

   if [ -d "${path}" ]
   then
      scan_directory "${path}" "${root}" "${PROJECT_EXTENSIONS}" "$@"
      return $?
   fi

   if [ -x "${path}" ]
   then
      fail "Specify the source file not a binary \"${TEST_PATH_PREFIX}${path}\""
   fi

   local directory
   local filename

   r_fast_dirname "${path}"
   directory="${RVAL}"
   r_fast_basename "${path}"
   filename="${RVAL}"

   local RUNS=0
   local FAILS=0

   run_test_matching_extensions_in_directory "${directory}" \
                                             "${filename}" \
                                             "${PROJECT_EXTENSIONS}" \
                                             "${root}" \
                                             "$@"
}


test_run_main()
{
   log_entry "test_run_main" "$@"

   if [ -z "${MULLE_TEST_ENVIRONMENT_SH}" ]
   then
      . "${MULLE_TEST_LIBEXEC_DIR}/mulle-test-environment.sh"
   fi

   include_required

   local DEFAULT_MAKEFLAGS
   local OPTION_REQUIRE_LIBRARY="YES"
   local OPTION_LENIENT='NO'
   local OPTION_TESTALLOCATOR="YES"

   DEFAULT_MAKEFLAGS="-s"

   setup_project "${MULLE_UNAME}"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|--help|help)
            test_run_usage
         ;;

         -l|--lenient)
            OPTION_LENIENT="YES"
         ;;

         -V)
            DEFAULT_MAKEFLAGS="VERBOSE=1"
            MULLE_FLAG_LOG_EXEKUTOR="YES"
         ;;

         -j|--jobs)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            OPTION_MAXJOBS="$1"
         ;;

         --no-testallocator)
            OPTION_TESTALLOCATOR="NO"
         ;;

         --configuration)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            MULLE_TEST_CONFIGURATION="$1"
         ;;

         --debug)
            MULLE_TEST_CONFIGURATION='Debug'
         ;;

         --release)
            MULLE_TEST_CONFIGURATION='Release'
         ;;

         --project-language)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            if [ "$1" != "${PROJECT_LANGUAGE}" ]
            then
               PROJECT_LANGUAGE="$1"
               PROJECT_EXTENSIONS=""
            fi
         ;;

         --project-dialect)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            if [ "$1" != "${PROJECT_DIALECT}" ]
            then
               PROJECT_DIALECT="$1"
               PROJECT_EXTENSIONS=""
            fi
         ;;

         --project-extensions)
            [ $# -eq 1 ] && test_run_usage "Missing argument to \"$1\""
            shift

            PROJECT_EXTENSIONS="$1"
         ;;

         --path-prefix)
            shift
            [ $# -eq 0 ] && test_run_usage

            TEST_PATH_PREFIX="$1"
         ;;

         --serial)
            MULLE_TEST_SERIAL='YES'
         ;;

         --parallel)
            MULLE_TEST_SERIAL='NO'
         ;;

         --run-args)
            shift
            break
         ;;

         --build-args)
            # remove build-only flags, which must appear first
            while [ $# -ne 0 ]
            do
               if [ "$1" == "--run-args" ]
               then
                  continue
               fi
               shift
            done
         ;;

         --)
            shift
            break
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   case "${MULLE_TEST_CONFIGURATION}" in
   	'Debug')
         CFLAGS="${DEBUG_CFLAGS}"
      ;;

      *)
         CFLAGS="${RELEASE_CFLAGS}"
      ;;
	esac

   local format

   case "${MULLE_UNAME}" in
      darwin)
         format="force-load"
      ;;

      mingw*)
         format="whole-archive-win"
      ;;

      *)
         format="whole-archive"
      ;;
   esac

   if ! LINK_COMMAND="`rexekutor mulle-sde \
   										${MULLE_TECHNICAL_FLAGS} \
   										${MULLE_SDE_FLAGS} \
   								linkorder \
   									--output-format ld \
                              --whole-archive-format "${format}"`"
   then
      fail "Can't get linkorder. Maybe rebuild with
   ${C_RESET_BOLD}mulle-test build"
   fi

   local RVAL_INTERNAL_ERROR=1
   local RVAL_FAILURE=2
   local RVAL_OUTPUT_DIFFERENCES=3
   local RVAL_EXPECTED_FAILURE=4
   local RVAL_IGNORED_FAILURE=5

   local HAVE_WARNED="NO"

   if [ "$RUN_ALL" = "YES" -o $# -eq 0 -o "${1:0:1}" = '-' ]
   then
      MULLE_TEST_SERIAL="${MULLE_TEST_SERIAL:-NO}"
      run_all_tests "$@"
      return $?
   fi

   MULLE_TEST_SERIAL='YES'
   if ! run_named_test "${MULLE_USER_PWD}" "$@"
   then
      return 1
   fi
}

