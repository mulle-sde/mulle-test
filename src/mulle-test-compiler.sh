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
MULLE_TEST_COMPILER_SH='included'


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
         RVAL="--coverage -fno-inline"
         # RVAL="-fprofile-instr-generate -fcoverage-mapping"
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

   case ":${sanitizer}:" in
      # MEMO: only produce coverage files for the shared library we
      #       are testing, not for the tests themselves
      *:coverage:*)
         RVAL="-lgcov"
         return 0
      ;;
   esac
#
# now add these unconditionally, because it makes life easier and we always
# link these anyway with executable startups
#
#   #  a bit too clang specific here or ?
#   case ":${sanitizer}:" in
#      *:testallocator:*)
#         case "${PROJECT_DIALECT}" in
#            objc)
#               case "${MULLE_UNAME}" in
#                  darwin)
#                     case "${MULLE_TEST_OBJC_DIALECT:-mulle-objc}" in
#                        mulle-objc)
#                           RVAL="-Wl,-exported_symbol -Wl,__mulle_atinit"
#                           RVAL="${RVAL} -Wl,-exported_symbol -Wl,_mulle_atexit"
#                           RVAL="${RVAL} -Wl,-exported_symbol -Wl,___register_mulle_objc_universe"
#                           return 0
#                        ;;
#                     esac
#                  ;;
#               esac
#            ;;
#         esac
#      ;;
#   esac

   return 1
}



test::compiler::r_env_sanitizer_flags()
{
   log_entry "test::compiler::r_env_sanitizer_flags" "$@"

   local sanitizer="$1"

   RVAL=""
   #  a bit too clang specific here or ?
   case ":${sanitizer}:" in
      *:objc-coverage:*)
         RVAL="MULLE_OBJC_COVERAGE=YES"
         return 0
      ;;
   esac
   
   return 1
}


test::compiler::r_common_c_flags()
{
   log_entry "test::compiler::r_common_c_flags" "$@"

   local srcfile="$1"
   local common_cflags

   test::flagbuilder::r_cflags "" "${srcfile}"
   common_cflags="${RVAL}"

   case "${CC}" in
      *-cl.exe)
         if [ "${MULLE_TEST_DEFINE}" = 'YES' ]
         then
            r_concat "${common_cflags}" "/DMULLE_TEST=1"
            common_cflags="${RVAL}"
         fi

         r_concat "${common_cflags}" "/DMULLE_INCLUDE_DYNAMIC=1"
         common_cflags="${RVAL}"
      ;;

      *)
         if [ "${MULLE_TEST_DEFINE}" = 'YES' ]
         then
            r_concat "${common_cflags}" "-DMULLE_TEST=1"
            common_cflags="${RVAL}"
         fi

         r_concat "${common_cflags}" "-DMULLE_INCLUDE_DYNAMIC=1"
         common_cflags="${RVAL}"
      ;;
   esac

   local incflags

   test::flagbuilder::r_include_cflags "'"
   incflags="${RVAL}"

   log_debug "common_cflags : ${common_cflags}"
   log_debug "incflags      : ${incflags}"

   r_concat "${common_cflags}" "${incflags}"
}


