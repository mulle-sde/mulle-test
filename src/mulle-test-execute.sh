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
MULLE_TEST_EXECUTE_SH="included"


test_execute_usage()
{
   [ $# -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} execute [options] <executable> <sourcefile>

   Run a compiled test. Feed it with stdin. The results will be compared
   against stderr and stdin. The return value must be 0 for a successful
   test unless an errors file is specified.

Options:
   --errors <file>   : xxx
   --stderr <file>   : xxx
   --stdin  <file>   : xxx
   --stdout <file>   : xxx
EOF

   exit 1
}


run_a_out()
{
   log_entry "run_a_out" "$@"

   local a_out_ext="$1"
   local args="$2"
   local input="$3"
   local output="$4"
   local errput="$5"

   if [ ! -x "${a_out_ext}" ]
   then
      fail "Compiler unexpectedly did not produce ${a_out_ext}"
   fi

   if [ "${MULLE_FLAG_LOG_ENVIRONMENT}" = "YES" ]
   then
      log_fluff "Environment:"
      env | sort >&2
   fi

   local environment
   local libpath
   local runner

   ###
   #
   # Construct library insert and searc path
   #

   case ":${MEMORY_CHECKER}:" in
      *:gmalloc:*)
         case "${MULLE_UNAME}" in
            darwin)
               libpath="/usr/lib/libgmalloc${SHAREDLIB_EXTENSION}"
            ;;

            *)
               libpath="${DEPENDENCY_DIR}/lib/libgmalloc${SHAREDLIB_EXTENSION}"
            ;;
         esac
      ;;
   esac

   case ":${MEMORY_CHECKER}:" in
      *:testallocator:*)
         r_colon_concat "${libpath}" "${DEPENDENCY_DIR}/lib/libmulle-testallocator${SHAREDLIB_EXTENSION}"
         libpath="${RVAL}"
      ;;
   esac

   if [ "${OPTION_DEBUG_DYLD}" = 'YES' ]
   then
      r_concat "${environment}" "MULLE_ATINIT_DEBUG='YES'"
      environment="${RVAL}"
   fi

   case "${MULLE_UNAME}" in
      darwin)
         r_colon_concat "${libpath}" "${DYLD_INSERT_LIBRARIES}"
         if [ ! -z "${RVAL}" ]
         then
            r_concat "${environment}" "DYLD_INSERT_LIBRARIES='${RVAL}'"
            environment="${RVAL}"
            if [ "${OPTION_DEBUG_DYLD}" = 'YES' ]
            then
               r_concat "${environment}" "DYLD_PRINT_LIBRARIES='YES'"
               environment="${RVAL}"
            fi
         fi
      ;;

      mingw*)
         if [ ! -z "${libpath}" ]
         then
            r_colon_concat "${libpath}" "${PATH}"
            r_concat "${environment}" " PATH='${RVAL}'"
            environment="${RVAL}"
         fi
      ;;

      *)
         r_colon_concat "${libpath}" "${LD_LIBRARY_PATH}"
         libpath="${RVAL}"

         if [ ! -z "${libpath}" ]
         then
            r_concat "${environment}" "LD_LIBRARY_PATH='${libpath}'"
         fi
         environment="${RVAL}"
      ;;
   esac

   if [ "${PROJECT_DIALECT}" = 'objc' ]
   then
      r_concat "${environment}" "MULLE_OBJC_PEDANTIC_EXIT='${OPTION_PEDANTIC_EXIT:-YES}'"
      environment="${RVAL}"

      case ":${MEMORY_CHECKER}:" in
         *:zombie:*)
            r_concat "${environment}" "NSZombieEnabled=YES"
            environment="${RVAL}"
         ;;
      esac
   fi

   case ":${MEMORY_CHECKER}:" in
      *:gmalloc:*)
         r_concat "${environment}" "MALLOC_PROTECT_BEFORE='YES' \
MALLOC_FILL_SPACE='YES' MALLOC_STRICT_SIZE='YES'"
         environment="${RVAL}"
      ;;
   esac

   case ":${MEMORY_CHECKER}:" in
      *:testallocator:*)
         r_concat "${environment}" "MULLE_TESTALLOCATOR='${OPTION_TESTALLOCATOR:-1}' \
MULLE_TESTALLOCATOR_FIRST_LEAK='YES'"
         environment="${RVAL}"
      ;;
   esac

   case ":${MEMORY_CHECKER}:" in
      *:valgrind:*)
         runner="'${VALGRIND:-valgrind}'"

         r_concat "${runner}" "${VALGRIND_OPTIONS:--q --error-exitcode=77 --leak-check=full --num-callers=500 --track-origins=yes}"
         runner="${RVAL}"
      ;;
   esac

   full_redirekt_eval_exekutor "${input}" "${output}" "${errput}" \
                                  "${environment}" "${runner}" "'${a_out_ext}'" "${args}"
}


