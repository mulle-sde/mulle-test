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


r_libraryfile_cmdline()
{
   log_entry "r_libraryfile_cmdline" "$@"

   local libraryfile="$1"

   RVAL=""

   if [ -z "${libraryfile}" ]
   then
      return
   fi

   local cmdline

   r_fast_dirname "${libraryfile}"
   cmdline="-L'${RVAL}'"

   r_extensionless_basename "${libraryfile}"
   libraryfile="${RVAL#lib}"

   r_concat "${cmdline} -l'${libraryfile}'"
}


# do not exit
fail_test_c()
{
   log_entry "fail_test_c" "$@"

   local srcfile="$1"
   local a_out="$2"
   local ext="$3"

   if [ -z "${MULLE_FLAG_MAGNUM_FORCE}" ]
   then
      return
   fi

   if [ "${MULLE_TEST_CONFIGURATION}" != "Debug" ]
   then
      local a_paths
      local RVAL

      r_quoted_paths "${ADDITIONAL_LIBRARY_FILES}"
      a_paths="${RVAL}"

      local cflags
      local incflags

      r_emit_cflags "${srcfile}"
      cflags="${RVAL}"
      r_emit_include_cflags "'"
      incflags="${RVAL}"

      log_info "DEBUG: "
      log_info "Rebuilding as `fast_basename ${a_out}` with -O0 and debug symbols..."

      local cmdline

      cmdline="'${CC}' ${cflags} ${incflags}"
      cmdline="${cmdline} ${DEBUG_CFLAGS}"
      cmdline="${cmdline} -o '${a_out}'"
      cmdline="${cmdline} '${srcfile}'"

      r_libraryfile_cmdline "${LIBRARY_FILE}"
      r_concat "${cmdline}" "${RVAL}"
      cmdline="${RVAL}"

      cmdline="${cmdline} "${a_paths}" ${LDFLAGS} ${RPATH_FLAGS}"

      eval_exekutor "${cmdline}"
   fi

   stdin="${name}.stdin"
   if rexekutor [ ! -f "${stdin}" ]
   then
      stdin="default.stdin"
   fi
   if rexekutor [ ! -f "${stdin}" ]
   then
      stdin="-"
   fi

   suggest_debugger_commandline "${a_out}" "${stdin}"
}


run_gcc_compiler()
{
   log_entry "run_gcc_compiler" "$@"

   local srcfile="$1"
   local a_out="$2"
   local errput="$3"

   [ -z "${srcfile}" ] && internal_fail "srcfile is empty"
   [ -z "${a_out}" ]   && internal_fail "a_out is empty"
   [ -z "${errput}" ]  && internal_fail "errput is empty"

   #hacque
   local a_paths
   local RVAL

   r_quoted_paths "${ADDITIONAL_LIBRARY_FILES}"
   a_paths="${RVAL}"

   local cflags
   local incflags
   local RVAL

   r_emit_cflags "${srcfile}"
   cflags="${RVAL}"

   r_emit_include_cflags "'"
   incflags="${RVAL}"

   if [ "${MULLE_FLAG_LOG_SETTINGS}" = "YES" ]
   then
      log_debug "LIBRARY_FILE=${LIBRARY_FILE}"
      log_debug "ADDITIONAL_LIBRARY_FILES=${a_paths}"
      log_debug "LDFLAGS=${LDFLAGS}"
      log_debug "RPATH_FLAGS=${RPATH_FLAGS}"
   fi

   cmdline="'${CC}' ${cflags} ${incflags}"
   cmdline="${cmdline} -o '${a_out}'"
   cmdline="${cmdline} '${srcfile}'"
   r_libraryfile_cmdline "${LIBRARY_FILE}"
   r_concat "${cmdline}" "${RVAL}"
   cmdline="${RVAL}"
   cmdline="${cmdline} ${a_paths} ${LDFLAGS} ${RPATH_FLAGS}"

   err_redirect_eval_exekutor "${errput}" "${cmdline}"
}


run_compiler()
{
   log_entry "run_compiler" "$@"

   case "${CC}" in
      cl|cl.exe|*-cl|*-cl.exe)
         run_gcc_compiler "$@"  #mingw magic
      ;;

      *)
         run_gcc_compiler "$@"
      ;;
   esac
}


#
#
#
suggest_debugger_commandline()
{
   log_entry "suggest_debugger_commandline" "$@"

   local a_out_ext="$1"
   local stdin="$2"

   case "${stdin}" in
      ""|"-")
         stdin=""
      ;;

      *)
         stdin="< ${stdin}"
      ;;
   esac

   case "${MULLE_UNAME}" in
      darwin)
         echo "MULLE_OBJC_AUTORELEASEPOOL_TRACE=15 \
MULLE_OBJC_TESTALLOCATOR=1 \
MULLE_TESTALLOCATOR_TRACE=2 \
MULLE_OBJC_TRACE_ENABLED=YES \
MULLE_OBJC_WARN_ENABLED=YES \
DYLD_INSERT_LIBRARIES=/usr/lib/libgmalloc.dylib \
${DEBUGGER:-mulle-lldb} ${a_out_ext}" >&2
         if [ "${stdin}" != "/dev/null" ]
         then
            echo "run ${stdin}" >&2
         fi
      ;;

      linux)
         echo "MULLE_OBJC_AUTORELEASEPOOL_TRACE=15 \
MULLE_OBJC_TESTALLOCATOR=1 \
MULLE_TESTALLOCATOR_TRACE=2 \
MULLE_OBJC_TRACE_ENABLED=YES \
MULLE_OBJC_WARN_ENABLED=YES \
LD_LIBRARY_PATH=\"${LD_LIBRARY_PATH}\" \
${DEBUGGER:-mulle-lldb} ${a_out_ext}" >&2
         if [ "${stdin}" != "/dev/null" ]
         then
            echo "run ${stdin}" >&2
         fi
     ;;
   esac
}


check_compiler_output()
{
   log_entry "check_compiler_output" "$@"

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

   if [ "${rval}" -eq 0 ]
   then
      return 0
   fi

   if [ -z "${ccdiag}" ]
   then
      ccdiag="${name}.ccdiag"
      if rexekutor [ ! -f "${ccdiag}" ]
      then
         ccdiag="default.ccdiag"
      fi
      if rexekutor [ ! -f "${ccdiag}" ]
      then
         ccdiag="-"
      fi
   fi

   if [ "${ccdiag}" = "-" -o ! -f "${ccdiag}" ]
   then
      log_error "COMPILER ERRORS: \"${TEST_PATH_PREFIX}${pretty_source}\""
   else
      search_for_regexps "COMPILER FAILED TO PRODUCE ERRORS: \
\"${TEST_PATH_PREFIX}${pretty_source}\" (${errput})" \
                         "${errput}" "${ccdiag}"
      if [ $? -eq 0 ]
      then
         return ${RVAL_EXPECTED_FAILURE}
      fi
   fi

   maybe_show_diagnostics "${errput}"

   return ${RVAL_FAILURE}
}



assert_binary()
{
   log_entry "assert_binary" "$@"

   local name="$1"
   local bin

   bin="`command -v "${name}"`"
   if [ -z "$bin" ]
   then
      fail "\"${name}\" can not be found"
   fi
}
