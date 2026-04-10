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


test::compiler::r_include_cflags()
{
   log_entry "test::compiler::r_include_cflags" "$@"

   local quote="$1"

   local c_flags

   if [ ! -z "${DEPENDENCY_DIR}" -a ! -z "${ADDICTION_DIR}" ]
   then
      include "platform::flags"
   fi

   local frameworkpath

   frameworkpath="$(mulle-craft searchpath --if-exists --sdk "${TEST_SDK}" --platform "${TEST_PLATFORM}" --configuration "${TEST_CONFIGURATION}" framework)"

   local headerpath

   headerpath="$(mulle-craft searchpath --if-exists --sdk "${TEST_SDK}" --platform "${TEST_PLATFORM}" --configuration "${TEST_CONFIGURATION}" header)"

   # make top level include-able (for "include.h")
   # make this first so test local "include.h" will be found first
   if [ ! -z "${MULLE_VIRTUAL_ROOT}" ]
   then
      platform::flags::r_cc_include_dir "${MULLE_VIRTUAL_ROOT}" "${quote}"
      r_concat "${c_flags}" "${RVAL}"
      c_flags="${RVAL}"
   else
      log_warning "Environment variable ${C_RESET_BOLD}MULLE_VIRTUAL_ROOT${C_WARNING} undefined, you may experience not working or wrong included 'include.h' and 'import.h' files"
   fi

   local directory

   .foreachpath directory in ${headerpath}
   .do
      platform::flags::r_cc_include_dir "${directory}" "${quote}"
      r_concat "${c_flags}" "${RVAL}"
      c_flags="${RVAL}"
   .done


   .foreachpath directory in ${frameworkpath}
   .do
      platform::flags::r_cc_framework_dir "${directory}" "${quote}"
      r_concat "${c_flags}" "${RVAL}"
      c_flags="${RVAL}"
   .done

   RVAL="${c_flags}"
}


test::compiler::r_common_c_flags()
{
   log_entry "test::compiler::r_common_c_flags" "$@"

   local srcfile="$1"
   local configuration="$2"

   local c_flags
   local key
   local value

   #
   # Check for .CFLAGS file that would clobber platform defaults
   #
   local name
   local filename

   r_extensionless_basename "${srcfile}"
   name="${RVAL}"

   # look for <configuration>.CFLAGS file first, then .CFLAGS
   r_concat "${configuration}" 'CFLAGS' '.'
   if [ "${RVAL}" != 'CFLAGS' ]
   then
      test::environment::r_get_test_datafile "${RVAL}" "${name}"
      filename="${RVAL}"
   fi

   if [ -z "${filename}" ]
   then
      test::environment::r_get_test_datafile 'CFLAGS' "${name}"
      filename="${RVAL}"
   fi

   local cflags_clobbered='NO'

   if [ ! -z "${filename}" ]
   then
      # file clobbers - use these instead of platform defaults
      c_flags="$(grep -E -v "^#" "${filename}")"
      log_fluff "CFLAGS clobbered by \"${filename}\""
      cflags_clobbered='YES'
   fi

   # CFLAGS env var augments (whether we have file or not)
   if [ ! -z "${CFLAGS}" ]
   then
      log_setting "CFLAGS (env)        : ${CFLAGS}"
      r_concat "${c_flags}" "${CFLAGS}"
      c_flags="${RVAL}"
   fi

   # OTHER_CFLAGS file augments
   test::environment::r_get_test_datafile 'OTHER_CFLAGS' "${name}"
   if [ ! -z "${RVAL}" ]
   then
      local other_cflags_file="${RVAL}"
      local other_cflags_from_file

      other_cflags_from_file="$(grep -E -v "^#" "${other_cflags_file}")"
      log_setting "OTHER_CFLAGS (file) : ${other_cflags_from_file} (from ${other_cflags_file})"
      r_concat "${c_flags}" "${other_cflags_from_file}"
      c_flags="${RVAL}"
   fi

   log_setting "CFLAGS             : ${c_flags}"

   #
   # OTHER_CFLAGS: augment, don't clobber (-fobjc-tao, --coverage etc.)
   #
   r_uppercase "${configuration}"
   key="${RVAL}_OTHER_CFLAGS"
   r_shell_indirect_expand "${key}"
   value="${RVAL}"

   if [ ! -z "${value}" ]
   then
      log_setting "${key}  : ${value}"
      r_concat "${c_flags}" "${value}"
      c_flags="${RVAL}"
   fi

   if [ ! -z "${OTHER_CFLAGS}" ]
   then
      log_setting "OTHER_CFLAGS        : ${OTHER_CFLAGS}"
      r_concat "${c_flags}" "${OTHER_CFLAGS}"
      c_flags="${RVAL}"
   fi

   # -DMULLE_TEST=1 define
   if [ "${MULLE_TEST_DEFINE}" = 'YES' ]
   then
      r_concat "${c_flags}" "-DMULLE_TEST=1"
      c_flags="${RVAL}"
   fi

   # include flags
   local incflags

   test::compiler::r_include_cflags "'"
   incflags="${RVAL}"

   log_debug "c_flags  : ${c_flags}"
   log_debug "incflags : ${incflags}"

   r_concat "${c_flags}" "${incflags}"

   # Return 4 if CFLAGS were clobbered
   if [ "${cflags_clobbered}" = 'YES' ]
   then
      return 4
   fi
}


