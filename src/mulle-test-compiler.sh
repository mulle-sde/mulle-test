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
MULLE_TEST_COMPILER_SH="included"


test::compiler::r_c_sanitizer_flags()
{
   log_entry "test::compiler::r_c_sanitizer_flags" "$@"

   local sanitizer="$1"

   RVAL=""
   #  a bit too clang specific here or ?
   case ":${sanitizer}:" in
      *:undefined:*)
         RVAL="-fsanitize=undefined"
         return 0
      ;;

      *:coverage:*)
         RVAL="--coverage"
         #RVAL="-fprofile-instr-generate -fcoverage-mapping"
         return 0
      ;;

      *:thread:*)
         RVAL="-fsanitize=thread"
         return 0
      ;;

      *:address:*)
         RVAL="-fsanitize=address"
         return 0
      ;;
   esac

   return 1
}


test::compiler::r_ld_sanitizer_flags()
{
   log_entry "test::compiler::r_ld_sanitizer_flags" "$@"

   local sanitizer="$1"

   RVAL=""
   #  a bit too clang specific here or ?
   case ":${sanitizer}:" in
      *:testallocator:*)
         case "${PROJECT_DIALECT}" in
            objc)
               case "${MULLE_UNAME}" in
                  darwin)
                     case "${MULLE_TEST_OBJC_DIALECT:-mulle-objc}" in
                        mulle-objc)
                           RVAL="-Wl,-exported_symbol -Wl,__mulle_atinit"
                           RVAL="${RVAL} -Wl,-exported_symbol -Wl,_mulle_atexit"
                           return 0
                        ;;
                     esac
                  ;;
               esac
            ;;
         esac
      ;;
   esac

   return 1
}


test::compiler::r_c_commandline()
{
   log_entry "test::compiler::r_c_commandline" "$@"

   local cflags="$1"; shift
   local srcfile="$1"; shift
   local a_out="$1"; shift

   [ -z "${srcfile}" ] && internal_fail "srcfile is empty"
   [ -z "${a_out}" ]   && internal_fail "a_out is empty"

   # skip -- passed on command line for now
   while [ "$1" = "--" ]
   do
      shift
   done

   #hacque
   local cflags
   local incflags
   local linkcommand

   linkcommand="${LINK_COMMAND}"
   if [ "${LINK_STARTUP_LIBRARY}" = 'NO' ] # true environment variable
   then
      linkcommand="${NO_STARTUP_LINK_COMMAND}"
   fi

   case "${MULLE_UNAME}" in 
      mingw|windows)
         if [ "${MULLE_FLAG_LOG_DEBUG}" = 'YES' ]
         then
            linkcommand="-link -verbose ${linkcommand}"
         else
            linkcommand="-link ${linkcommand}"
         fi
      ;;
   esac

   test::flagbuilder::r_cflags "${cflags}" "${srcfile}"
   cflags="${RVAL}"

   case "${MULLE_UNAME}" in
      windows)
         r_concat "${cflags}" "/DMULLE_TEST=1"
         cflags="${RVAL}"
      ;;

      *)
         r_concat "${cflags}" "-DMULLE_TEST=1"
         cflags="${RVAL}"
      ;;
   esac

   test::flagbuilder::r_include_cflags "'"
   incflags="${RVAL}"

   cmdline="'${CC}' ${cflags} ${incflags}"
   if test::compiler::r_c_sanitizer_flags "${SANITIZER}"
   then
      cmdline="${cmdline} ${RVAL}"
   fi

   if test::compiler::r_ld_sanitizer_flags "${SANITIZER}"
   then
      cmdline="${cmdline} ${RVAL}"
   fi

   case "${PROJECT_DIALECT}" in
      objc)
         case "${MULLE_UNAME}" in
            darwin)
               case "${MULLE_TEST_OBJC_DIALECT:-mulle-objc}" in
                  mulle-objc)
                     cmdline="${cmdline} -Wl,-exported_symbol \
-Wl,___register_mulle_objc_universe"
                  ;;
               esac
            ;;
         esac
      ;;
   esac

   if [ "${MULLE_FLAG_LOG_SETTINGS}" = "YES" ]
   then
      log_debug "LINK_COMMAND=${linkcommand}"
      log_debug "LDFLAGS=${LDFLAGS}"
      log_debug "RPATH_FLAGS=${RPATH_FLAGS}"
   fi

   r_concat "${cmdline}" "$*"
   cmdline="${RVAL}"

   include "platform::flags"

   platform::flags::r_cc_output_exe_filename "${a_out}" "'"
   cmdline="${cmdline} ${RVAL}"

   cmdline="${cmdline} '${srcfile}'"

   r_concat "${cmdline}" "${linkcommand}"
   cmdline="${RVAL}"

   cmdline="${cmdline} ${LDFLAGS} ${RPATH_FLAGS}"

   RVAL="${cmdline}"
}


