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
MULLE_TEST_EXECUTE_SH='included'


test::execute::usage()
{
   [ $# -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} execute [options] <executable> <sourcefile>

   Run a compiled test. Feed it with stdin. The results will be compared
   against stderr and stdin. The return value must be 0 for a successful
   test, unless you specify an errors file.

Options:
   --errors <file>   : xxx
   --stderr <file>   : xxx
   --stdin  <file>   : xxx
   --stdout <file>   : xxx
EOF

   exit 1
}


test::execute::r_add_name_to_custompath()
{
   log_entry "test::execute::r_add_name_to_custompath" "$@"

   local name="$1"; shift

   local directory="$1"
   local configuration="$2"
   local custompath="${3:-}"

   if [ ! -e "${directory}" ]
   then
      RVAL="${custompath}"
      return
   fi

   r_filepath_concat "${directory}" "${configuration}" "${name}"
   if [ -e "${RVAL}" ]
   then
      r_colon_concat "${RVAL}" "${custompath}"
      custompath="${RVAL}"
   fi

   if [ ! -z "${configuration}" ]
   then
      r_filepath_concat "${directory}" "${name}"
      if [ -e "${RVAL}" ]
      then
         r_colon_concat "${RVAL}" "${custompath}"
         custompath="${RVAL}"
      fi
   fi

   RVAL="${custompath}"
}


test::execute::r_add_bin_lib_to_custompath()
{
   test::execute::r_add_name_to_custompath bin "$1" "$2" "$3"
   test::execute::r_add_name_to_custompath lib "$1" "$2" "${RVAL}"
}

#
# dlls are sometimes installed into bin
#
test::execute::r_windows_custompath()
{
   log_entry "test::execute::r_windows_custompath" "$@"

   local insertpath="$1"

   local custompath

   custompath=""

   if [ -d "${TEST_KITCHEN_DIR:-kitchen}" ]
   then
      r_absolutepath "${TEST_KITCHEN_DIR:-kitchen}"
      custompath="${RVAL}"
   fi

   #
   # add addiction/lib and dependency/lib to PATH for dlls
   #
   test::execute::r_add_bin_lib_to_custompath "${DEPENDENCY_DIR:-dependency}" \
                                              "${OPTION_CONFIGURATION:-Debug}" \
                                              "${custompath}"
   custompath="${RVAL}"

   test::execute::r_add_bin_lib_to_custompath "${ADDICTION_DIR:-addiction}" \
                                              "" \
                                              "${custompath}"
   custompath="${RVAL}"

   # kind of wrong, can we do this in MINGW ?
   if [ ! -z "${insertlibpath}" ]
   then
      r_colon_concat "${insertlibpath}" "${custompath}"
      custompath="${RVAL}"
   fi
   RVAL="${custompath}"   
}


test::execute::a_out()
{
   log_entry "test::execute::a_out" "$@"

   local a_out_ext="$1"
   local args="$2"
   local input="$3"
   local output="$4"
   local errput="$5"

   if [ ! -x "${a_out_ext}" ]
   then
      fail "Compiler unexpectedly did not produce ${a_out_ext}"
   fi

   if [ "${MULLE_FLAG_LOG_ENVIRONMENT}" = 'YES' ]
   then
      log_fluff "Environment:"
      env | sort >&2
   fi


   local libdir

   test::execute::r_add_name_to_custompath "lib" \
                                            "${DEPENDENCY_DIR}" \
                                            "${OPTION_CONFIGURATION:-Debug}"
   libdir="${RVAL}"

   local frameworksdir

   test::execute::r_add_name_to_custompath "Frameworks" \
                                            "${DEPENDENCY_DIR}" \
                                            "${OPTION_CONFIGURATION:-Debug}"
   frameworksdir="${RVAL}"

   ###
   #
   # Construct library insert and search path
   #

   local insertlibpath

   case ":${SANITIZER}:" in
      *:gmalloc:*)
         case "${MULLE_UNAME}" in
            darwin)
               insertlibpath="/usr/lib/libgmalloc${SHAREDLIB_EXTENSION}"
            ;;

            *)
               insertlibpath="${libdir}/libgmalloc${SHAREDLIB_EXTENSION}"
            ;;
         esac
      ;;
   esac

   case ":${SANITIZER}:" in
      *:testallocator:*)
         local filepath

         filepath="${libdir}/${SHAREDLIB_PREFIX}mulle-testallocator${SHAREDLIB_EXTENSION}"
         if [ -f "${filepath}" ]
         then
            r_colon_concat "${insertlibpath}" "${filepath}"
            insertlibpath="${RVAL}"
         else
            log_verbose "\"${filepath#"${MULLE_USER_PWD}/"}\" not found, memory checks will be unavailable"
            SANITIZER="${SANITIZER/testallocator/}"
            r_remove_ugly "${SANITIZER}" ":"
            SANITIZER="${RVAL}"
         fi
      ;;
   esac

   local environment

   case ":${SANITIZER}:" in
      *:coverage:*)
         r_concat "${environment}" "LLVM_PROFILE_FILE='${a_out_ext%.exe}.${MULLE_UNAME}.profraw'"
         environment="${RVAL}"
      ;;
   esac

   case ":${SANITIZER}:" in
      *:glibc:*)
         r_concat "${environment}" "MALLOC_PERTURB_=185"
         r_concat "${RVAL}" "MALLOC_CHECK_=3"
         environment="${RVAL}"
      ;;
   esac

   # add sanitizer flags
   if test::compiler::r_env_sanitizer_flags "${SANITIZER}"
   then
      r_concat "${environment}" "${RVAL}"
      environment="${RVAL}"
   fi

   if [ "${OPTION_DEBUG_DYLD}" = 'YES' ]
   then
      r_concat "${environment}" "MULLE_ATINIT_DEBUG='YES'"
      environment="${RVAL}"
   fi

   case "${MULLE_UNAME}" in
      'darwin')
         r_colon_concat "${insertlibpath}" "${DYLD_INSERT_LIBRARIES}"
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

         r_concat "${environment}" "DYLD_FRAMEWORK_PATH='${frameworksdir}'"
         environment="${RVAL}"

         r_concat "${environment}" "DYLD_LIBRARY_PATH='${libdir}'"
         environment="${RVAL}"
      ;;

      'mingw'|'msys')
         local custompath

         test::execute::r_windows_custompath "${insertpath}"
         custompath="${RVAL}"

         r_concat "${environment}" " PATH='${custompath}'"
         environment="${RVAL}"
      ;;

      'sunos')
         local custompath

         r_concat "${environment}" "LD_LIBRARY_PATH='${libdir}'"
         environment="${RVAL}"
      ;;

      'windows')
         local custompath
         local wslenv 

         test::execute::r_windows_custompath "${insertpath}"
         custompath="${RVAL}"

         r_colon_concat "${WSLENV}" "PATH/l"
         wslenv="${RVAL}"

         r_concat "${environment}" "PATH='${custompath}' WSLENV='${wslenv}'"
         environment="${RVAL}"
      ;;

      *)
         r_colon_concat "${insertlibpath}" "${LD_PRELOAD}"
         if [ ! -z "${RVAL}" ]
         then
            r_concat "${environment}" "LD_PRELOAD='${RVAL}'"
            environment="${RVAL}"
         fi
      ;;
   esac

   if [ "${PROJECT_DIALECT}" = 'objc' ]
   then
      r_concat "${environment}" "MULLE_OBJC_PEDANTIC_EXIT='${OPTION_PEDANTIC_EXIT:-YES}'"
      environment="${RVAL}"

      case ":${SANITIZER}:" in
         *:zombie:*)
            r_concat "${environment}" "NSZombieEnabled=YES"
            environment="${RVAL}"
         ;;
      esac
   fi

   case ":${SANITIZER}:" in
      *:gmalloc:*)
         r_concat "${environment}" "MALLOC_PROTECT_BEFORE='YES' \
MALLOC_FILL_SPACE='YES' MALLOC_STRICT_SIZE='YES'"
         environment="${RVAL}"
      ;;
   esac


   #
   # When run on non mulle-atinit executables, or on mulle-atinit
   # executables that exec a system function, we don't want to see
   # any errors here.
   #
   case ":${SANITIZER}:" in
      *:testallocator:*)
         r_concat "${environment}" "MULLE_TESTALLOCATOR='${OPTION_TESTALLOCATOR:-1}' \
MULLE_TESTALLOCATOR_FIRST_LEAK='YES' \
MULLE_ATINIT_FAILURE=0"
         environment="${RVAL}"
      ;;
   esac

   local runner

   case ":${SANITIZER}:" in
      *:gdb:*)
         runner="'${GDB:-gdb}'"

         r_concat "${runner}" "${GDB_OPTIONS:---silent --return-child-result -ex='set confirm on' -ex=run -ex bt -ex=quit --args}"
         runner="${RVAL}"
      ;;

      *:valgrind:*)
         runner="'${VALGRIND:-valgrind}'"

         r_concat "${runner}" "${VALGRIND_OPTIONS:--q --error-exitcode=77 \
--leak-check=full --num-callers=500 --track-origins=yes}"
         runner="${RVAL}"
      ;;

      *:valgrind-no-leaks:*)
         runner="'${VALGRIND:-valgrind}'"

         r_concat "${runner}" "${VALGRIND_OPTIONS:--q --error-exitcode=77 \
--num-callers=500 --track-origins=yes}"
         runner="${RVAL}"
      ;;
   esac

   if [ ! -z "${environment}" ]
   then
      log_verbose "Custom environment: ${environment}"
   fi

   if [ "${MULLE_FLAG_LOG_VERBOSE}" = 'NO' ]
   then
      test::logging::full_redirekt_eval_exekutor "${input}" \
                                                 "${output}" \
                                                 "${errput}" \
                                                 "${environment}" \
                                                 "${runner}" \
                                                 "'${a_out_ext}'" \
                                                 ${args}
      return $?
   fi

   test::logging::full_redirekt_eval_tee_exekutor "${input}" \
                                                  "${output}" \
                                                  "${errput}" \
                                                  "${environment}" \
                                                  "${runner}" \
                                                  "'${a_out_ext}'" \
                                                  ${args}
   return $?
}


