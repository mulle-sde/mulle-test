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
   mulle-test run [options] [tests]

   You may optionally specify a source test file, to run
   only that test.

   Options:
         -f  : keep going, if tests fail
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
   pretty_source="`relative_path_between "${PWD}/${srcfile}" "${root}"`" || exit 1

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

   test_execute_main "${a_out}" "${srcfile}"

   rval=$?
   if [ "${rval}" -ne 0 ]
   then
      a_out_ext="${a_out}${DEBUG_EXE_EXTENSION}"

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

   TEST_BUILDER=run_cmake
   FAIL_TEST=fail_test_cmake
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
         log_debug "internal problems exit"
         exit 1
      ;;

      *)
         FAILS="`expr "${FAILS}" + 1`"
         if [ "${MULLE_FLAG_MAGNUM_FORCE}" != "YES" ]
         then
            fail "Test \"${name}\" failed ($rval)"
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

   IFS=":"
   for ext in ${extensions}
   do
      IFS="${DEFAULT_IFS}"
      ext=".${ext}"
      case "${filename}" in
         *${ext})
            name="`basename -- "${filename}" "${ext}"`"
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

   log_fluff "Scanning \"${PWD}\" ..."

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

   local RUNS=0
   local FAILS=0

   local directory
   local filename

   directory="`fast_dirname "${path}"`"
   filename="`fast_basename "${path}"`"

   if [ -d "${path}" ]
   then
      scan_directory "${path}" "${PWD}" "${PROJECT_EXTENSIONS}"
      return $?
   fi

   if [ ! -f "${path}" ]
   then
      fail "error: source file \"${TEST_PATH_PREFIX}${path}\" not found"
   fi

   run_test_matching_extensions_in_directory "${filename}" \
                                             "${directory}" \
                                             "${PWD}" \
                                             "${PROJECT_EXTENSIONS}"
}


run_all_tests()
{
   log_entry "run_all_tests" "$@"

   local RUNS=0
   local FAILS=0

   scan_directory "${PWD}" "${PWD}" "${PROJECT_EXTENSIONS}"

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
      log_warning "No tests found"
   fi
}


setup_environment()
{
   MAKEFLAGS="${MAKEFLAGS:-${def_makeflags}}"

   if [ -z "${DEBUGGER}" ]
   then
      DEBUGGER=lldb
   fi

   DEBUGGER="`which "${DEBUGGER}" 2> /dev/null`"

   if [ -z "${DEBUGGER_LIBRARY_PATH}" ]
   then
      DEBUGGER_LIBRARY_PATH="`dirname -- "${DEBUGGER}"`/../lib"
   fi

   RESTORE_CRASHDUMP=`suppress_crashdumping`
   trap 'trace_ignore "${RESTORE_CRASHDUMP}"' 0 5 6

   LIBRARY_SHORTNAME="${LIBRARY_SHORTNAME:-${PROJECT_NAME}}"
   [ -z "${LIBRARY_SHORTNAME}" ] && fail "LIBRARY_SHORTNAME not set"

   LIBRARY_FILENAME="${LIB_PREFIX}${LIBRARY_SHORTNAME}${LIB_SUFFIX}${LIB_EXTENSION}"

   LIBRARY_PATH="`locate_library "${LIBRARY_FILENAME}" "${LIBRARY_PATH}"`" || exit 1

   #
   # figure out where the headers are
   #
   LIBRARY_FILENAME="`basename -- "${LIBRARY_PATH}"`"
   LIBRARY_DIR="`dirname -- "${LIBRARY_PATH}"`"
   LIBRARY_ROOT="`dirname -- "${LIBRARY_DIR}"`"

   if [ -d "${LIBRARY_ROOT}/usr/local/include" ]
   then
      LIBRARY_INCLUDE="${LIBRARY_INCLUDE}/usr/local/include"
   else
      LIBRARY_INCLUDE="${LIBRARY_ROOT}/include"
   fi

   LIBRARY_PATH="`absolutepath "${LIBRARY_PATH}"`"
   LIBRARY_INCLUDE="`absolutepath "${LIBRARY_INCLUDE}"`"

   LIBRARY_DIR="`dirname -- ${LIBRARY_PATH}`"

   case "${MULLE_UNAME}" in
      darwin)
         RPATH_FLAGS="-Wl,-rpath ${LIBRARY_DIR}"

         log_verbose "RPATH_FLAGS=${RPATH_FLAGS}"
      ;;

      linux)
         LD_LIBRARY_PATH="${LIBRARY_DIR}:${LD_LIBRARY_PATH}"
         export LD_LIBRARY_PATH

         log_verbose "LD_LIBRARY_PATH=${LD_LIBRARY_PATH}"
      ;;

      mingw*)
         PATH="${LIBRARY_DIR}:${PATH}"
         export PATH

         log_verbose "PATH=${PATH}"
      ;;
   esac


   #
   # read os-specific-libraries, to link unto standalone
   #
   local os_specific

   os_specific="include/${PROJECT_NAME}/link/os-specific-libraries.txt"

   if [ -f "${os_specific}" ]
   then
      IFS="
