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

      *:valgrind:*)
         RVAL="MULLE_OBJC_PEDANTIC_EXIT=YES"
         return 0
      ;;
   esac
   
   return 1
}


test::compiler::r_common_c_flags()
{
   log_entry "test::compiler::r_common_c_flags" "$@"

   local srcfile="$1"
   local configuration="$2"

   local common_cflags

   # Get OTHER_CFLAGS (special flags like -fobjc-tao, --coverage, etc)
   # but NOT the basic CFLAGS which contain -O* and -g
   # (mulle-platform handles optimization via --configuration)
   local key
   local value

   r_uppercase "${configuration}"
   key="${RVAL}_OTHER_CFLAGS"
   r_shell_indirect_expand "${key}"
   value="${RVAL}"

   if [ ! -z "${value}" ]
   then
      r_concat "${common_cflags}" "${value}"
      common_cflags="${RVAL}"
   fi

   if [ ! -z "${OTHER_CFLAGS}" ]
   then
      r_concat "${common_cflags}" "${OTHER_CFLAGS}"
      common_cflags="${RVAL}"
   fi

   # Always use -D format for defines; mulle-platform will convert to /D for MSVC
   if [ "${MULLE_TEST_DEFINE}" = 'YES' ]
   then
      r_concat "${common_cflags}" "-DMULLE_TEST=1"
      common_cflags="${RVAL}"
   fi

   # Note: MULLE_INCLUDE_DYNAMIC is now automatically defined by mulle-platform when --shared is used

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

   local c_flags="$1"
   local srcfile="$2"
   local a_out="$3"
   local configuration="$4"

   shift 4

   [ -z "${srcfile}" ] && _internal_fail "srcfile is empty"
   [ -z "${a_out}" ]   && _internal_fail "a_out is empty"

   # skip -- passed on command line for now
   while [ "$1" = "--" ]
   do
      shift
   done

   # Find mulle-platform
   local mulle_platform

   mulle_platform="`command -v 'mulle-platform'`"
   if [ -z "${mulle_platform}" ]
   then
      fail "mulle-platform not found in PATH. Please install mulle-platform."
   fi


   # Build mulle-platform compile command
   local cmdline

   cmdline="${mulle_platform} ${MULLE_TECHNICAL_FLAGS} compile"

#   # Add platform
#   if [ ! -z "${MULLE_UNAME}" ]
#   then
#      cmdline="${cmdline} --platform ${MULLE_UNAME}"
#   fi

   # Add language/dialect
   if [ ! -z "${PROJECT_DIALECT}" ]
   then
      cmdline="${cmdline} --dialect ${PROJECT_DIALECT}"

      # Add objc-dialect if applicable
      if [ "${PROJECT_DIALECT}" = "objc" -a ! -z "${MULLE_TEST_OBJC_DIALECT}" ]
      then
         cmdline="${cmdline} --objc-dialect ${MULLE_TEST_OBJC_DIALECT}"
      fi
   fi

   # Add configuration
   if [ ! -z "${configuration}" ]
   then
      cmdline="${cmdline} --configuration ${configuration}"
   fi   # Add sanitizer flags to mulle-platform
   # Parse SANITIZER variable and add appropriate --sanitizer flags
   if [ ! -z "${SANITIZER}" ]
   then
      local sanitizer

      case ":${SANITIZER}:" in
         *:address:*)
            cmdline="${cmdline} --sanitizer address"
         ;;
      esac

      case ":${SANITIZER}:" in
         *:thread:*)
            cmdline="${cmdline} --sanitizer thread"
         ;;
      esac

      case ":${SANITIZER}:" in
         *:undefined:*)
            cmdline="${cmdline} --sanitizer undefined"
         ;;
      esac

      case ":${SANITIZER}:" in
         *:coverage:*)
            cmdline="${cmdline} --coverage"
         ;;
      esac
   fi

   # Add assembler output flags if requested
   if [ "${OPTION_OUTPUT_ASSEMBLER}" = 'YES' ]
   then
      cmdline="${cmdline} --output-asm"

      if [ "${OPTION_OUTPUT_ASSEMBLER_IR}" = 'YES' ]
      then
         cmdline="${cmdline} --emit-llvm"
      fi
   fi

   # Get common c flags (includes -D defines and -I includes)
   # These should be passed to mulle-platform BEFORE the source file
   # mulle-platform handles optimization flags via --configuration, so we don't pass -O* or -g
   test::compiler::r_common_c_flags "${srcfile}" "${configuration}"
   local common_flags="${RVAL}"

   # Add valgrind define if needed (not a compiler sanitizer, just a define)
   case ":${SANITIZER}:" in
      *:valgrind:*)
         r_concat "${common_flags}" "-DMULLE_TEST_VALGRIND"
         common_flags="${RVAL}"
      ;;
   esac

   # Add common flags (defines, includes) before source
   if [ ! -z "${common_flags}" ]
   then
      cmdline="${cmdline} ${common_flags}"
   fi   # Parse platform-specific linker flags and convert to abstract flags


   # Add source and output
   cmdline="${cmdline} '${srcfile}' -o '${a_out}'"

   include "test::link_parser"

   local linkcommand

   if [ "${LINK_STARTUP_LIBRARY}" = 'NO' ]
   then
      linkcommand="${NO_STARTUP_LINK_COMMAND}"
   else
      linkcommand="${LINK_COMMAND}"
   fi

   # Add export symbols to mulle-platform (for Darwin mainly)
   # mulle-platform will handle the platform-specific flag formatting
   if [ ! -z "${linkcommand}" -o ! -z "${LDFLAGS}" ]
   then
      eval $(mulle-platform env)

      case "${PROJECT_DIALECT}" in
         c)
            case "${linkcommand},${LDFLAGS}" in
               *${MULLE_PLATFORM_LIBRARY_PREFIX}mulle-atinit${MULLE_PLATFORM_LIBRARY_SUFFIX_STATIC}*)
                  cmdline="${cmdline} --export-symbol __mulle_atinit"
               ;;
            esac
            case "${linkcommand},${LDFLAGS}" in
               *${MULLE_PLATFORM_LIBRARY_PREFIX}mulle-atexit${MULLE_PLATFORM_LIBRARY_SUFFIX_STATIC}*)
                  cmdline="${cmdline} --export-symbol _mulle_atexit"
               ;;
            esac
         ;;

         objc)
            case "${MULLE_TEST_OBJC_DIALECT:-mulle-objc}" in
               mulle-objc)
                  cmdline="${cmdline} --export-symbol __mulle_atinit"
                  cmdline="${cmdline} --export-symbol _mulle_atexit"
                  cmdline="${cmdline} --export-symbol ___register_mulle_objc_universe"
               ;;
            esac
         ;;
      esac
   fi


   log_setting "LINK_COMMAND=${linkcommand}"
   log_setting "LDFLAGS=${LDFLAGS}"
   log_setting "RPATH_FLAGS=${RPATH_FLAGS}"

   local link_flags

   # Convert platform-specific linker flags to abstract mulle-platform flags
   r_concat "${linkcommand}" "${LDFLAGS}" "${RPATH_FLAGS}"
   link_flags="${RVAL}"

   r_concat "${cmdline}" "${RVAL}" ' -- '
   cmdline="${RVAL}"

   # No more flags after -- ! Everything is now handled by mulle-platform

   RVAL="${cmdline}"
}


