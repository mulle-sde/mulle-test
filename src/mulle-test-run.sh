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
MULLE_TEST_RUN_SH='included'


test::run::usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} run [options] [test]

   You may optionally specify a source test file, to only run that specific
   test. Each test is of the form <name>.<extension>, where extension is the
   specific language extension (like "c" or "m"). Besided the test there
   can be a number of auxiliary files, that determine the way the test is
   processed. See the README for more details.

   <name>.args        : Arguments to pass to the test
   <name>.stdout      : Contents must match exactly standard output of the test
   <name>.stdin       : File fed to standard input of the test
   <name>.stderr      : Contents must match exactly standard error of the test
   <name>.errors      : Each line must grep for test diagnostics
   <name>.ccdiag      : Each line must grep for compiler diagnostics
   <name>.environment : Environment variables sourced for test (export FOO=YES)
   <name>.cat         : command to use instead of the default cat
   <name>.diff        : command to use instead of the default diff

   These files can be reused by other tests in the directory by changing <name>
   to "default". You can add ".${MULLE_UNAME}.${MULLE_ARCH}" to specify your
   current platform only (or just either one) e.g. "default.cat.linux.x86_64".

Options:
   --assembler        : produce assembler code on the side (C|ObjC/gcc|clang)
   --debug            : build for debug
   --ir               : produce LLVM IR code (clang/mulle-clang only)
   --keep-exe         : keep test executables around after a successful test
   --release          : build for release
   --reuse-exe        : if executable already exists, reuse it, don't rebuild
   --serial           : run test one after the other
   -l                 : be lenient, keep going if tests fail

EOF
   exit 1
}


#
# this is system wide, not so great
# and also not trapped...
#
test::run::r_suppress_crashdumping()
{
   log_entry "test::run::r_suppress_crashdumping" "$@"

   local restore

   case "${MULLE_UNAME}" in
      darwin)
         restore="`defaults read com.apple.CrashReporter DialogType 2> /dev/null`"
         defaults write com.apple.CrashReporter DialogType none
         ;;
   esac

   RVAL="${restore}"
}