test::compiler::r_c_commandline()
{
   log_entry "test::compiler::r_c_commandline" "$@"

   local c_flags="$1"; shift
   local srcfile="$1"; shift
   local a_out="$1"; shift

   [ -z "${srcfile}" ] && _internal_fail "srcfile is empty"
   [ -z "${a_out}" ]   && _internal_fail "a_out is empty"

   # skip -- passed on command line for now
   while [ "$1" = "--" ]
   do
      shift
   done

   test::compiler::r_common_c_flags "${srcfile}"
   r_concat "${c_flags}" "${RVAL}"
   c_flags="${RVAL}"

   local cmdline

   cmdline="'${CC}' ${c_flags}"
   if test::compiler::r_c_sanitizer_flags "${SANITIZER}"
   then
      cmdline="${cmdline} ${RVAL}"
   fi

   case "${PROJECT_DIALECT}" in
      c)
         case "${MULLE_UNAME}" in
            darwin)
               case "${linkcommand},${LDFLAGS}" in
                  *libmulle-atinit\.a*)
                     cmdline="${cmdline} -Wl,-exported_symbol -Wl,__mulle_atinit"
                  ;;
               esac
               case "${linkcommand},${LDFLAGS}" in
                  *libmulle-atexit\.a*)
                     cmdline="${cmdline} -Wl,-exported_symbol -Wl,_mulle_atexit"
                  ;;
               esac
            ;;
         esac
      ;;

      objc)
         case "${MULLE_UNAME}" in
            darwin)
               case "${MULLE_TEST_OBJC_DIALECT:-mulle-objc}" in
                  mulle-objc)
                     cmdline="${cmdline} -Wl,-exported_symbol -Wl,__mulle_atinit"
                     cmdline="${cmdline} -Wl,-exported_symbol -Wl,_mulle_atexit"
                     cmdline="${cmdline} -Wl,-exported_symbol \
-Wl,___register_mulle_objc_universe"
                  ;;
               esac
            ;;
         esac
      ;;
   esac

   if test::compiler::r_ld_sanitizer_flags "${SANITIZER}"
   then
      LDFLAGS="${LDFLAGS} ${RVAL}"
   fi

   #hacque
   local linkcommand

   linkcommand="${LINK_COMMAND}"
   if [ "${LINK_STARTUP_LIBRARY}" = 'NO' ] # true environment variable
   then
      linkcommand="${NO_STARTUP_LINK_COMMAND}"
   fi

   case "${MULLE_UNAME}" in
      'mingw'|'windows')
         if [ "${MULLE_FLAG_LOG_DEBUG}" = 'YES' ]
         then
            linkcommand="-link -verbose ${linkcommand}"
         else
            linkcommand="-link ${linkcommand}"
         fi
      ;;
   esac

   log_setting "LINK_COMMAND=${linkcommand}"
   log_setting "LDFLAGS=${LDFLAGS}"
   log_setting "RPATH_FLAGS=${RPATH_FLAGS}"

   r_concat "${cmdline}" "$*"
   cmdline="${RVAL}"

   include "platform::flags"

   platform::flags::r_cc_output_exe_filename "${a_out}" "'"
   cmdline="${cmdline} ${RVAL}"

   cmdline="${cmdline} '${srcfile}'"

   r_concat "${cmdline}" "${linkcommand}"
   cmdline="${RVAL}"

   r_concat "${cmdline}" "${LDFLAGS}"
   cmdline="${RVAL}"

   r_concat "${cmdline}" "${RPATH_FLAGS}"
   cmdline="${RVAL}"

   RVAL="${cmdline}"
}


