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
   local input="$2"
   local output="$3"
   local errput="$4"

   if [ ! -x "${a_out_ext}" ]
   then
      fail "Compiler unexpectedly did not produce ${a_out_ext}"
   fi

   if [ "${MULLE_FLAG_LOG_ENVIRONMENT}" = "YES" ]
   then
      log_fluff "Environment:"
      env | sort >&2
   fi

   case "${MULLE_UNAME}" in
      darwin)
         full_redirekt_eval_exekutor "${input}" \
"${output}" \
"${errput}" \
MULLE_OBJC_TESTALLOCATOR=1 \
"${a_out_ext}"
      ;;


      mingw*)
         full_redirekt_eval_exekutor "${input}" \
"${output}" \
"${errput}" \
PATH="'${PATH}'" \
MULLE_OBJC_TESTALLOCATOR=1
"${a_out_ext}"
      ;;

      *)
         full_redirekt_eval_exekutor "${input}" \
"${output}" \
"${errput}" \
LD_LIBRARY_PATH="'${LD_LIBRARY_PATH}'" \
MULLE_OBJC_TESTALLOCATOR=1 \
"${a_out_ext}"
      ;;
   esac
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

   [ -z "${stdout}" ] && internal_fail "stdout must not be empty"
   [ -z "${stderr}" ] && internal_fail "stderr must not be empty"
   [ -z "${output}" ] && internal_fail "output must not be empty"
   [ -z "${errput}" ] && internal_fail "errput must not be empty"
   [ -z "${a_out}" ]  && internal_fail "a_out must not be empty"

   local info_text

   info_text="\"${TEST_PATH_PREFIX}${pretty_source}\" (${TEST_PATH_PREFIX}${a_out}"

   if [ ${rval} -ne 0 ]
   then
      if [ ! -f "${errors}" ]
      then
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

      result=`exekutor diff -q "${stdout}" "${output}"`
      if [ "${result}" != "" ]
      then
         white=`exekutor diff -q -w "${stdout}" "${output}"`
         if [ "$white" != "" ]
         then
            log_error "FAILED: \"${TEST_PATH_PREFIX}${pretty_source}\" produced unexpected output"
            log_info  "DIFF: (${output} vs. ${stdout})"
            exekutor diff -y "${output}" "${stdout}" >&2
         else
            log_error "FAILED: \"${TEST_PATH_PREFIX}${pretty_source}\" produced different whitespace output"
            log_info  "DIFF: (${TEST_PATH_PREFIX}${stdout} vs. ${output})"
            redirect_exekutor "${output}.actual.hex" od -a "${output}"
            redirect_exekutor "${output}.expect.hex" od -a "${stdout}"
            exekutor diff -y "${output}.expect.hex" "${output}.actual.hex" >&2
         fi

         return ${RVAL_OUTPUT_DIFFERENCES}
      fi
   else
      local contents

      contents="`exekutor head -2 "${output}"`" 2> /dev/null
      if [ "${contents}" != "" ]
      then
         log_warning "WARNING: \"${TEST_PATH_PREFIX}${pretty_source}\" produced unexpected output (${output})" >&2
         return ${RVAL_OUTPUT_DIFFERENCES}
      fi
   fi

   if [ "${stderr}" != "-" ]
   then
      result=`exekutor diff -w "${stderr}" "${errput}"`
      if [ "${result}" != "" ]
      then
         log_warning "WARNING: \"${TEST_PATH_PREFIX}${pretty_source}\" produced unexpected diagnostics (${errput})" >&2
         exekutor echo "" >&2
         exekutor diff "${stderr}" "${errput}" >&2
         return ${RVAL_OUTPUT_DIFFERENCES}
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
   local pretty_source="$7"

   local rval

   _check_test_output "$@"
   rval=$?

   if [ $rval -ne 0 ]
   then
      log_error "${TEST_PATH_PREFIX}${pretty_source}"
      maybe_show_diagnostics "${errput}"
   else
      log_info "${TEST_PATH_PREFIX}${pretty_source}"
   fi

   if [ ${rval} = ${RVAL_OUTPUT_DIFFERENCES} ]
   then
      maybe_show_output "${output}"
   fi

   return $rval
}


test_execute()
{
   log_entry "test_execute" "$@"

   local a_out="$1"
   local name="$2"
   local root="$3"
   local ext="$4"
   local pretty_source="$5"
   local stdin="$6"
   local stdout="$7"
   local stderr="$8"
   local errors="$9"

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

   random="`make_tmp_file "${name}"`" || exit 1

   local output
   local errput
   local errors

   output="${random}.stdout"
   errput="${random}.stderr"

   #
   # run test executable "${a_out}" feeding it "${stdin}" as input
   # retrieve stdout and stderr into temporary files
   #
   run_a_out "${a_out}" "${stdin}" "${output}.tmp" "${errput}.tmp"
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
   exekutor rm "${output}.tmp" "${errput}.tmp"

   if [ "${MULLE_FLAG_LOG_SETTINGS}" = "YES" ]
   then
      log_fluff "-----------------------"
      log_fluff "${errput}:"
      log_fluff "-----------------------"
      cat "${errput}" >&2
      log_fluff "-----------------------"
   fi

   check_test_output  "${stdout}" \
                      "${stderr}" \
                      "${errors}" \
                      "${output}" \
                      "${errput}" \
                      "${rval}"   \
                      "${pretty_source}" \
                      "${a_out}" \
                      "${ext}"
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


   [ -x "${a_out}" ] || test_execute_usage "Improper executable
\"${a_out}\" (not there or lacking execute permissions)"

   local name
   local ext
   local directory

   r_fast_dirname "${sourcefile}"
   directory="${RVAL}"
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

   local root

   root="${PWD}"
   (
      cd "${directory}" &&
      test_execute "${a_out}" \
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