test::compiler::r_c_commandline()
{
   log_entry "test::compiler::r_c_commandline" "$@"

   local c_flags="$1"
   local srcfile="$2"
   local a_out="$3"
   local configuration="$4"  # used to build Debug

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


   # Build mulle-platform compiler run command
   local cmdline

   cmdline="${mulle_platform} ${MULLE_TECHNICAL_FLAGS} compiler run"

   # Detect cross-compilation and add target platform
   local target_platform="${TEST_PLATFORM}"
   local cross_compiler_root=""

   if [ "${target_platform}" != "${MULLE_UNAME}" ]
   then
      # Get cross-compiler root for this platform
      local platform_upper
      platform_upper="$(tr '[:lower:]' '[:upper:]' <<< "${target_platform}")"
      local var_name="MULLE_CRAFT_CROSS_COMPILER_ROOT__${platform_upper}"
      eval "cross_compiler_root=\"\${${var_name}}\""
   fi

   if [ ! -z "${target_platform}" ]
   then
      cmdline="${cmdline} --platform ${target_platform}"
   fi

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

   # Get common c flags early to determine if we have CFLAGS that clobber
   local HAVE_CFLAGS='NO'

   local rc
   local common_flags

   test::compiler::r_common_c_flags "${srcfile}" "${configuration}"
   rc=$?
   common_flags="${RVAL}"

   if [ ${rc} -eq 4 ]
   then
      HAVE_CFLAGS='YES'
   fi

   # Add configuration
   if [ ! -z "${configuration}" ]
   then
      cmdline="${cmdline} --configuration ${configuration}"
   fi

   # Add --no-default-cflags if CFLAGS file exists
   if [ "${HAVE_CFLAGS}" = 'YES' ]
   then
      cmdline="${cmdline} --no-default-cflags"
   fi

   # Add sanitizer flags to mulle-platform
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

   # common_flags already set earlier (before --configuration)

   # Add valgrind define if needed (not a compiler sanitizer, just a define)
   case ":${SANITIZER}:" in
      *:valgrind:*)
         r_concat "${common_flags}" "-DMULLE_TEST_VALGRIND"
         common_flags="${RVAL}"
      ;;
   esac

   # Add common flags (defines, includes) will be added after -- separator
   # if [ ! -z "${common_flags}" ]
   # then
   #    cmdline="${cmdline} ${common_flags}"
   # fi   # Parse platform-specific linker flags and convert to abstract flags


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

   #
   # Add export symbols to mulle-platform (for Darwin mainly)
   # mulle-platform will handle the platform-specific flag formatting
   # TODO: are these hax even needed ?
   #
   if [ ! -z "${linkcommand}" -o ! -z "${LDFLAGS}" ]
   then
      eval $(mulle-platform env)

      # TODO: ??? for what platforms, which compiler/linkers is this valid ?
      case "${PROJECT_DIALECT}" in
         c)
            case "${linkcommand},${LDFLAGS}" in
               *${MULLE_PLATFORM_LIBRARY_PREFIX}mulle-atinit${MULLE_PLATFORM_LIBRARY_SUFFIX_STATIC}*|*${MULLE_PLATFORM_LIBRARY_PREFIX}mulle-core-all-load${MULLE_PLATFORM_LIBRARY_SUFFIX_STATIC}*)
                  cmdline="${cmdline} --export-symbol _mulle_atinit"
               ;;
            esac
            case "${linkcommand},${LDFLAGS}" in
               *${MULLE_PLATFORM_LIBRARY_PREFIX}mulle-atexit${MULLE_PLATFORM_LIBRARY_SUFFIX_STATIC}*|*${MULLE_PLATFORM_LIBRARY_PREFIX}mulle-core-all-load${MULLE_PLATFORM_LIBRARY_SUFFIX_STATIC}*)
                  cmdline="${cmdline} --export-symbol _mulle_atexit"
               ;;
            esac
         ;;

         objc)
            case "${MULLE_TEST_OBJC_DIALECT:-mulle-objc}" in
               mulle-objc)
                  cmdline="${cmdline} --export-symbol _mulle_atinit"
                  cmdline="${cmdline} --export-symbol _mulle_atexit"
                  cmdline="${cmdline} --export-symbol ___register_mulle_objc_universe"
               ;;
            esac
         ;;
      esac
   fi

   case "${TEST_PLATFORM}" in
      windows)
         linkcommand="${linkcommand} -Wl,--export-all-symbols"
      ;;
   esac

   log_setting "LINK_COMMAND=${linkcommand}"
   log_setting "LDFLAGS=${LDFLAGS}"
   log_setting "RPATH_FLAGS=${RPATH_FLAGS}"

   local link_flags

   # Convert platform-specific linker flags to abstract mulle-platform flags
   r_concat "${linkcommand}" "${LDFLAGS}" "${RPATH_FLAGS}"
   link_flags="${RVAL}"

   # Add -- separator and then common_flags and link_flags
   cmdline="${cmdline} --"
   if [ ! -z "${common_flags}" ]
   then
      cmdline="${cmdline} ${common_flags}"
   fi
   if [ ! -z "${link_flags}" ]
   then
      cmdline="${cmdline} ${link_flags}"
   fi

   # No more flags after -- ! Everything is now handled by mulle-platform

   RVAL="${cmdline}"
}