# do not exit
test::compiler::fail_c()
{
   log_entry "test::compiler::fail_c" "$@"

   local srcfile="$1"
   local a_out="$2"
   local ext="$3"
   local name="$4"

   shift 4

   if [ "${MULLE_FLAG_MAGNUM_FORCE}" = 'YES' ]
   then
      log_debug "fail ignored due to -f"
      return
   fi

   local cmdline
   local cflags

   if [ "${TEST_CFLAGS}" != "${DEBUG_CFLAGS}" ]
   then
      r_concat "${DEBUG_CFLAGS}" "${CPPFLAGS}"
      r_concat "${RVAL}" "${CFLAGS}"
      cflags="${RVAL}"

      a_out="${a_out%}${DEBUG_EXE_EXTENSION}"

      test::compiler::r_c_commandline "${cflags}" "${srcfile}" "${a_out}" "$@"
      cmdline="${RVAL}"

      log_info "DEBUG: "
      log_info "Rebuilding as `basename -- ${a_out}` with ${cflags} ..."

      eval_exekutor "${cmdline}"
   else
      log_fluff "Don't recompile as DEBUG, because it's debuggable already"

      a_out="${a_out%}${EXE_EXTENSION}"
   fi

   local stdin

   stdin="${name}.stdin"
   if rexekutor [ ! -f "${stdin}" ]
   then
      stdin="default.stdin"
   fi
   if rexekutor [ ! -f "${stdin}" ]
   then
      stdin="-"
   fi

   test::compiler::suggest_debugger_commandline "${a_out}" "${stdin}"
}


test::compiler::run_gcc()
{
   log_entry "test::compiler::run_gcc" "$@"

   local srcfile="$1"
   local a_out="$2"
   local errput="$3"

   shift 3

   local cmdline
   local cflags

   r_concat "${TEST_CFLAGS}" "${CPPFLAGS}"
   r_concat "${RVAL}" "${CFLAGS}"
   cflags="${RVAL}"

   test::compiler::r_c_commandline "${cflags}" "${srcfile}" "${a_out}" "$@"
   cmdline="${RVAL}"

   local old

   old="${MULLE_FLAG_LOG_EXEKUTOR}"
   if [ "${MULLE_FLAG_LOG_VERBOSE}" = 'YES' ]
   then
      MULLE_FLAG_LOG_EXEKUTOR="YES"
   fi

   local rval

   test::logging::err_redirect_grepping_eval_exekutor "${errput}" "${cmdline}"
   rval=$?

   MULLE_FLAG_LOG_EXEKUTOR="${RVAL}"

   return $rval
}


test::compiler::run()
{
   log_entry "test::compiler::run" "$@"

   case "${CC}" in
      cl|cl.exe|*-cl|*-cl.exe)
         test::compiler::run_gcc "$@"  #mingw magic
      ;;

      *)
         test::compiler::run_gcc "$@"
      ;;
   esac
}


#
#
#
test::compiler::suggest_debugger_commandline()
{
   log_entry "test::compiler::suggest_debugger_commandline" "$@"

   local a_out_ext="$1"
   local stdin="$2"

   #
   # don't show debugger commandline if a runner is being used
   #
   r_dirname "${a_out_ext}"
   if [ -x "${RVAL}/runner" ]
   then
      return
   fi

   case "${stdin}" in
      ""|"-")
         stdin=""
      ;;

      *)
         stdin="< ${stdin}"
      ;;
   esac

   (
      case "${MULLE_UNAME}" in
         darwin)
            printf "%s " "DYLD_FRAMEWORK_PATH='${DEPENDENCY_DIR}/Frameworks'"
            printf "%s " "DYLD_LIBRARY_PATH='${DEPENDENCY_DIR}/lib'"
         ;;
      esac

      case ":${SANITIZER}:" in
         *:testallocator:*)
            printf "%s" "MULLE_TESTALLOCATOR=1 \
MULLE_TESTALLOCATOR_TRACE=0 "
         ;;
      esac

      case "${PROJECT_DIALECT}" in
         objc)
            if [ "${MULLE_TEST_OBJC_DIALECT:-mulle-objc}" = "mulle-objc" ]
            then
               printf "%s" "\
MULLE_OBJC_TRACE_INSTANCE=NO \
MULLE_OBJC_TRACE_METHOD_CALL=NO \
MULLE_OBJC_DEBUG_ENABLED=YES \
MULLE_OBJC_TRACE_ENABLED=NO \
MULLE_OBJC_EPHEMERAL_SINGLETON=YES \
MULLE_OBJC_PEDANTIC_EXIT=YES \
MULLE_OBJC_TRACE_LOAD=NO \
MULLE_OBJC_TRACE_THREAD=YES \
MULLE_OBJC_TRACE_UNIVERSE=YES \
MULLE_OBJC_WARN_ENABLED=YES "
            fi
         ;;
      esac

      echo "${DEBUGGER:-gdb} ${a_out_ext}"
      if [ "${stdin}" != "/dev/null" ]
      then
         echo "run ${stdin}"
      fi
   ) >&2
}


test::compiler::check_output()
{
   log_entry "test::compiler::check_output" "$@"

   local srcfile="$1"
   local errput="$2"
   local rval="$3"
   local pretty_source="$4"
   local ccdiag="$5"

   if [ "${MULLE_FLAG_LOG_SETTINGS}" = "YES" ]
   then
      log_fluff "-----------------------"
      log_fluff "${errput}:"
      log_fluff "-----------------------"
      cat "${errput}" >&2
      log_fluff "-----------------------"
   fi

   test::execute::r_get_test_datafile "ccdiag" "${name}" "-"
   ccdiag="${RVAL}"

   if [ "${ccdiag}" != "-" ]
   then
      test::regex::search "COMPILER FAILED TO PRODUCE ERRORS: \
\"${TEST_PATH_PREFIX}${pretty_source}\" (${errput})" \
                         "${errput}" "${ccdiag}"
      if [ $? -eq 0 ]
      then
         return ${RVAL_EXPECTED_FAILURE}
      fi
      rval=1
   fi

   if [ "${rval}" -eq 0 ]
   then
      return 0
   fi

   log_error "COMPILER ERRORS: \"${TEST_PATH_PREFIX}${pretty_source}\""

   test::run::maybe_show_diagnostics "${errput}"

   return ${RVAL_FAILURE}
}