test::execute::other()
{
   log_entry "test::execute::other" "$@"

   local a_out_ext="$1"
   local args="$2"
   local input="$3"
   local output="$4"
   local errput="$5"

   local environment

   if [ "${MULLE_FLAG_LOG_ENVIRONMENT}" = 'YES' ]
   then
      log_fluff "Environment:"
      env | sort >&2
   fi

   local runner

   test::logging::full_redirekt_eval_exekutor "${input}" \
                                              "${output}" \
                                              "${errput}" \
                                              "${environment}" \
                                              "${runner}" \
                                              "'${a_out_ext}'" \
                                              ${args}
}


#
# translate flags for platform if possible
#
mulle_diff()
{
   local OPTION_TERSE
   local OPTION_WIDTH=0
   local OPTION_TWO_COLUMNS
   local OPTION_IGNORE_BLANK_LINES
   local OPTION_IGNORE_WHITESPACE

   while [ $# -ne 0 ]
   do
      case "$1" in
         -q)
            OPTION_TERSE='YES'  # just return value
         ;;

         -w)
            OPTION_IGNORE_WHITESPACE='YES'
         ;;

         -W)
            shift
            OPTION_WIDTH="$1"
         ;;

         -y)
            OPTION_TWO_COLUMNS='YES'
         ;;


         -B)
            OPTION_IGNORE_BLANK_LINES='YES'
         ;;

         -)
            break
         ;;

         -*)
            _internal_fail "unsupported diff flag $1"
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local file_a
   local file_b

   [ $# -eq  2 ] || _internal_fail "need two arguments"

   file_a="$1"
   file_b="$2"

   DIFF="${DIFF:-`command -v diff`}"
   [ -z "${DIFF}" ] && fail "There is no diff command installed on this system"

   set -- "${DIFF}"

   if [ "${OPTION_IGNORE_WHITESPACE}" = 'YES' ]
   then
      set -- "$@" -w
   fi

   if [ "${OPTION_TWO_COLUMNS}" = 'YES' ]
   then
      case "${MULLE_UNAME}" in
         sunos)
            # just no way
         ;;

         *)
            set -- "$@" -y
         ;;
      esac
   fi

   if [ "${OPTION_WIDTH}" -gt 0 ]
   then
      case "${MULLE_UNAME}" in
         sunos)
            # just no way
         ;;

         *)
            set -- "$@" -W "${OPTION_WIDTH}"
         ;;
      esac
   fi

   local tmp_file_a
   local tmp_file_b

   if [ "${OPTION_IGNORE_BLANK_LINES}" = 'YES' ]
   then
      case "${MULLE_UNAME}" in
         sunos)
            r_make_tmp_file
            tmp_file_a="${RVAL}"
            if [ "${file_a}" = "-" ]
            then
               sed '/^[:white:]*$/d' > "${tmp_file_a}"
            else
               sed '/^[:white:]*$/d' < "${file_a}" > "${tmp_file_a}"
            fi

            r_make_tmp_file
            tmp_file_b="${RVAL}"
            if [ "${file_b}" = "-" ]
            then
               sed '/^[:white:]*$/d' > "${tmp_file_b}"
            else
               sed '/^[:white:]*$/d' < "${file_b}" > "${tmp_file_b}"
            fi
         ;;

         *)
            set -- "$@" "-B"
         ;;
      esac
   fi

   local rval

   set -- "$@" "${file_a}" "${file_b}"
   if [ "${OPTION_TERSE}" = 'YES' ]
   then
      rexekutor "$@" > /dev/null
      rval=$?
   else
      rexekutor "$@"
      rval=$?
   fi

   [ ! -z "${tmp_file_a}" ] && exekutor rm "${tmp_file_a}"
   [ ! -z "${tmp_file_b}" ] && exekutor rm "${tmp_file_b}"

   log_debug "rval: ${rval}"

   return $rval
}