test::run::restore_crashdumping()
{
   log_entry "test::run::restore_crashdumping" "$@"

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


test::run::trace_ignore()
{
   log_entry "test::run::trace_ignore" "$@"

   test::run::restore_crashdumping "$1"
   return 0
}


#
#
#
test::run::maybe_show_diagnostics()
{
   log_entry "test::run::maybe_show_diagnostics" "$@"
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


test::run::maybe_show_output()
{
   log_entry "test::run::maybe_show_output" "$@"

   local output="$1"

   local contents

   if file_is_binary "${output}"
   then
      log_debug "output file is binary, lets not dump it"
      return
   fi

   log_info "OUTPUT:"
   "${CAT:-cat}" "${output}"
}

test::run::common_execute()
{
   local exeflags="$1"
   local args="$2"
   local pretty_source="$3"
   local a_out_ext="$4"
   local srcfile="$5"

   shift 5

   log_verbose "Run test ${C_MAGENTA}${C_BOLD}${pretty_source}"

   if [ ! -z "${exeflags}" ]
   then
      set -- "$@" ${exeflags}
   fi
   if [ ! -z "${args}" ]
   then
      set -- "$@" --args "${args}"
   fi
   if [ ! -z "${pretty_source}" ]
   then
      set -- "$@" --pretty "${pretty_source}"
   fi
   set -- "$@" "${a_out_ext}" "${srcfile}"

   test::execute::main "$@"
}

test::run::common()
{
   log_entry "test::run::common" "$@"

   local args="$1"
   local a_out="$2"
   local a_out_ext="$3"
   local name="$4"
   local flags="$5"
   local ext="$6"
   local root="$7"

   shift 7

   [ -z "${a_out}" ] && _internal_fail "a_out must not be empty"
   [ -z "${name}" ] && _internal_fail "name must not be empty"
   [ -z "${root}" ] && _internal_fail "root must not be empty"

   local srcfile

   srcfile="${name}${ext}"

   local cc_errput

   _r_make_tmp_in_dir "${MULLE_TEST_VAR_DIR}/tmp" "${name}" "f" || exit 1
   cc_errput="${RVAL}.ccerr"

   local pretty_source

   r_filepath_concat "${PWD}" "${srcfile}"
   r_relative_path_between "${RVAL}" "${root}"
   pretty_source="${RVAL}"

   local rval
   local exeflags
   local output

   if [ "${OPTION_REUSE_EXE}" = 'YES' -a -x "${a_out_ext}" ]
   then
      log_verbose "Reusing executable ${a_out_ext#"${MULLE_USER_PWD}/"}"
      TEST_BUILDER=
   fi

   if [ ! -z "${TEST_BUILDER}" ]
   then
      log_fluff "Build test ${pretty_source}"

      "${TEST_BUILDER}" "${srcfile}" "${a_out_ext}" "${cc_errput}" "${flags}" "$@"
      rval="$?"

      test::compiler::check_output "${srcfile}" "${cc_errput}" "${rval}" "${pretty_source}"
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
      exeflags="--keep-exe"
   fi

   log_verbose "Run test ${C_MAGENTA}${C_BOLD}${pretty_source}"

   test::run::common_execute "${exeflags}" \
                             "${args}" \
                             "${pretty_source}" \
                             "${a_out_ext}" \
                             "${srcfile}" \
                             "$@"
   rval=$?

   if [ ${RVAL_EXPECTED_FAILURE} = $rval ]
   then
      return 0
   fi

   if [ ! -z "${FAIL_TEST}" ]
   then
      if [ "${rval}" -ne 0 ]
      then
         "${FAIL_TEST}" "${srcfile}" "${a_out}" "${ext}" "${name}" "$@"
      fi
   else
      log_debug "FAIL_TEST is undefined"
   fi

   log_debug "Execute failure, returns with $rval"
   return $rval
}


test::run::cmake()
{
   log_entry "test::run::cmake" "$@"

   local name="$1"
   # local ext="$2"
   # local root="$3"

   shift

   local purename


   # remove leading 20_ or 20-
   purename="${name#"${name%%[!0-9_-]*}"}"

   local a_out

   a_out="${PWD}/${purename}"

   local cmakeflags

   if test::run::r_get_environmentfile "${purename}" "cmakeflags" "cmakeflags"
   then
      cmakeflags="`grep -E -v '^#' "${RVAL}"`"
   fi

   TEST_BUILDER="test::cmake::run"
   FAIL_TEST="test::cmake::fail_test"
   test::run::common "" "${a_out}" "${a_out}${EXE_EXTENSION}" "${name}" "${cmakeflags}" "$@"
}


test::run::sh()
{
   log_entry "test::run::sh" "$@"

   local name="$1"; shift
   local ext="$1"

   local a_out

   a_out="${PWD}/${name}"

   # local purename
   #
   # remove leading 20_ or 20-
   # purename="${name#"${name%%[!0-9_-]*}"}"

   TEST_BUILDER=""
   test::run::common "" "${a_out}" "" "${name}" "" "$@"
}



test::run::c()
{
   log_entry "test::run::c" "$@"

   local name="$1"; shift
   local ext="$1"

   local purename

   # remove leading 20_ or 20-
   purename="${name#"${name%%[!0-9_-]*}"}"

   local a_out

   a_out="${PWD}/${name}"

   # cmake-output: hein ?
   if test::run::r_get_environmentfile "${purename}" "cmake-output" "cmake-output"
   then
      a_out="`grep -E -v '^#' "${RVAL}"`"
   fi

   local c_flags

   if test::run::r_get_environmentfile "${purename}" "c_flags" "c_flags"
   then
      c_flags="`grep -E -v '^#' "${RVAL}"`"

      local line

      .foreachline line in ${c_flags}
      .do
         case "${line}" in
            ${OPTION_CONFIGURATION}:*)
               c_flags="${line#*:}"
               .break
            ;;

            Release:*|Debug:*|RelWithDebInfo:*|MinSizeRel*)
            ;;

            *)
               c_flags="${line}"
               .break
            ;;
         esac
      .done
   fi

   TEST_BUILDER="test::compiler::run"
   FAIL_TEST="test::compiler::fail_c"
   test::run::common "" "${a_out}" "${a_out}${EXE_EXTENSION}" "${name}" "${c_flags}" "$@"
}