"
      for path in `egrep -v '^#' "${os_specific}"`
      do
         IFS="${DEFAULT_IFS}"

         log_verbose "Additional library: ${path}"
         ADDITIONAL_LIBRARY_PATHS="`concat "${ADDITIONAL_LIBRARY_PATHS}" "${path}"`"
      done
      IFS="${DEFAULT_IFS}"
   else
      log_warning "${os_specific} not found"
   fi

   #
   # manage additional libraries, expected to be in same path
   # as library
   #
   local i
   local path
   local filename

   IFS="
"
   for i in ${ADDITIONAL_LIBS}
   do
      IFS="${DEFAULT_IFS}"

      filename="${LIB_PREFIX}${i}${LIB_SUFFIX}${LIB_EXTENSION}"
      path="`locate_library "${filename}"`" || exit 1
      path="`absolutepath "${path}"`"

      log_verbose "Additional library: ${path}"
      ADDITIONAL_LIBRARY_PATHS="`concat "${ADDITIONAL_LIBRARY_PATHS}" "${path}"`"
   done
   IFS="${DEFAULT_IFS}"

   if [ -z "${CC}" ]
   then
      fail "CC for C compiler not defined"
   fi

   assert_binary "$CC" "CC"
}


run_main()
{
   log_entry "run_main" "$@"

   local def_makeflags

   set -m # job control enable

   CFLAGS="${CFLAGS:-${RELEASE_CFLAGS}}"
   BUILD_TYPE="${BUILD_TYPE:-Release}"
   def_makeflags="-s"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -V)
            def_makeflags="VERBOSE=1"
            MULLE_FLAG_LOG_EXEKUTOR="YES"
         ;;

         -n)
            MULLE_FLAG_EXEKUTOR_DRY_RUN="YES"
         ;;

         -f)
            MULLE_FLAG_MAGNUM_FORCE="YES"
         ;;

         --debug)
            BUILD_TYPE=Debug
            CFLAGS="${DEBUG_CFLAGS}"
         ;;

         --release)
            BUILD_TYPE=Release
            CFLAGS="${RELEASE_CFLAGS}"
         ;;

         --path-prefix)
            shift
            [ $# -eq 0 ] && usage

            TEST_PATH_PREFIX="$1"
         ;;

         -*)
            fail "unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   if [ -z "${MULLE_PATH_SH}" ]
   then
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-path.sh"
   fi
   if [ -z "${MULLE_FILE_SH}" ]
   then
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-file.sh"
   fi

   . "${MULLE_TEST_LIBEXEC_DIR}/mulle-test-environment.sh"
   . "${MULLE_TEST_LIBEXEC_DIR}/mulle-test-mingw.sh"

   . "${MULLE_TEST_LIBEXEC_DIR}/mulle-test-cmake.sh"
   . "${MULLE_TEST_LIBEXEC_DIR}/mulle-test-compiler.sh"
   . "${MULLE_TEST_LIBEXEC_DIR}/mulle-test-execute.sh"
   . "${MULLE_TEST_LIBEXEC_DIR}/mulle-test-flagbuilder.sh"
   . "${MULLE_TEST_LIBEXEC_DIR}/mulle-test-locate.sh"
   . "${MULLE_TEST_LIBEXEC_DIR}/mulle-test-logging.sh"
   . "${MULLE_TEST_LIBEXEC_DIR}/mulle-test-regexsearch.sh"

   setup_platform
   setup_tooling
   setup_language "${PROJECT_LANGUAGE}" "${PROJECT_DIALECT}"
   setup_library_type "${LIBRARY_TYPE}"
   setup_environment

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
      if ! run_named_test "$1"
      then
         return 1
      fi
      shift
   done
}