test::execute::_check_output()
{
   log_entry "test::execute::_check_output" "$@"

   local stdout="$1" # test provided
   local stderr="$2"
   local errors="$3"
   local output="$4" # test output
   local errput="$5"
   local rval="$6"
   local pretty_source="$7"  # environment
   local a_out="$8"
   local ext="$9"

   [ -z "${RVAL_FAILURE}" ] && _internal_fail "RVAL_FAILURE undefined"
   [ -z "${RVAL_OUTPUT_DIFFERENCES}" ] && _internal_fail "RVAL_OUTPUT_DIFFERENCES undefined"

   [ -z "${stdout}" ] && _internal_fail "stdout must not be empty"
   [ -z "${stderr}" ] && _internal_fail "stderr must not be empty"
   [ -z "${output}" ] && _internal_fail "output must not be empty"
   [ -z "${errput}" ] && _internal_fail "errput must not be empty"
   [ -z "${a_out}" ]  && _internal_fail "a_out must not be empty"
   [ "${rval}" = "" ] && _internal_fail "rval must not be empty"

   [ -z "${CAT}" ]    && _internal_fail "CAT must be defined"

   local info_text

   info_text="\"${TEST_PATH_PREFIX}${pretty_source}\" (${TEST_PATH_PREFIX}${a_out}"

   if [ ${rval} -ne 0 ]
   then
      if [ ! -f "${errors}" ]
      then
         log_info "Stdout"
         rexekutor "${CAT}" "${output}" >&2
         log_info "Stderr"
         rexekutor cat "${errput}" >&2
         if [ ${rval} -ne 1 ]
         then
            log_error "TEST CRASHED ($rval): ${info_text}, ${errput})"
         else
            log_error "TEST FAILED: ${info_text}, ${errput}) (returned ${rval})"
         fi
         return ${RVAL_FAILURE}
      fi

      local banner

      banner="TEST FAILED TO PRODUCE ERRORS: ${info_text} ,${errput})"
      test::regex::search "${banner}" "${errput}" "${errors}"
      return $?
   fi

   if [ -f "${errors}" ]
   then
      log_error "TEST FAILED TO CRASH: ${rval}"
      return ${RVAL_FAILURE}
   fi

   pretty_source="${TEST_PATH_PREFIX}${pretty_source}"
   pretty_source="${pretty_source#"${MULLE_USER_PWD}/"}"

   local pretty_stdout
   local pretty_output
   local pretty_stderr
   local pretty_errput

   pretty_stdout="${TEST_PATH_PREFIX}${stdout}"
   pretty_stdout="${pretty_stdout#"${MULLE_USER_PWD}/"}"
   pretty_stderr="${TEST_PATH_PREFIX}${stderr}"
   pretty_stderr="${pretty_stderr#"${MULLE_USER_PWD}/"}"
   pretty_output="${output#"${MULLE_USER_PWD}/"}"
   pretty_errput="${errput#"${MULLE_USER_PWD}/"}"

   # when MULLE_TEXT_EXECUTABLE is set, this not.-hmm

   if [ "${stdout}" != "-" ]
   then
      # so if we have diffs, we fail
      if ! rexekutor "${CAT}" "${output}" | mulle_diff -q "${stdout}" -
      then
         log_fluff "Check if we have only whitespace differences"
         # if we have no diffs except whitespace
         if rexekutor "${CAT}" "${output}" | mulle_diff -q -w -B "${stdout}" -
         then
            log_warning "WARNING: \"${pretty_source}\" produced different whitespace output"
            log_info  "DIFF: (${pretty_output#{MULLE_USER_PWD}/} vs. ${pretty_stdout#{MULLE_USER_PWD}/})"
            redirect_exekutor "${output}.actual.hex" od -a "${output}"
            redirect_exekutor "${output}.expect.hex" od -a "${stdout}"
            rexekutor "${CAT}" "${output}.actual.hex" | mulle_diff -y -W ${DIFF_COLUMN_WIDTH:-160} - "${output}.expect.hex"  >&2
            return ${RVAL_OUTPUT_DIFFERENCES}
         fi

         log_error "FAILED: \"${pretty_source}\" produced different output"
         log_info  "DIFF: (${pretty_output} vs. ${pretty_stdout})"
         rexekutor "${CAT}"  "${output}" | mulle_diff -y -W ${DIFF_COLUMN_WIDTH:-160} - "${stdout}" >&2
         return ${RVAL_OUTPUT_DIFFERENCES}
      fi
      log_fluff "No differences in stdout found"
   else
      local size

      size="`file_size_in_bytes "${output}"`"
      if [ "${size}" != 0 ]
      then
         log_warning "WARNING: \"${pretty_source}\" produced possibly unexpected output (${pretty_output})" >&2
         "${CAT}" "${output}" >&2
         # return ${RVAL_OUTPUT_DIFFERENCES} just a warning though
      fi
   fi

   if [ "${stderr}" != "-" ]
   then
      if ! mulle_diff -q -w "${stderr}" "${errput}"
      then
         log_error "FAILED: \"${pretty_source}\" produced different diagnostics (${pretty_errput})" >&2
         exekutor echo "" >&2
         exekutor mulle_diff "${pretty_stderr}" "${pretty_errput}" >&2
         return ${RVAL_OUTPUT_DIFFERENCES}
      fi
      log_fluff "No differences in stderr found"
   fi

   return 0
}