test::run::find_a_out_ext()
{
   log_entry "test::run::find_a_out_ext" "$@"

   local executable="$1"

   local exename
   local exename_ext

   EXE_SEARCH_PATH="${EXE_SEARCH_PATH:-"`mulle-sde searchpath --if-exists binary`"}"
   exename="${executable}"

   case "${MULLE_UNAME}" in
      'mingw'|'msys'|'windows')
         exename_ext="${exename}${EXE_EXTENSION}"
      ;;

      *)
         exename_ext="${exename}"
      ;;
   esac

   command -v "${exename_ext}"
}


test::run::exe()
{
   log_entry "test::run::exe" "$@"

   local name="$1" ; shift
   local ext="$1"

#   local purename
#
#   # remove leading 20_ or 20-
#   purename="${name#"${name%%[!0-9_-]*}"}"

   local a_out
   local a_out_ext

   a_out_ext="`test::run::find_a_out_ext "${MULLE_TEST_EXECUTABLE}" `"
   a_out="${a_out_ext%${EXE_EXTENSION}}"

   TEST_BUILDER=""
   FAIL_TEST=""

   test::run::common "" "${a_out}" "${a_out_ext}" "${name}" "" "$@"
}


test::run::args_exe()
{
   log_entry "test::run::args_exe" "$@"

   local args="$1"; shift

   local name="$1" ; shift
   local ext="$1"

#   local purename
#
#   # remove leading 20_ or 20-
#   purename="${name#"${name%%[!0-9_-]*}"}"

   local a_out
   local a_out_ext

   a_out_ext="`test::run::find_a_out_ext "${MULLE_TEST_EXECUTABLE}" `"
   a_out="${a_out_ext%${EXE_EXTENSION}}"
   TEST_BUILDER=""
   FAIL_TEST=""

   test::run::common "${args}" "${a_out}" "${a_out_ext}" "${name}" "" "$@"
}


test::run::m()
{
   log_entry "test::run::m" "$@"

   test::run::c "$@"
}


test::run::aam()
{
   log_entry "test::run::aam" "$@"

   test::run::m "$@"
}


test::run::h()
{
   log_entry "test::run::h" "$@"

   test::run::args_exe "${name}${ext}" "$@"
}


test::run::cpp()
{
   log_entry "test::run::cpp" "$@"

   log_error "$1: cpp testing is not available yet"
}


test::run::cxx()
{
   log_entry "test::run::cxx" "$@"

   test::run::cpp "$@"
}


test::run::run()
{
   log_entry "test::run::run" "$@"

   local name="$1"
   local ext="$2"

   shift 2

   local a_out
   local a_out_ext

   case "${MULLE_UNAME}" in
      mingw|msys|windows)
         a_out_ext="./run.bat"
      ;;

      *)
         a_out_ext="./run"
      ;;
   esac

   a_out="${a_out_ext%${BAT_EXTENSION}}"

   #
   # remove all sanitizers, because they would get injected
   # into bash, which may become unusably slow. The shell 
   # script should setup the sanitizers if it wants to
   local before

   TEST_SANITIZER="${SANITIZER}"
   SANITIZER=""
   if [ ! -z "${TEST_SANITIZER}" ]
   then
      log_verbose "Implement TEST_SANITIZER in your run script, if you want to support them"
   fi
   export TEST_SANITIZER
   
   TEST_BUILDER=""
   FAIL_TEST=""

   export MULLE_TECHNICAL_FLAGS

   #
   # local args="$1"
   # local a_out="$2"
   # local a_out_ext="$3"
   # local name="$4"
   # local flags="$5"
   # local ext="$6"
   # local root="$7"
   #
   test::run::common "" \
                     "${a_out}" \
                     "${a_out_ext}" \
                     "${name}" \
                     "" \
                     "" \
                     "$@"
}


test::run::r_get_environmentfile()
{
   local name="$1"
   local varname="$2"
   local fallback="$3"

   RVAL="${name}.${varname}.${MULLE_UNAME}.${MULLE_ARCH}"
   if [ ! -f "${RVAL}" ]
   then
      log_debug "\"${RVAL}\" not present"
      RVAL="${name}.${varname}.${MULLE_UNAME}"
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
               RVAL="default.${varname}.${MULLE_UNAME}.${MULLE_ARCH}"
               if [ ! -f "${RVAL}" ]
               then
                  log_debug "\"${RVAL}\" not present"
                  RVAL="default.${varname}.${MULLE_UNAME}"
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
   return 0
}