_check_test_output()
{
   log_entry "_check_test_output" "$@"

   local stdout="$1" # test provided
   local stderr="$2"
   local errors="$3"
   local output="$4" # test output
   local errput="$5"
   local rval="$6"
   local pretty_source="$7"  # environment
   local a_out="$8"
   local ext="$9"

   [ -z "${RVAL_FAILURE}" ] && internal_fail "RVAL_FAILURE undefined"
   [ -z "${RVAL_OUTPUT_DIFFERENCES}" ] && internal_fail "RVAL_OUTPUT_DIFFERENCES undefined"

   [ -z "${stdout}" ] && internal_fail "stdout must not be empty"
   [ -z "${stderr}" ] && internal_fail "stderr must not be empty"
   [ -z "${output}" ] && internal_fail "output must not be empty"
   [ -z "${errput}" ] && internal_fail "errput must not be empty"
   [ -z "${a_out}" ]  && internal_fail "a_out must not be empty"
   [ "${rval}" = "" ] && internal_fail "rval must not be empty"

   local info_text

   info_text="\"${TEST_PATH_PREFIX}${pretty_source}\" (${TEST_PATH_PREFIX}${a_out}"

   if [ ${rval} -ne 0 ]
   then
      if [ ! -f "${errors}" ]
      then
         cat "${errput}" >&2
         if [ ${rval} -ne 1 ]
         then
            log_error "TEST CRASHED: ${info_text}, ${errput})"
         else
            log_error "TEST FAILED: ${info_text}, ${errput}) (returned ${rval})"
         fi
         return ${RVAL_FAILURE}
      fi

      local banner

      banner="TEST FAILED TO PRODUCE ERRORS: ${info_text} ,${errput})"
      search_for_regexps "${banner}" "${errput}" "${errors}"
      return $?
   fi

   if [ -f "${errors}" ]
   then
      log_error "TEST FAILED TO CRASH: "
      return ${RVAL_FAILURE}
   fi

   if [ "${stdout}" != "-" ]
   then
      local result

      result=`exekutor "${DIFF}" -q "${stdout}" "${output}"`
      if [ "${result}" != "" ]
      then
         white=`exekutor "${DIFF}" -q -w "${stdout}" "${output}"`
         if [ "$white" != "" ]
         then
            log_error "FAILED: \"${TEST_PATH_PREFIX}${pretty_source}\" produced unexpected output"
            log_info  "DIFF: (${output} vs. ${stdout})"
            exekutor "${DIFF}" -y "${output}" "${stdout}" >&2
         else
            log_error "FAILED: \"${TEST_PATH_PREFIX}${pretty_source}\" produced different whitespace output"
            log_info  "DIFF: (${TEST_PATH_PREFIX}${stdout} vs. ${output})"
            redirect_exekutor "${output}.actual.hex" od -a "${output}"
            redirect_exekutor "${output}.expect.hex" od -a "${stdout}"
            exekutor "${DIFF}" -y "${output}.expect.hex" "${output}.actual.hex" >&2
         fi

         return ${RVAL_OUTPUT_DIFFERENCES}
      else
         log_fluff "No differences in stdout found"
      fi
   else
      local contents

      contents="`exekutor cat "${output}"`" 2> /dev/null
      if [ "${contents}" != "" ]
      then
         log_warning "WARNING: \"${TEST_PATH_PREFIX}${pretty_source}\" produced possibly unexpected output (${output})" >&2
         echo "${contents}" >&2
         # return ${RVAL_OUTPUT_DIFFERENCES} just a warning though
      fi
   fi

   if [ "${stderr}" != "-" ]
   then
      result=`exekutor "${DIFF}" -w "${stderr}" "${errput}"`
      if [ "${result}" != "" ]
      then
         log_error "FAILED: \"${TEST_PATH_PREFIX}${pretty_source}\" produced unexpected diagnostics (${errput})" >&2
         exekutor echo "" >&2
         exekutor "${DIFF}" "${stderr}" "${errput}" >&2
         return ${RVAL_OUTPUT_DIFFERENCES}
      else
         log_fluff "No differences in stderr found"
      fi
   fi

   return 0
}