# This function is now obsolete - assembler output is handled by mulle-platform compiler run
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

      test::compiler::r_c_commandline "${c_flags}" \
                                      "${srcfile}" \
                                      "${a_out}" \
                                      'Debug' \
                                      "$@"
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

   # Detect cross-compilation and set compiler
   local old_CC
   local old_CXX

   if [ "${TEST_PLATFORM}" != "${MULLE_UNAME}" ]
   then
      # Cross-compiling - set up compiler
      local platform_upper

      r_uppercase "${TEST_PLATFORM}"
      platform_upper="${RVAL}"

      local cross_compiler_root

      r_shell_indirect_expand "MULLE_CRAFT_CROSS_COMPILER_ROOT__${platform_upper}"
      cross_compiler_root="${RVAL}"

      local triplet

      r_shell_indirect_expand "MULLE_SDE_PLATFORM_TRIPLET__${platform_upper}"
      triplet="${RVAL}"
      triplet="${cross_compiler_triplet:-x86_64-w64-mingw32}"

      if [ ! -z "${cross_compiler_root}" ]
      then
         old_CC="${CC}"
         old_CXX="${CXX}"

         # hax hax hax
         case "${TEST_PLATFORM}" in
            windows)
               export CC="${cross_compiler_root}/bin/${triplet}-clang"
               export CXX="${cross_compiler_root}/bin/${triplet}-clang++"
            ;;
         esac
      fi
   fi

   local cmdline

   # MEMO: this is all done in `test::compiler::r_c_commandline` already
   # TEST_CFLAGS are the default, but let them be overridden by .c_flags
   # r_concat "${CPPFLAGS}" "${CFLAGS}"
   # r_concat "${c_flags:-${TEST_CFLAGS}}" "${RVAL}"
   # c_flags="${RVAL}"

   test::compiler::r_c_commandline "${c_flags}" \
                                   "${srcfile}" \
                                   "${a_out}" \
                                   "${TEST_CONFIGURATION}" \
                                   "$@"
   cmdline="${RVAL}"

   local old_MULLE_FLAG_LOG_EXEKUTOR

   old_MULLE_FLAG_LOG_EXEKUTOR="${MULLE_FLAG_LOG_EXEKUTOR}"
   if [ "${MULLE_FLAG_LOG_VERBOSE}" = 'YES' ]
   then
      MULLE_FLAG_LOG_EXEKUTOR='YES'
   fi

   local rc

   test::logging::err_redirect_grepping_eval_exekutor "${errput}" "${cmdline}"
   rc=$?

   # Restore original CC/CXX if we changed them
   # (nat) why ???
   if [ ! -z "${old_CC+x}" ]
   then
      if [ -z "${old_CC}" ]
      then
         unset CC
      else
         export CC="${old_CC}"
      fi
   fi
   if [ ! -z "${old_CXX+x}" ]
   then
      if [ -z "${old_CXX}" ]
      then
         unset CXX
      else
         export CXX="${old_CXX}"
      fi
   fi

   # Assembler output is now handled by mulle-platform compiler run via --output-asm and --emit-llvm flags
   # The flags are added during command line construction in test::compiler::r_c_commandline

   MULLE_FLAG_LOG_EXEKUTOR="${old_MULLE_FLAG_LOG_EXEKUTOR}"

   return $rc
}


