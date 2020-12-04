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
      -l         : be lenient, keep going if tests fail
      --serial   : run test one after the other
      --keep-exe : keep test executables around after a successful test
EOF
   exit 1
}


#
# this is system wide, not so great
# and also not trapped...
#
r_suppress_crashdumping()
{
   log_entry "r_suppress_crashdumping" "$@"

   local restore

   case "${MULLE_UNAME}" in
      darwin)
         restore="`defaults read com.apple.CrashReporter DialogType 2> /dev/null`"
         defaults write com.apple.CrashReporter DialogType none
         ;;
   esac

   RVAL="${restore}"
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
#
#   local errput="$1"
#
#   local contents
#
#
# may not be needed anymore since we compile with "grep" now
#

#   contents="`head -2 "${errput}"`" 2> /dev/null
#   if [ ! -z "${contents}" ]
#   then
#      log_info "DIAGNOSTICS:" >&2
#      cat "${errput}" >&2
#   fi
}


maybe_show_output()
{
   log_entry "maybe_show_output" "$@"

   local output="$1"

   local contents

   if file_is_binary "${output}"
   then
      return
   fi

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

   local args="$1"; shift
   local a_out="$1"; shift
   local a_out_ext="$1"; shift
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

   _r_make_tmp_in_dir "${MULLE_TEST_VAR_DIR}/tmp" "${name}.ccerr" "f"
   cc_errput="${RVAL}" || exit 1

   r_relative_path_between "${PWD}/${srcfile}" "${root}"
   pretty_source="${RVAL}" || exit 1

   local rval
   local flags

   if [ ! -z "${TEST_BUILDER}" ]
   then
      log_fluff "Build test ${pretty_source}"

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
         cat "${cc_errput}" >&2
         return $rval
      fi
   else
      flags="--keep-exe"
   fi

   log_verbose "Run test ${pretty_source}"

   local cmd

   cmd="test_execute_main"
   if [ ! -z "${flags}" ]
   then
       cmd="${cmd} ${flags}"
   fi
   if [ ! -z "${args}" ]
   then
      cmd="${cmd} --args '${args}'"
   fi
   if [ ! -z "${pretty_source}" ]
   then
      cmd="${cmd} --pretty '${pretty_source}'"
   fi
   cmd="${cmd} '${a_out_ext}'"
   cmd="${cmd} '${srcfile}'"

   eval "${cmd}"
   rval=$?

   if [ ${RVAL_EXPECTED_FAILURE} = $rval ]
   then
      return 0
   fi

   if [ ! -z "${FAIL_TEST}" ]
   then
      if [ "${rval}" -ne 0 ]
      then
         a_out_ext="${a_out}${DEBUG_EXE_EXTENSION}"

         "${FAIL_TEST}" "${srcfile}" "${a_out_ext}" "${ext}" "${name}" "$@"
      fi
   else
      log_debug "FAIL_TEST is undefined"
   fi

   log_debug "Execute failure, returns with $rval"
   return $rval
}


run_cmake_test()
{
   log_entry "run_cmake_test" "$@"

   local name="$1"; shift

   local a_out
   local purename

   # remove leading 20_ or 20-
   purename="${name#"${name%%[!0-9_-]*}"}"
   a_out="${PWD}/${purename}"

   if r_get_test_environmentfile "${purename}" "cmake-output" "cmake-output"
   then
      a_out="`egrep -v '^#' "${RVAL}"`"
   fi

   TEST_BUILDER="run_cmake"
   FAIL_TEST="fail_test_cmake"
   run_common_test "" "${a_out}" "${a_out}${EXE_EXTENSION}" "${purename}" "$@"
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
   run_common_test "" "${a_out}" "${a_out}${EXE_EXTENSION}" "$@"
}


run_exe_test()
{
   log_entry "run_exe_test" "$@"

   local name="$1"
   local ext="$2"

   local a_out
   local a_out_ext

   a_out="${DEPENDENCY_DIR}/bin/${MULLE_TEST_EXECUTABLE}"
   case "${MULLE_UNAME}" in
      mingw|windows)
         a_out="${a_out}${EXE_EXTENSION}"
      ;;

      *)
         a_out_ext="${a_out}"
      ;;
   esac

   TEST_BUILDER=""
   FAIL_TEST=""

   run_common_test "" "${a_out}" "${a_out_ext}" "$@"
}