# we are in the test directory and we are running in a subshell
#
# testname: is either the test.m or "" for Makefile
# runtest : is where the user started the search, its only used for printing
# ext     : extension of the file used for tmp filename construction
#
test::run::_run()
{
   log_entry "test::run::_run" "$@"

   local name="$1"
   local ext="$2"
   local root="$3"

   shift 3

   [ -z "${name}" ] && _internal_fail "name must not be empty"
   [ -z "${ext}" ]  && _internal_fail "ext must not be ? empty"
   [ -z "${root}" ] && _internal_fail "root must not be empty"

   # we change the SANITIZER variable here on demand
   if [ ! -z "${SANITIZER}" ] && [ -e "${name}.no-sanitizers" -o -e "${name}.no-sanitizers.${MULLE_UNAME}" ]
   then
      case ":${SANITIZER}:" in
         *:coverage:*)
            log_info "Disable all sanitizers except ${C_MAGENTA}${C_BOLD}coverage${C_INFO} as ${C_MAGENTA}${C_BOLD}${name}${C_INFO} doesn't work with any sanitizer"
            SANITIZER="coverage"
         ;;

         *)
            SANITIZER=
            log_info "Disable all sanitizers as ${C_MAGENTA}${C_BOLD}${name}${C_INFO} doesn't work with any sanitizer"
            return
         ;;
      esac
   fi

   local sanitizer
   local filtered
   local identifier

   .foreachpath sanitizer in ${SANITIZER}
   .do
      r_lowercase "${sanitizer%%-*}" # turn valgrind-no-leaks into valgrind
      identifier="${RVAL}"

      if [ -e "${name}.no-${identifier}" -o -e "${name}.no-${identifier}.${MULLE_UNAME}" ]
      then
         log_info "Disable ${C_RESET_BOLD}${sanitizer}${C_INFO} as it doesn't work with ${C_MAGENTA}${C_BOLD}${name}${C_INFO}"
      else
         r_colon_concat "${filtered}" "${sanitizer}"
         filtered="${RVAL}"
      fi
   .done

   SANITIZER="${filtered}"

   local purename

   purename="${name#"${name%%[!0-9_-]*}"}"
   if test::run::r_get_environmentfile "${purename}" "environment" "environment"
   then
      log_verbose "Read environment file \"${RVAL}\" (${PWD#"${MULLE_USER_PWD}/"}) "
      # as we are running in a subshell this is OK
      . "${PWD}/${RVAL}" || fail "\"${RVAL}\" read failed"
   fi

   case "${ext#.}" in
      cmake)
         test::run::cmake "${name}" "" "${root}" "$@"
      ;;

      args)
         test::run::exe "${name}" "${ext}" "${root}" "$@"
      ;;

      run)
         if [ "${OPTION_RUN_SCRIPT}" = 'YES' ]
         then
            test::run::run "${name}" "${ext}" "${root}" "$@"
         fi
      ;;

      *)
         local functionname

         functionname="test::run::${ext#.}"
         if shell_is_function "${functionname}"
         then
            # will call test::run:c for C
            "${functionname}" "${name}" "${ext}" "${root}" "$@"
            return $?
         fi

         if [ -z "${MULLE_TEST_EXECUTABLE}" ]
         then
            fail "Don't know how to handle extension \"${ext}\""
         fi

         test::run::args_exe "${name}${ext}" "${name}" "${ext}" "${root}" "$@"
      ;;
   esac
}


test::run::has_run_successfully()
{
   log_entry "test::run::has_run_successfully" "$@"

   local directory="$1"
   local name="$2"

   if [ ! -z "${MULLE_TEST_SUCCESS_FILE}" ]
   then
      rexekutor grep -F -s -q -x "${directory}/${name}" "${MULLE_TEST_SUCCESS_FILE}"
      return $?
   fi
   return 1
}


