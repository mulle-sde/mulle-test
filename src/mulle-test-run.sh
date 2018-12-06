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



#####################################################################
# main
#
# if you really want to, you can also specify the LIB_EXTENSION as
# .a, and then pass in the link dependencies as LDFLAGS. But is it
# easier, than a shared library ?
#
usage()
{
   cat <<EOF >&2
usage:
   mulle-test run [options] [test]

   You may optionally specify a source test file, to run
   only that test.

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

   local a_out="$1"
   local name="$2"
   local ext="$3"
   local root="$4"

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

   log_info "${TEST_PATH_PREFIX}${pretty_source}"

   local rval
   local a_out_ext

   log_verbose "Build test"

   a_out_ext="${a_out}${EXE_EXTENSION}"

   "${TEST_BUILDER}" "${srcfile}" "${a_out_ext}" "${cc_errput}"
   rval="$?"

   check_compiler_output "${srcfile}" "${cc_errput}" "${rval}" "${pretty_source}"
   rval="$?"

   if [ "$rval" -ne 0 ]
   then
      return $rval
   fi

   log_verbose "Run test"

   test_execute_main "${a_out_ext}" "${srcfile}"

   rval=$?
   if [ "${rval}" -ne 0 ]
   then
      if [ "${MULLE_TEST_CONFIGURATION}" != "Debug" ]
      then
         a_out_ext="${a_out}${DEBUG_EXE_EXTENSION}"
      fi

      "${FAIL_TEST}" "${srcfile}" "${a_out_ext}" "${ext}"
   fi

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

   local name="$1"
   local ext="$2"
   local root="$3"

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
         run_cmake_test "${name}" "" "${root}"
      ;;

      .m|.aam)
         run_m_test "${name}" "${ext}" "${root}"
      ;;

      .c)
         run_c_test "${name}" "${ext}" "${root}"
      ;;

      .cxx|.cpp)
         run_cpp_test "${name}" "${ext}" "${root}"
      ;;
   esac
}


run_test_in_directory()
{
   log_entry "run_test_in_directory" "$@"

   local name="$1"
   local ext="$2"
   local directory="$3"
   local root="$4"

   local rval
   local RVAL

   RUNS="`expr "$RUNS" + 1`"
   (
      cd "${directory}" &&
      _run_test "${name}" "${ext}" "${root}"
   )
   rval="$?"

   log_debug "Return value of _run_test: ${rval}"

   case "${rval}" in
      0|${RVAL_EXPECTED_FAILURE})
      ;;

      ${RVAL_INTERNAL_ERROR})
         fail "Test exited due to internal problems (assert, crasher)"
      ;;

      *)
         FAILS="`expr "${FAILS}" + 1`"
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


run_test_matching_extensions_in_directory()
{
   log_entry "run_test_matching_extensions_in_directory" "$@"

   local filename="$1"
   local directory="$2"
   local root="$3"
   local extensions="$4"

   local name
   local ext
   local RVAL

   IFS=":"
   for ext in ${extensions}
   do
      IFS="${DEFAULT_IFS}"
      ext=".${ext}"
      case "${filename}" in
         *${ext})
            r_extensionless_basename "${filename}"
            name="${RVAL}"

            run_test_in_directory "${name}" "${ext}" "${directory}" "${root}"
            return $?
         ;;
      esac
   done
   IFS="${DEFAULT_IFS}"
}


_scan_directory()
{
   log_entry "_scan_directory" "$@"

   local root="$1"
   local extensions="$2"

   if [ -f CMakeLists.txt ]
   then
      run_test_in_directory "`fast_basename "${PWD}"`" "cmake" "$PWD" "${root}"
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
         _*|build|include|lib|bin|tmp|etc|share|stashes)
            continue
         ;;
      esac

      if [ -d "${i}" ]
      then
         if ! scan_directory "${i}" "${root}" "${extensions}"
         then
            return 1
         fi
      else
         if ! run_test_matching_extensions_in_directory "${i}" \
                                                        "${PWD}" \
                                                        "${root}" \
                                                        "${extensions}"
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

   local directory="$1"
   local root="$2"
   local extensions="$3"

   [ -z "${directory}" ] && internal_fail "directory must not be empty"
   [ ! -d "${directory}" ] && internal_fail "directory \"${directory}\" does not exist"
   [ -z "${root}" ] && internal_fail "root must not be empty"

   local old
   local rval

   old="$PWD"
   rexekutor cd "${directory}" && _scan_directory "${root}" "${extensions}"
   rval=$?
   rexekutor cd "${old}"

   return $rval
}


run_named_test()
{
   log_entry "run_named_test" "$@"

   local path="$1"
   local root="$2"

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
      scan_directory "${path}" "${root}" "${PROJECT_EXTENSIONS}"
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

   run_test_matching_extensions_in_directory "${filename}" \
                                             "${directory}" \
                                             "${root}" \
                                             "${PROJECT_EXTENSIONS}"
}


run_all_tests()
{
   log_entry "run_all_tests" "$@"

   local RUNS=0
   local FAILS=0

   scan_directory "${PWD}" "${MULLE_USER_PWD}" "${PROJECT_EXTENSIONS}"

   if [ "$RUNS" -ne 0 ]
   then
      if [ "${FAILS}" -eq 0 ]
      then
         log_info "All tests ($RUNS) passed successfully"
      else
         log_error "$FAILS tests out of $RUNS failed"
         return 1
      fi
   else
      log_warning "No tests found in ${PWD} with extensions ${PROJECT_EXTENSIONS}"
   fi
}


run_main()
{
   log_entry "run_main" "$@"

   local flags="$1" ; shift
   local options="$1"; shift

   if [ -z "${MULLE_TEST_ENVIRONMENT_SH}" ]
   then
      . "${MULLE_TEST_LIBEXEC_DIR}/mulle-test-environment.sh"
   fi

   include_required

   local DEFAULT_MAKEFLAGS
   local OPTION_REQUIRE_LIBRARY="YES"
   local OPTION_LIBRARY_FILE
   local OPTION_LENIENT='NO'

   DEFAULT_MAKEFLAGS="-s"

   setup_project "${MULLE_UNAME}"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|--help|help)
            usage
         ;;

         -l|--lenient)
            OPTION_LENIENT="YES"
         ;;

         -V)
            DEFAULT_MAKEFLAGS="VERBOSE=1"
            MULLE_FLAG_LOG_EXEKUTOR="YES"
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

         --path-prefix)
            shift
            [ $# -eq 0 ] && usage

            TEST_PATH_PREFIX="$1"
         ;;

         --no-library)
            OPTION_REQUIRE_LIBRARY="NO"
         ;;

         --library-file)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            OPTION_LIBRARY_FILE="$1"
         ;;

         -*)
            fail "Unknown run option \"$1\""
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

   setup_user "${MULLE_UNAME}"
   setup_library "${MULLE_UNAME}" "${OPTION_LIBRARY_FILE}" "${OPTION_REQUIRE_LIBRARY}"

   local RVAL_INTERNAL_ERROR=1
   local RVAL_FAILURE=2
   local RVAL_OUTPUT_DIFFERENCES=3
   local RVAL_EXPECTED_FAILURE=4
   local RVAL_IGNORED_FAILURE=5

   local HAVE_WARNED="NO"

   if [ "$RUN_ALL" = "YES" -o $# -eq 0 ]
   then
      run_all_tests "$@"
      return $?
   fi

   while [ $# -ne 0 ]
   do
      if ! run_named_test "$1" "${MULLE_USER_PWD}"
      then
         return 1
      fi
      shift
   done
}