run_args_exe_test()
{
   log_entry "run_args_exe_test" "$@"

   local args="$1"; shift

   local name="$1"
   local ext="$2"

   local a_out
   local a_out_ext

   a_out="${DEPENDENCY_DIR}/bin/${MULLE_TEST_EXECUTABLE}"
   case "${MULLE_UNAME}" in
      mingw|windows)
         a_out="${a_out}${EXE_EXTENSION}"
      ;;

      *)
         a_out_ext="${a_out}"
      ;;
   esac

   TEST_BUILDER=""
   FAIL_TEST=""

   run_common_test "${args}" "${a_out}" "${a_out_ext}" "$@"
}


run_m_test()
{
   log_entry "run_m_test" "$@"

   run_c_test "$@"
}


run_aam_test()
{
   log_entry "run_aam_test" "$@"

   run_m_test "$@"
}


run_h_test()
{
   log_entry "run_h_test" "$@"

   run_args_exe_test "${name}${ext}" "$@"
}


run_cpp_test()
{
   log_entry "run_cpp_test" "$@"

   log_error "$1: cpp testing is not available yet"
}


run_cxx_test()
{
   log_entry "run_cxx_test" "$@"

   run_cpp_test "$@"
}


r_get_test_environmentfile()
{
   local varname="$1"
   local name="$2"
   local fallback="$3"

   RVAL="${name}.${varname}.${MULLE_UNAME}.${MULLE_ARCH}"
   if rexekutor [ ! -f "${RVAL}" ]
   then
      RVAL="${name}.${varname}.${MULLE_UNAME}"
      if rexekutor [ ! -f "${RVAL}" ]
      then
         RVAL="${name}.${varname}.${MULLE_ARCH}"
         if rexekutor [ ! -f "${RVAL}" ]
         then
            RVAL="${name}.${varname}"
            if rexekutor [ ! -f "${RVAL}" ]
            then
               RVAL="default.${varname}.${MULLE_UNAME}.${MULLE_ARCH}"
               if rexekutor [ ! -f "${RVAL}" ]
               then
                  RVAL="default.${varname}.${MULLE_UNAME}"
                  if rexekutor [ ! -f "${RVAL}" ]
                  then
                     RVAL="default.${varname}.${MULLE_ARCH}"
                     if rexekutor [ ! -f "${RVAL}" ]
                     then
                        RVAL="default.${varname}"
                        if rexekutor [ ! -f "${RVAL}" ]
                        then
                           RVAL="${fallback}"
                           if rexekutor [ ! -f "${RVAL}" ]
                           then
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
   return 0
}


# we are in the test directory and we are running in a subshell
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
   [ -z "${ext}" ]  && internal_fail "ext must not be ? empty"
   [ -z "${root}" ] && internal_fail "root must not be empty"

   if r_get_test_environmentfile "${name}" "environment" "environment"
   then
      log_fluff "Read environment file \"${RVAL}\" (${PWD#${MULLE_USER_PWD}/}) "
      # as we are running in a subshell this is OK
      . "${RVAL}" || fail "\"${RVAL}\" read failed"
   fi

   case "${ext}" in
      cmake)
         run_cmake_test "${name}" "" "${root}" "$@"
      ;;

      .args)
         run_exe_test "${name}" "${ext}" "${root}" "$@"
      ;;

      *)
         local functionname

         functionname="run_${ext#.}_test"
         if [ "`type -t "${functionname}"`" != "function" ]
         then
             fail "Don't know how to handle extension \"${ext}\""
         fi
         "${functionname}" "${name}" "${ext}" "${root}" "$@"
      ;;
   esac
}