test::run::handle_return_value()
{
   log_entry "test::run::handle_return_value" "$@"

   local rval=$1; shift

   local directory="$1"
   local name="$2"
   local ext="$3"
   local root="$4"

   log_debug "Return value of test::run::_run: ${rval}"

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


test::run::_run_in_directory()
{
   log_entry "test::run::_run_in_directory" "$@"

   local directory="$1"; shift
   local name="$1"

   (
      # this is OK since we are in a subshell here
      exekutor cd "${directory}" || exit 0

      test::run::_run "$@"
   )
}


test::run::_run_in_directory_parallel()
{
   log_entry "test::run::_run_in_directory_parallel" "$@"

   local directory="$1"; shift

   (
      exekutor cd "${directory}" || exit 0
      test::run::_run "$@"
      test::run::handle_return_value $? "${directory}" "$@"
   )
}


test::run::run_in_directory()
{
   log_entry "test::run::run_in_directory" "$@"

   if test::run::has_run_successfully "$@"
   then
      log_fluff "Test $2 already passed"
      return 0
   fi

   if [ "${MULLE_TEST_SERIAL}" = 'NO' ]
   then
      __parallel_execute test::run::_run_in_directory_parallel "$@"
      return 0
   fi

   RUNS="$((RUNS + 1))"
   test::run::_run_in_directory "$@"
   test::run::handle_return_value $? "$@"
}


test::run::run_matching_extensions_in_directory()
{
   log_entry "test::run::run_matching_extensions_in_directory" "$@"

   local directory="$1"
   local filename="$2"
   local extensions="$3"
   local root="$4"

   shift 4

   local name
   local ext

   .foreachpath ext in ${extensions}
   .do
      ext=".${ext}"

      case "${filename}" in
         *${ext})
            r_extensionless_basename "${filename}"
            test::run::run_in_directory "${directory}" \
                                        "${RVAL}" \
                                        "${ext}" \
                                        "${root}" \
                                        "$@"
            return $?
         ;;
      esac
   .done
}


test::run::r_all_test_roots()
{
   log_entry "test::run::r_all_test_roots" "$@" "(${PWD#"${MULLE_USER_PWD}/"})"

   local dir_only="${1:-NO}"
   local delimiter="${2:-}"

   if [ -z "${delimiter}" ]
   then
      delimiter=$'\n'
   fi

   local i
   local roots

   .foreachline i in `ls -1`
   .do
      if [ ${dir_only} = 'YES' ] && [ ! -d "${i}" ]
      then
         .continue
      fi

      case "${i}" in
         _*|addiction|bin|build|kitchen|craftinfo|dependency|include|lib|libexec|old|stash|tmp)
            log_debug "Ignoring \"${i}\" because it's surely not a test directory"
            .continue
         ;;
      esac

      r_concat "${roots}" "${i}" "${delimiter}"
      roots="${RVAL}"
   .done

   RVAL="${roots}"
}


test::run::_scan_directory()
{
   log_entry "test::run::_scan_directory" "$@" "(${PWD#"${MULLE_USER_PWD}/"})"

   local root="$1"; shift
   local extensions="$1"; shift

   if [ -x run ]
   then
      r_basename "${PWD}"
      test::run::run_in_directory "${PWD}" "${RVAL}" "run" "${root}" "$@"
      return $?
   fi

   if [ -f CMakeLists.txt -a ! -e CMakeLists.txt.ignore ]
   then
      r_basename "${PWD}"
      test::run::run_in_directory "${PWD}" "${RVAL}" "cmake" "${root}" "$@"
      return $?
   fi

   log_fluff "Scanning \"${PWD}\" for files with extensions \"${extensions}\"..."

   local i
   local roots

   test::run::r_all_test_roots
   roots="${RVAL}"

   .foreachline i in ${roots}
   .do
      if [ -d "${i}" ]
      then
         if ! test::run::scan_directory "${i}" "${root}" "${extensions}" "$@"
         then
            return 1
         fi
      else
         if ! test::run::run_matching_extensions_in_directory "${PWD}" \
                                                              "${i}" \
                                                              "${extensions}" \
                                                              "${root}" \
                                                              "$@"
         then
            return 1
         fi
      fi
   .done

   return 0
}


test::run::scan_directory()
{
   log_entry "test::run::scan_directory" "$@"

   local directory="$1"; shift
   local root="$1"; shift
   local extensions="$1"; shift

   [ -z "${directory}" ] && _internal_fail "directory must not be empty"
   [ ! -d "${directory}" ] && _internal_fail "directory \"${directory}\" does not exist"
   [ -z "${root}" ] && _internal_fail "root must not be empty"

   local old
   local rval

   # preserve shell context (no subshell here)
   old="$PWD"

   if ! rexekutor cd "${directory}"
   then
      return 0
   fi

   test::run::_scan_directory "${root}" "${extensions}" "$@"
   rval=$?

   cd "${old}"
   return $rval
}