check_test_output()
{
   log_entry "check_test_output" "$@"

#   local stdout="$1"
#   local stderr="$2"
#   local errors="$3"
   local output="$4"
   local errput="$5"
# local rval=$?
   local pretty_source="$7"
#   local a_out="$8"
#   local ext="$9"

   [ -z "${RVAL_OUTPUT_DIFFERENCES}" ] && internal_fail "RVAL_OUTPUT_DIFFERENCES undefined"

   _check_test_output "$@"
   rval=$?

   if [ $rval -ne 0 ]
   then
      log_error "${TEST_PATH_PREFIX}${pretty_source}"
      maybe_show_diagnostics "${errput}"
   else
      log_info "${TEST_PATH_PREFIX}${pretty_source}"
   fi

   if [ ${rval} -eq ${RVAL_OUTPUT_DIFFERENCES} ]
   then
      maybe_show_output "${output}"
   fi

   return $rval
}


test_execute()
{
   log_entry "test_execute" "$@"

   local a_out="$1" ; shift
   local args="$1"; shift
   local name="$1"; shift
   local root="$1"; shift
   local ext="$1"; shift
   local pretty_source="$1"; shift
   local stdin="$1"; shift
   local stdout="$1"; shift
   local stderr="$1"; shift
   local errors="$1"; shift

   [ -z "${a_out}" ]  && internal_fail "a_out must not be empty"
   [ -z "${name}" ]   && internal_fail "name must not be empty"
   [ -z "${root}" ]   && internal_fail "root must not be empty"
   [ -z "${stdin}" ]  && internal_fail "stdin must not be empty"
   [ -z "${stdout}" ] && internal_fail "stdout must not be empty"
   [ -z "${stderr}" ] && internal_fail "stderr must not be empty"
   [ -z "${pretty_source}" ] && internal_fail "stderr must not be empty"

   local srcfile

   r_concat "${name}" "${ext}" "."
   srcfile="${RVAL}"

   local random
   local output
   local errput
   local errors

   _r_make_tmp_in_dir "${MULLE_TEST_VAR_DIR}/tmp" "${name}.stdout" "f"
   output="${RVAL}"

   errput="${output%.stdout}.stderr"

   #
   # run test executable "${a_out}" feeding it "${stdin}" as input
   # retrieve stdout and stderr into temporary files
   #
   run_a_out "${a_out}" "${args}" "${stdin}" "${output}.tmp" "${errput}.tmp"
   rval=$?

   log_debug "Check test \"${name}\" output (rval: $rval)"

   redirect_eval_exekutor "${output}" "${CRLFCAT}" "<" "${output}.tmp"
   if [ "${MULLE_FLAG_LOG_SETTINGS}" = "YES" ]
   then
      log_fluff "-----------------------"
      log_fluff "${output}:"
      log_fluff "-----------------------"
      cat "${output}" >&2
      log_fluff "-----------------------"
   fi

   redirect_eval_exekutor "${errput}" "${CRLFCAT}" "<" "${errput}.tmp"
   remove_file_if_present "${output}.tmp"
   remove_file_if_present "${errput}.tmp"

   if [ "${MULLE_FLAG_LOG_SETTINGS}" = "YES" ]
   then
      log_fluff "-----------------------"
      log_fluff "${errput}:"
      log_fluff "-----------------------"
      cat "${errput}" >&2
      log_fluff "-----------------------"
   fi

   local rc

   check_test_output  "${stdout}" \
                      "${stderr}" \
                      "${errors}" \
                      "${output}" \
                      "${errput}" \
                      "${rval}"   \
                      "${pretty_source}" \
                      "${a_out}" \
                      "${ext}"
   rc=$?

   remove_file_if_present "${output}"
   remove_file_if_present "${errput}"
   if [ $rc -eq 0 -a "${OPTION_REMOVE_EXE}" = 'YES' ]
   then
      remove_file_if_present "${a_out}"
      rmdir_safer "${a_out}.dSYM"
   fi

   return $rc
}