test::compiler::r_c_asm_commandline()
{
   log_entry "test::compiler::r_c_asm_commandline" "$@"

   local c_flags="$1"; shift
   local srcfile="$1"; shift
   local extra="$1"; shift
   local extension="$1"; shift

   [ -z "${srcfile}" ] && _internal_fail "srcfile is empty"
   [ -z "${extension}" ] && _internal_fail "extension is empty"

   # skip -- passed on command line for now
   while [ "$1" = "--" ]
   do
      shift
   done

   local outfile

   outfile="${srcfile%.*}"
   outfile="${outfile}.${extension}"

   test::compiler::r_common_c_flags "${srcfile}"
   r_concat "${c_flags}" "${RVAL}"
   c_flags="${RVAL}"

   local cmdline

   cmdline="'${CC}' ${c_flags} -S"
   r_concat "${cmdline}" "${extra}"
   r_concat "${RVAL}" '${srcfile}'
   r_concat "${RVAL}" "-o '${outfile}'"
   r_concat "${RVAL}" "$*"
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
   local c_flags

   if [ "${TEST_CFLAGS}" != "${DEBUG_CFLAGS}" ]
   then
      r_concat "${DEBUG_CFLAGS}" "${CPPFLAGS}"
      r_concat "${RVAL}" "${CFLAGS}"
      c_flags="${RVAL}"

      a_out="${a_out%}${DEBUG_EXE_EXTENSION}"

      test::compiler::r_c_commandline "${c_flags}" "${srcfile}" "${a_out}" "$@"
      cmdline="${RVAL}"

      log_info "DEBUG: "
      log_info "Rebuilding as `basename -- ${a_out}` with ${c_flags} ..."

      eval_exekutor "${cmdline}"
   else
      log_fluff "Won't recompile as DEBUG, because it's debuggable already"

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
   local c_flags="$4"

   shift 4

   local cmdline

   # TEST_CFLAGS are the default, but let them be overridden by .c_flags
   r_concat "${CPPFLAGS}" "${CFLAGS}"
   r_concat "${c_flags:-${TEST_CFLAGS}}" "${RVAL}"
   c_flags="${RVAL}"

   test::compiler::r_c_commandline "${c_flags}" "${srcfile}" "${a_out}" "$@"
   cmdline="${RVAL}"

   local old_MULLE_FLAG_LOG_EXEKUTOR

   old_MULLE_FLAG_LOG_EXEKUTOR="${MULLE_FLAG_LOG_EXEKUTOR}"
   if [ "${MULLE_FLAG_LOG_VERBOSE}" = 'YES' ]
   then
      MULLE_FLAG_LOG_EXEKUTOR='YES'
   fi

   local rval

   test::logging::err_redirect_grepping_eval_exekutor "${errput}" "${cmdline}"
   rval=$?

   if [ "${OPTION_OUTPUT_ASSEMBLER}" = 'YES'  ]
   then
      local extra
      local extension

      extension="s"
      if [ "${OPTION_OUTPUT_ASSEMBLER_IR}" = 'YES' ]
      then
         extra="-emit-llvm"
         extension="ir"
      fi

      test::compiler::r_c_asm_commandline "${c_flags}" "${srcfile}" "${extra}" "${extension}" "$@"
      cmdline="${RVAL}"

      eval_exekutor "${cmdline}"
   fi

   MULLE_FLAG_LOG_EXEKUTOR="${old_MULLE_FLAG_LOG_EXEKUTOR}"

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
            printf "%s " "MULLE_TESTALLOCATOR=1"
         ;;
      esac

      case "${PROJECT_DIALECT}" in
         objc)
            if [ "${MULLE_TEST_OBJC_DIALECT:-mulle-objc}" = "mulle-objc" ]
            then
#
# MEMO: these flags are more useful if you have a crash in your app during
#       running. if you use some kind of pedantic exit, then you'd need
#
# MULLE_OBJC_ZOMBIE_ENABLED=NO \
# MULLE_OBJC_PEDANTIC_EXIT=YES \
# MULLE_OBJC_EPHEMERAL_SINGLETON=YES \
# MULLE_OBJC_TRACE_INSTANCE=YES \
#

               printf "%s" "\
MULLE_OBJC_ZOMBIE_ENABLED=YES \
MULLE_OBJC_PEDANTIC_EXIT=NO \
MULLE_OBJC_EPHEMERAL_SINGLETON=NO \
MULLE_OBJC_TRACE_INSTANCE=NO \
\
MULLE_OBJC_TRACE_METHOD_CALL=NO \
\
MULLE_OBJC_TRACE_ENABLED=NO \
MULLE_OBJC_TRACE_UNIVERSE=NO \
MULLE_OBJC_TRACE_LOAD=NO \
MULLE_OBJC_TRACE_THREAD=YES \
MULLE_OBJC_DEBUG_ENABLED=YES \
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

   if [ "${MULLE_FLAG_LOG_SETTINGS}" = 'YES' ]
   then
      log_setting "-----------------------"
      log_setting "${errput}:"
      log_setting "-----------------------"
      cat "${errput}" >&2
      log_setting "-----------------------"
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