test::run::all_tests()
{
   log_entry "test::run::all_tests" "$@"

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
      include "parallel"

      log_verbose "Parallel testing"
      __parallel_begin "${OPTION_MAXJOBS}"
   else
      log_verbose "Serial testing"
   fi

   test::run::scan_directory "${PWD}" "${MULLE_USER_PWD}" "${MULLE_TEST_EXTENSIONS}" "$@"

   if [ "${MULLE_TEST_SERIAL}" = 'NO' ]
   then
      __parallel_end

      RUNS="${_parallel_jobs:-0}"
      FAILS="${_parallel_fails:-1}"
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
   return 0
}


test::run::named_test()
{
   log_entry "test::run::named_test" "$@"

   local root="$1"; shift
   local filepath="$1"; shift

   if ! is_absolutepath "${filepath}"
   then
      r_filepath_concat "${root}" "${filepath}"
      filepath="${RVAL}"
   fi

   if [ ! -e "${filepath}" ]
   then
      fail "Test \"${TEST_PATH_PREFIX}${filepath}\" not found"
   fi

   # make physical for WSL
   r_physicalpath "$filepath"
   filepath="${RVAL}"

   if [ -d "${filepath}" ]
   then
      test::run::scan_directory "${filepath}" "${root}" "${MULLE_TEST_EXTENSIONS}" "$@"
      return $?
   fi

   # not so good on windows
   case "${MULLE_UNAME}" in
      'mingw'|'windows')
      ;;

      *)
        # Test invalid now, since .args can be executable and are also the
        # test run target (mulle-cpp)
        #
        # if [ -x "${filepath}" ]
        # then
        #    fail "Specify the source file not a binary \"${TEST_PATH_PREFIX}${filepath}\""
        # fi
      ;;
   esac

   local directory
   local filename

   r_dirname "${filepath}"
   directory="${RVAL}"
   r_basename "${filepath}"
   filename="${RVAL}"

   local RUNS=0
   local FAILS=0

   if ! test::run::run_matching_extensions_in_directory "${directory}" \
                                                        "${filename}" \
                                                        "${MULLE_TEST_EXTENSIONS}" \
                                                        "${root}" \
                                                        "$@"
   then
      return 1
   fi

   if [ ${RUNS} -eq 0 ]
   then
      fail "Could not find \"${filename}\" with matching extensions \
MULLE_TEST_EXTENSIONS \"${MULLE_TEST_EXTENSIONS}\""
   fi
}