###
### parameters and environment variables
###
test_execute_main()
{
   log_entry "test_execute_main" "$@"

   local stdin
   local stdout
   local stderr
   local errors

   local pretty_source

   if [ -z "${OPTION_REMOVE_EXE}" ]
   then
      OPTION_REMOVE_EXE="${MULLE_TEST_REMOVE_EXE:-YES}"
   fi

   while :
   do
      case "$1" in
         -h*|--help|help)
            test_execute_usage
         ;;

         --stdin)
            [ $# -eq 1 ] && test_execute_usage "missing argument to \"$1\""
            shift

            stdin="$1"
         ;;

         --stdout)
            [ $# -eq 1 ] && test_execute_usage "missing argument to \"$1\""
            shift

            stdout="$1"
         ;;

         --stderr)
            [ $# -eq 1 ] && test_execute_usage "missing argument to \"$1\""
            shift

            stderr="$1"
         ;;

         --errors)
            [ $# -eq 1 ] && test_execute_usage "missing argument to \"$1\""
            shift

            errors="$1"
         ;;

         --pretty)
            [ $# -eq 1 ] && test_execute_usage "missing argument to \"$1\""
            shift

            pretty_source="$1"
         ;;

         --keep-exe)
            OPTION_REMOVE_EXE='NO'
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local a_out
   local sourcefile

   [ $# -eq 2 ] || test_execute_usage

   a_out="$1"
   shift

   sourcefile="$1"
   shift

   [ -z "${sourcefile}" ] && test_execute_usage "sourcefile is empty"

   pretty_source="${pretty_source:-${sourcefile}}"

   local directory

   r_fast_dirname "${sourcefile}"
   directory="${RVAL}"

   if [ -e "${directory}/runner" ]
   then
      a_out="${directory}/runner"
      OPTION_REMOVE_EXE='NO'
   fi

   [ -x "${a_out}" ] || test_execute_usage "Improper executable
\"${a_out}\" (not there or lacking execute permissions)"

   DIFF="`command -v diff`"
   [ -z "${DIFF}" ] && fail "There is no diff installed on this system"

   local name
   local ext

   r_fast_basename "${sourcefile}"
   name="${RVAL}"
   name="${sourcefile%.*}"
   ext="${sourcefile##*.}"

   if [ -z "${stdin}" ]
   then
      stdin="${name}.stdin"
      if rexekutor [ ! -f "${stdin}" ]
      then
         stdin="default.stdin"
      fi
      if rexekutor [ ! -f "${stdin}" ]
      then
         stdin="/dev/null"
      fi
   fi

   if [ -z "${stdout}" ]
   then
      stdout="${name}.stdout"
      if rexekutor [ ! -f "${stdout}" ]
      then
         stdout="default.stdout"
      fi
      if rexekutor [ ! -f "${stdout}" ]
      then
         stdout="-"
      fi
   fi

   if [ -z "${stderr}" ]
   then
      stderr="${name}.stderr"
      if rexekutor [ ! -f "${stderr}" ]
      then
         stderr="default.stderr"
      fi
      if rexekutor [ ! -f "${stderr}" ]
      then
         stderr="-"
      fi
   fi

   if [ -z "${errors}" ]
   then
      errors="${name}.errors"
      if rexekutor [ ! -f "${errors}" ]
      then
         errors="default.errors"
      fi
      if rexekutor [ ! -f "${errors}" ]
      then
         errors="-"
      fi
   fi

   if [ -z "${args}" ]
   then
      args="${name}.args"
      if rexekutor [ ! -f "${args}" ]
      then
         args="default.args"
      fi
      if rexekutor [ ! -f "${args}" ]
      then
         args=""
      else
         args="`cat "${args}"`"
      fi
   fi

   local root

   root="${PWD}"
   (
      cd "${directory}" &&
      test_execute "${a_out}" \
                   "${args}" \
                   "${name}" \
                   "${root}" \
                   "${ext}" \
                   "${pretty_source}" \
                   "${stdin}" \
                   "${stdout}" \
                   "${stderr}" \
                   "${errors}"
   )
}