# This function is now obsolete - assembler output is handled by mulle-platform compile
# via --output-asm and --emit-llvm flags


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
      # r_concat "${DEBUG_CFLAGS}" "${CPPFLAGS}"
      # r_concat "${RVAL}" "${CFLAGS}"
      # c_flags="${RVAL}"
      c_flags=${DEBUG_CFLAGS}

      a_out="${a_out%}${DEBUG_EXE_EXTENSION}"

      test::compiler::r_c_commandline "${c_flags}" "${srcfile}" "${a_out}" 'Debug' "$@"
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

   # MEMO: this is all done in `test::compiler::r_c_commandline` already
   # TEST_CFLAGS are the default, but let them be overridden by .c_flags
   # r_concat "${CPPFLAGS}" "${CFLAGS}"
   # r_concat "${c_flags:-${TEST_CFLAGS}}" "${RVAL}"
   # c_flags="${RVAL}"

   test::compiler::r_c_commandline "${c_flags}" \
                                   "${srcfile}" \
                                   "${a_out}" \
                                   "${OPTION_CONFIGURATION}" \
                                   "$@"
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

   # Assembler output is now handled by mulle-platform compile via --output-asm and --emit-llvm flags
   # The flags are added during command line construction in test::compiler::r_c_commandline

   MULLE_FLAG_LOG_EXEKUTOR="${old_MULLE_FLAG_LOG_EXEKUTOR}"

   return $rval
}


test::compiler::run()
{
   log_entry "test::compiler::run" "$@"

   # All compilation is now handled by mulle-platform compile
   # which handles compiler-specific quirks internally
   test::compiler::run_gcc "$@"
}


#
#
#
test::compiler::suggest_debugger_commandline()
{
   log_entry "test::compiler::suggest_debugger_commandline" "$@"

   local a_out_ext="$1"
   local stdin="$2"
   local is_exe="$3" # used by cmake ?
   # local error_log="$4"

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
      # Use mulle-platform quirks to check for DYLD paths on Darwin
      if mulle-platform quirks check uses-dyld 2>/dev/null
      then
         printf "%s " "DYLD_FRAMEWORK_PATH='${DEPENDENCY_DIR}/Frameworks'"
         printf "%s " "DYLD_LIBRARY_PATH='${DEPENDENCY_DIR}/lib'"
      fi

      case ":${SANITIZER}:" in
         *:testallocator:*)
            printf "%s " "MULLE_TESTALLOCATOR=3"
         ;;
      esac

      case "${PROJECT_DIALECT}" in
         objc)
            if [ "${MULLE_TEST_OBJC_DIALECT:-mulle-objc}" = "mulle-objc" ]
            then
# can't do this as we dont know where the log is
#               if [ ! -z "${error_log}" ] && grep -q -F '### leak' "${error_log}" > /dev/null 2>&1
#               then
#                  printf "%s " "\
#MULLE_OBJC_TRACE_ZOMBIE=NO \
#MULLE_OBJC_TRACE_LEAK=YES"
#               else
                  printf "%s " "\
MULLE_OBJC_TRACE_ZOMBIE=YES \
MULLE_OBJC_TRACE_LEAK=NO"
#               fi
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

   test::environment::r_get_test_datafile "ccdiag" "${name}" "-"
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