has_test_run_successfully()
{
   log_entry "has_test_run_successfully" "$@"

   local directory="$1"
   local name="$2"

   if [ ! -z "${MULLE_TEST_SUCCESS_FILE}" ]
   then
      rexekutor fgrep -s -q -x "${directory}/${name}" "${MULLE_TEST_SUCCESS_FILE}"
      return $?
   fi
   return 1
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
         if [ ! -z "${MULLE_TEST_SUCCESS_FILE}" ]
         then
            redirect_append_exekutor "${MULLE_TEST_SUCCESS_FILE}" \
               printf "%s\n" "${directory}/${name}"
         fi
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
   local name="$1"

   (
      # this is OK since we are in a subshell here
      cd "${directory}" || exit 1

      _run_test "$@"
   )
}


_run_test_in_directory_parallel()
{
   log_entry "_run_test_in_directory_parallel" "$@"

   local directory="$1"; shift

   (
      cd "${directory}" || exit 1
      _run_test "$@"
      handle_return_value $? "${directory}" "$@"
   )
}


run_test_in_directory()
{
   log_entry "run_test_in_directory" "$@"

   if has_test_run_successfully "$@"
   then
      log_fluff "Test $2 already passed"
      return 0
   fi

   if [ "${MULLE_TEST_SERIAL}" = 'NO' ]
   then
      _parallel_execute _run_test_in_directory_parallel "$@"
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

   IFS=':'; set -f
   for ext in ${extensions}
   do
      set +o noglob; IFS="${DEFAULT_IFS}"
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
   set +o noglob; IFS="${DEFAULT_IFS}"
}


_scan_directory()
{
   log_entry "_scan_directory" "$@" "($PWD)"

   local root="$1"; shift
   local extensions="$1"; shift

   if [ -f CMakeLists.txt ]
   then
      r_basename "${PWD}"
      run_test_in_directory "${PWD}" "${RVAL}" "cmake" "${root}" "$@"
      return $?
   fi

   log_fluff "Scanning \"${PWD}\" for files with extensions \"${extensions}\"..."

   local i

   IFS=$'\n'
   for i in `ls -1`
   do
      IFS="${DEFAULT_IFS}"

      case "${i}" in
         _*|addiction|bin|build|kitchen|craftinfo|dependency|include|lib|libexec|old|stash|tmp)
            log_debug "Ignoring \"${i}\" because it's surely not a test directory"
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

   scan_directory "${PWD}" "${MULLE_USER_PWD}" "${MULLE_TEST_EXTENSIONS}" "$@"

   if [ "${MULLE_TEST_SERIAL}" = 'NO' ]
   then
      _parallel_end

      RUNS="${_parallel_jobs}"
      FAILS="${_parallel_fails}"
   fi

   if [ "${RUNS}" -ne 0 -o "${OPTION_RERUN_FAILED}" = 'YES' ]
   then
      if [ "${FAILS}" -eq 0 ]
      then
         log_info "All tests (${RUNS}) passed successfully"
      else
         log_error "${FAILS} tests out of ${RUNS} failed"
         return 1
      fi
   else
      log_warning "No tests found in ${PWD} with extensions ${MULLE_TEST_EXTENSIONS}"
   fi
}


run_named_test()
{
   log_entry "run_named_test" "$@"

   local root="$1"; shift
   local path="$1"; shift

   if ! is_absolutepath "${path}"
   then
      r_filepath_concat "${root}" "${path}"
      path="${RVAL}"
   fi

   if [ ! -e "${path}" ]
   then
      fail "Test \"${TEST_PATH_PREFIX}${path}\" not found"
   fi

   # make physical for WSL
   path="`physicalpath "$path"`"

   if [ -d "${path}" ]
   then
      scan_directory "${path}" "${root}" "${MULLE_TEST_EXTENSIONS}" "$@"
      return $?
   fi

   # not so good on windows
   case "${MULLE_UNAME}" in
      mingw*|windows)
      ;;

      *)
        # Test invalid now, since .args can be executable and are also the
        # test run target (mulle-cpp)
        #
        # if [ -x "${path}" ]
        # then
        #    fail "Specify the source file not a binary \"${TEST_PATH_PREFIX}${path}\""
        # fi
      ;;
   esac

   local directory
   local filename

   r_dirname "${path}"
   directory="${RVAL}"
   r_basename "${path}"
   filename="${RVAL}"

   local RUNS=0
   local FAILS=0

   if ! run_test_matching_extensions_in_directory "${directory}" \
                                                  "${filename}" \
                                                  "${MULLE_TEST_EXTENSIONS}" \
                                                  "${root}" \
                                                  "$@"
   then
      return 1
   fi

   if [ ${RUNS} -eq 0 ]
   then
      fail "Could not find \"${filename}\" with matching extensions MULLE_TEST_EXTENSIONS \"${MULLE_TEST_EXTENSIONS}\""
   fi
}