test::execute::check_output()
{
   log_entry "test::execute::check_output" "$@"

#   local stdout="$1"
#   local stderr="$2"
#   local errors="$3"
   local output="$4"
   local errput="$5"
# local rval=$?
   local pretty_source="$7"
#   local a_out="$8"
#   local ext="$9"

   [ -z "${RVAL_OUTPUT_DIFFERENCES}" ] && _internal_fail "RVAL_OUTPUT_DIFFERENCES undefined"

   local rc

   test::execute::_check_output "$@"
   rc=$?

   if [ ${rc} -ne 0 ]
   then
      log_error "${TEST_PATH_PREFIX}${pretty_source}"
      test::run::maybe_show_diagnostics "${errput}"
   else
      log_info "${TEST_PATH_PREFIX}${pretty_source}"
   fi

   if [ ${rc} -eq ${RVAL_OUTPUT_DIFFERENCES} ]
   then
      test::run::maybe_show_output "${output}"
   fi

   return ${rc}
}


test::execute::run()
{
   log_entry "test::execute::run" "$@"

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

#   [ -z "${a_out}" ]  && _internal_fail "a_out must not be empty"
   [ -z "${name}" ]   && _internal_fail "name must not be empty"
   [ -z "${root}" ]   && _internal_fail "root must not be empty"
   [ -z "${stdin}" ]  && _internal_fail "stdin must not be empty"
   [ -z "${stdout}" ] && _internal_fail "stdout must not be empty"
   [ -z "${stderr}" ] && _internal_fail "stderr must not be empty"
   [ -z "${pretty_source}" ] && _internal_fail "stderr must not be empty"

   local srcfile

   r_concat "${name}" "${ext}" "."
   srcfile="${RVAL}"

   local random
   local output
   local errput

   [ -z "${MULLE_TEST_VAR_DIR}" ] && _internal_fail "MULLE_TEST_VAR_DIR undefined"

   _r_make_tmp_in_dir "${MULLE_TEST_VAR_DIR}/tmp" "${name}" "f" || exit 1
   output="${RVAL}.stdout"
   errput="${RVAL}.stderr"

   #
   # run test executable "${a_out}" feeding it "${stdin}" as input
   # retrieve stdout and stderr into temporary files
   #
   local executable

   executable="${a_out}"
   if [ ! -z "${executable}" ]
   then
      test::execute::a_out "${executable}" "${args}" "${stdin}" "${output}.tmp" "${errput}.tmp"
      rval=$?
   else
      r_concat "${name}" "${ext}" "."
      r_filepath_concat "${root}" "${RVAL}"
      executable="${RVAL}"

      test::execute::other "${executable}" "${args}" "${stdin}" "${output}.tmp" "${errput}.tmp"
      rval=$?
   fi

   log_debug "Check test \"${name}\" output (rval: $rval)"

   [ -z "${CRLFCAT}" ] && _internal_fail "CRLFCAT must be defined"

   test::logging::redirect_eval_exekutor "${output}" "${CRLFCAT}" "<" "${output}.tmp"
   if [ "${MULLE_FLAG_LOG_SETTINGS}" = 'YES' ]
   then
      log_setting "-----------------------"
      log_setting "${output}:"
      log_setting "-----------------------"
      cat "${output}" >&2
      log_setting "-----------------------"
   fi

   test::logging::redirect_eval_exekutor "${errput}" "${CRLFCAT}" "<" "${errput}.tmp"
   remove_file_if_present "${output}.tmp"
   remove_file_if_present "${errput}.tmp"

   if [ "${MULLE_FLAG_LOG_SETTINGS}" = 'YES' ]
   then
      log_setting "-----------------------"
      log_setting "${errput}:"
      log_setting "-----------------------"
      cat "${errput}" >&2
      log_setting "-----------------------"
   fi

   local rc

   test::execute::check_output  "${stdout}" \
                                "${stderr}" \
                                "${errors}" \
                                "${output}" \
                                "${errput}" \
                                "${rval}"   \
                                "${pretty_source}" \
                                "${executable}" \
                                "${ext}"
   rc=$?

   if [ $rc -eq 0 ]
   then
      remove_file_if_present "${output}"
      remove_file_if_present "${errput}"
   fi

   if [ "${OPTION_REMOVE_EXE}" = 'YES' ]
   then
      # usually always remove this, since we dont want this in coverage report
      remove_file_if_present "${a_out##.exe}.gcno"
   fi

   if [ ! -z "${a_out}" -a $rc -eq 0 -a "${OPTION_REMOVE_EXE}" = 'YES' ]
   then
      # also remove debug file if present
      remove_file_if_present "${a_out##.exe}.debug.exe"
      remove_file_if_present "${a_out}"
      rmdir_safer "${a_out}.dSYM"
   fi

   return $rc
}