test::run::main()
{
   log_entry "test::run::main" "$@"

   include "test::environment"

   test::environment::include_required

   local DEFAULT_MAKEFLAGS
   local OPTION_REQUIRE_LIBRARY='YES'
   local OPTION_LENIENT='NO'
   local OPTION_RERUN_FAILED='NO'
   local OPTION_DEBUG_DYLD='NO'
   local OPTION_REUSE_EXE='NO'
   local OPTION_RUN_SCRIPT='YES'
   local OPTION_OUTPUT_ASSEMBLER='NO'
   local OPTION_OUTPUT_ASSEMBLER_IR='NO'

   DEFAULT_MAKEFLAGS="-s"

   test::environment::setup_execution_platform "${MULLE_UNAME}"
   if [ -z "${MULLE_TEST_EXECUTABLE}" ]
   then
      test::environment::setup_development_environment "${MULLE_UNAME}"
   fi

   # for windows its kinda important, that the flags are
   # consistent with what we crafted
   # TODO: figure out what we have...

   TEST_CFLAGS="${DEBUG_CFLAGS}"
   OPTION_CONFIGURATION="${OPTION_CONFIGURATION:-Debug}"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|--help|help)
            test::run::usage
         ;;

         -l|--lenient)
            OPTION_LENIENT='YES'
         ;;

         -V)
            DEFAULT_MAKEFLAGS="VERBOSE=1"
            MULLE_FLAG_LOG_EXEKUTOR='YES'
         ;;

         -j|--jobs)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            OPTION_MAXJOBS="$1"
         ;;

         --no-run-script)
            OPTION_RUN_SCRIPT='NO'
         ;;

         --assembler)
            OPTION_OUTPUT_ASSEMBLER='YES'
            OPTION_OUTPUT_ASSEMBLER_IR='NO'
         ;;

         --ir|--llvm-ir)
            OPTION_OUTPUT_ASSEMBLER='YES'
            OPTION_OUTPUT_ASSEMBLER_IR='YES'
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
            [ $# -eq 1 ] && test::run::usage "Missing argument to \"$1\""
            shift

            PROJECT_EXTENSIONS="$1"
         ;;

         # this is used so inconsistently its prolly useless
         # the idea was apparenly to have prettier output ?
         --path-prefix)
            shift
            [ $# -eq 0 ] && test::run::usage

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
            [ $# -eq 1 ] && test::run::usage "Missing argument to \"$1\""
            shift

            MULLE_TEST_EXTENSIONS="$1"
         ;;

         --release)
            TEST_CFLAGS="${RELEASE_CFLAGS}"
            OPTION_CONFIGURATION="Release"
         ;;

         --debug)
            TEST_CFLAGS="${DEBUG_CFLAGS}"
            OPTION_CONFIGURATION="Debug"
         ;;

         --build-args)
            # remove build-only flags, which must appear first
            while [ $# -ne 0 ]
            do
               if [ "$1" = "--run-args" ]
               then
                  continue
               fi
               shift
            done
         ;;

         --reuse-exe)
            # this passed "silently" to mulle-test-execute... ugly
            OPTION_REUSE_EXE='YES'
            OPTION_REMOVE_EXE='NO'
         ;;

         --keep-exe)
            # this passed "silently" to mulle-test-execute... ugly
            OPTION_REMOVE_EXE='NO'
         ;;

         --)
            shift
            break
         ;;

         --*)
            log_verbose "Unknown flag \"$1\" will be passed on"
            break
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ -z "${MULLE_TEST_DIR}" ] && _internal_fail "MULLE_TEST_DIR undefined"
   [ -z "${MULLE_TEST_VAR_DIR}" ] && _internal_fail "MULLE_TEST_VAR_DIR undefined"

   MULLE_TEST_EXTENSIONS="${MULLE_TEST_EXTENSIONS:-${PROJECT_EXTENSIONS}}"

   local RVAL_INTERNAL_ERROR=1
   local RVAL_FAILURE=2
   local RVAL_OUTPUT_DIFFERENCES=3
   local RVAL_EXPECTED_FAILURE=4
   local RVAL_IGNORED_FAILURE=5

   local HAVE_WARNED='NO'

   #
   # if extension is args, we just run a dependency/bin/executable
   #
   case ":${PROJECT_EXTENSIONS}:" in
      *:[Cc]:*|*:[Cc]++:*|*:[Cc][XxPp][XxPp]:*|*:[Mm]:*|*:aam:*)
         . "${MULLE_TEST_LIBEXEC_DIR}/mulle-test-linkorder.sh"

         test::linkorder::r_get_link_command 'YES'
         LINK_COMMAND="${RVAL}"

         test::linkorder::r_get_link_command 'NO'
         NO_STARTUP_LINK_COMMAND="${RVAL}"
      ;;

      "")
        _internal_fail "PROJECT_EXTENSIONS is empty"
      ;;

      *:args:*)
         MULLE_TEST_EXECUTABLE="${MULLE_TEST_EXECUTABLE:-${TEST_PROJECT_NAME}}"
         MULLE_TEST_EXECUTABLE="${MULLE_TEST_EXECUTABLE:-run-test.exe}"
      ;;
   esac

   MULLE_TEST_SUCCESS_FILE="${MULLE_TEST_VAR_DIR}/passed.txt"

   if [ "$RUN_ALL" = 'YES' -o $# -eq 0 -o "${1:0:1}" = '-' ]
   then
      if [ "${OPTION_RERUN_FAILED}" = 'NO' ]
      then
         remove_file_if_present "${MULLE_TEST_SUCCESS_FILE}"
      fi

      # cl.exe likes to clobber a central file, when multiple
      # tests are in one directory 
      case "${MULLE_UNAME}" in 
         'mingw'|'msys'|'windows')
            MULLE_TEST_SERIAL='YES'
         ;;

         *)
            MULLE_TEST_SERIAL="${MULLE_TEST_SERIAL:-NO}"
         ;;
      esac
      test::run::all_tests "$@"
      return $?
   fi

   MULLE_TEST_SERIAL='YES'
   MULLE_TEST_SUCCESS_FILE=""

   local testname

   for testname in "$@"
   do
      if ! test::run::named_test "${MULLE_USER_PWD}" "${testname}"
      then
         return 1
      fi
   done
}