test::compiler::run()
{
   log_entry "test::compiler::run" "$@"

   # All compilation is now handled by mulle-platform compiler run
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

      local debugger_cmd
      local platform

      platform="${TEST_PLATFORM}"

      case "${platform}" in
         'mingw'|'msys'|'windows')
            r_uppercase "${TEST_PLATFORM}"
            r_shell_indirect_expand "MULLE_EMULATOR__${RVAL}"
            r_extensionless_basename "${RVAL}"
            case "${RVAL}" in
               *wine*)
                  debugger_cmd="winedbg"
                  printf "%s " "\
MULLE_OBJC_TRACE_UNIVERSE=YES \
MULLE_OBJC_TRACE_LOAD=NO"
               ;;
            esac

            local dllpath
            local winepath

            test::execute::r_windows_custompath
            dllpath="${RVAL}"

            test::execute::r_construct_winepath "${dllpath}"
            winepath="${RVAL}"

            if [ ! -z "${winepath}" ]
            then
               printf "%s " "WINEPATH='${winepath}'"
            fi
         ;;
      esac

      debugger_cmd="${debugger_cmd:-${DEBUGGER:-gdb}}"

      echo "${debugger_cmd} ${a_out_ext}"
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
   local rc="$3"
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
      rc=1
   fi

   if [ "${rc}" -eq 0 ]
   then
      return 0
   fi

   log_error "COMPILER ERRORS: \"${TEST_PATH_PREFIX}${pretty_source}\""

   test::run::maybe_show_diagnostics "${errput}"

   return ${RVAL_FAILURE}
}