test::execute::r_get_test_datafile()
{
   local varname="$1"
   local name="$2"
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


###
### parameters and environment variables
###
test::execute::main()
{
   log_entry "test::execute::main" "$@"

   local stdin
   local stdout
   local stderr
   local errors
   local args
   local diff
   local cat
   local c_flags
   local pretty_source

   if [ -z "${OPTION_REMOVE_EXE}" ]
   then
      OPTION_REMOVE_EXE="${MULLE_TEST_REMOVE_EXE:-YES}"
   fi

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            test::execute::usage
         ;;

         --args)
            [ $# -eq 1 ] && test::execute::usage "missing argument to \"$1\""
            shift

            args="$1"
         ;;

         --stdin)
            [ $# -eq 1 ] && test::execute::usage "missing argument to \"$1\""
            shift

            stdin="$1"
         ;;

         --stdout)
            [ $# -eq 1 ] && test::execute::usage "missing argument to \"$1\""
            shift

            stdout="$1"
         ;;

         --stderr)
            [ $# -eq 1 ] && test::execute::usage "missing argument to \"$1\""
            shift

            stderr="$1"
         ;;

         --errors)
            [ $# -eq 1 ] && test::execute::usage "missing argument to \"$1\""
            shift

            errors="$1"
         ;;

         --pretty)
            [ $# -eq 1 ] && test::execute::usage "missing argument to \"$1\""
            shift

            pretty_source="$1"
         ;;

         --diff)
            [ $# -eq 1 ] && test::execute::usage "missing argument to \"$1\""
            shift

            diff="$1"
         ;;

         --cat)
            [ $# -eq 1 ] && test::execute::usage "missing argument to \"$1\""
            shift

            cat="$1"
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

   [ $# -eq 2 ] || test::execute::usage

   a_out="$1"
   shift

   sourcefile="$1"
   shift

   [ -z "${sourcefile}" ] && test::execute::usage "sourcefile is empty"

   pretty_source="${pretty_source:-${sourcefile}}"

   local directory

   r_dirname "${sourcefile}"
   directory="${RVAL}"

   if [ -e "${directory}/runner" ]
   then
      a_out="${directory}/runner"
      OPTION_REMOVE_EXE='NO'
   fi

   local name
   local ext

   r_basename "${sourcefile}"
   name="${RVAL}"
   name="${sourcefile%.*}"
   ext="${sourcefile##*.}"

   if [ -z "${stdin}" ]
   then
      test::execute::r_get_test_datafile "stdin" "${name}" "/dev/null"
      stdin="${RVAL}"
   fi

   if [ -z "${stdout}" ]
   then
      test::execute::r_get_test_datafile "stdout" "${name}" "-"
      stdout="${RVAL}"
   fi

   if [ -z "${stderr}" ]
   then
      test::execute::r_get_test_datafile "stderr" "${name}" "-"
      stderr="${RVAL}"
   fi

   if [ -z "${errors}" ]
   then
      test::execute::r_get_test_datafile "errors" "${name}" "-"
      errors="${RVAL}"
   fi

   if [ -z "${diff}" ]
   then
      test::execute::r_get_test_datafile "diff" "${name}" ""
      diff="${RVAL}"
   fi

   if [ -z "${cat}" ]
   then
      test::execute::r_get_test_datafile "cat" "${name}" ""
      cat="${RVAL}"
   fi

   local args_text
   local file_args

   test::execute::r_get_test_datafile "args" "${name}" ""
   file_args="${RVAL}"

   if [ ! -z "${file_args}" ]
   then
      if [ -x "${file_args}" ]
      then
         args_text="`PATH="${PWD}:${PATH}" rexekutor "${file_args}"`" || fail "${file_args} errored out"
      else
         args_text="`cat "${file_args}"`"
      fi

      TESTSOURCE="${sourcefile}" TESTNAME="${name}" r_expanded_string "${args_text}"
      args_text=${RVAL}
   else
      args_text="${args}"
   fi

   local root

   root="${PWD}"
   (
      cd "${directory}"

      if [ ! -z "${diff}" ]
      then
         diff="${PWD}/${diff}"
      else
         diff="diff"
      fi
      DIFF="`command -v ${diff}`"
      [ -z "${DIFF}" ] && fail "There is no ${diff} installed on this system"

      # allow special local cat to massage output for diffing
      if [ ! -z "${cat}" ]
      then
         cat="${PWD}/${cat}"
      else
         cat="cat"
      fi

      CAT="`command -v ${cat}`"
      [ -z "${CAT}" ] && fail "There is no ${cat} installed on this system"

      test::execute::run "${a_out}" \
                         "${args_text}" \
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