test_run_main()
{
   log_entry "test_run_main" "$@"

   if [ -z "${MULLE_TEST_ENVIRONMENT_SH}" ]
   then
      . "${MULLE_TEST_LIBEXEC_DIR}/mulle-test-environment.sh"
   fi

   test_include_required

   local DEFAULT_MAKEFLAGS
   local OPTION_REQUIRE_LIBRARY="YES"
   local OPTION_LENIENT='NO'
   local OPTION_RERUN_FAILED='NO'
   local OPTION_DEBUG_DYLD='NO'

   DEFAULT_MAKEFLAGS="-s"

   test_setup_project "${MULLE_UNAME}"
   TEST_CFLAGS="${RELEASE_CFLAGS}"

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

         # don't make MULLE_TEST_SERIAL local so we can put it into env
         --serial|--no-parallel)
            MULLE_TEST_SERIAL='YES'
         ;;

         --parallel)
            MULLE_TEST_SERIAL='NO'
         ;;

         --rerun|--rerun-failed)
            OPTION_RERUN_FAILED='YES'
         ;;

         --run-args)
            shift
            break
         ;;

         --extensions)
            [ $# -eq 1 ] && test_run_usage "Missing argument to \"$1\""
            shift

            MULLE_TEST_EXTENSIONS="$1"
         ;;

         --release)
            TEST_CFLAGS="${RELEASE_CFLAGS}"
         ;;

         --debug)
            TEST_CFLAGS="${DEBUG_CFLAGS}"
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

         --keep-exe)
            # this passed "silently" to mulle-test-execute... ugly
            OPTION_REMOVE_EXE='NO'
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

   [ -z "${MULLE_TEST_DIR}" ] && internal_fail "MULLE_TEST_DIR undefined"
   [ -z "${MULLE_TEST_VAR_DIR}" ] && internal_fail "MULLE_TEST_VAR_DIR undefined"

   MULLE_TEST_EXTENSIONS="${MULLE_TEST_EXTENSIONS:-${PROJECT_EXTENSIONS}}"

   local RVAL_INTERNAL_ERROR=1
   local RVAL_FAILURE=2
   local RVAL_OUTPUT_DIFFERENCES=3
   local RVAL_EXPECTED_FAILURE=4
   local RVAL_IGNORED_FAILURE=5

   local HAVE_WARNED="NO"

   . "${MULLE_TEST_LIBEXEC_DIR}/mulle-test-linkorder.sh"

   r_get_link_command "YES"
   LINK_COMMAND="${RVAL}"

   r_get_link_command "NO"
   NO_STARTUP_LINK_COMMAND="${RVAL}"

   MULLE_TEST_SUCCESS_FILE="${MULLE_TEST_VAR_DIR}/passed.txt"

   if [ "$RUN_ALL" = "YES" -o $# -eq 0 -o "${1:0:1}" = '-' ]
   then
      if [ "${OPTION_RERUN_FAILED}" = 'NO' ]
      then
         remove_file_if_present "${MULLE_TEST_SUCCESS_FILE}"
      fi

      MULLE_TEST_SERIAL="${MULLE_TEST_SERIAL:-NO}"
      run_all_tests "$@"
      return $?
   fi

   MULLE_TEST_SERIAL='YES'
   MULLE_TEST_SUCCESS_FILE=""
   if ! run_named_test "${MULLE_USER_PWD}" "$@"
   then
      return 1
   fi
}

