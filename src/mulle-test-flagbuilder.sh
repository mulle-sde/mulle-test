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
MULLE_TEST_FLAGBUILDER_SH='included'


test::flagbuilder::r_include_cflags()
{
   log_entry "test::flagbuilder::r_include_cflags" "$@"

   local quote="$1"

   local c_flags

   if [ ! -z "${DEPENDENCY_DIR}" -a ! -z "${ADDICTION_DIR}" ]
   then
      include "platform::flags"
   fi

   local frameworkpath

   frameworkpath="`mulle-craft searchpath --if-exists --configuration "${OPTION_CONFIGURATION:-Debug}" framework`"

   local headerpath

   headerpath="`mulle-craft searchpath --if-exists --configuration "${OPTION_CONFIGURATION:-Debug}" header`"

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


test::flagbuilder::r_cflags()
{
   log_entry "test::flagbuilder::r_cflags" "$@"

   local c_flags="$1"
   local srcfile="$2"
   local configuration="$3"

#     log_setting "STATICLIB_PREFIX    : ${STATICLIB_PREFIX}"

   local name

   r_extensionless_basename "${srcfile}"
   name="${RVAL}"

   local filename

   #
   # CFLAGS must be completely overrideable by file
   #
   test::environment::r_get_test_datafile 'CFLAGS' "${name}"
   filename="${RVAL}"

   local key
   local value

   if [ -z "${filename}"  ]
   then
      r_uppercase "${configuration}"
      key="${RVAL}_CFLAGS"
      r_shell_indirect_expand "${key}"
      value="${RVAL}"
      log_debug "Using default ${key}"
   else
      value="$(grep -E "^${configuration}:" "${filename}" )"
      if [ ! -z "${value}" ]
      then
         value="${value#:*}"
      else
         value="$(grep -v -E "^[A-Za-z_][A-Za-z0-9_]*:" "${filename}" )"
      fi
      log_debug "Using override CFLAGS from \"${filename}\""
   fi

   log_setting "CFLAGS             : ${value}"

   r_concat "${c_flags}" "${value}"
   c_flags="${RVAL}"

   #
   # this is used to glom -fobjc-tao unto the flags, but we can replace
   # -O0 -g
   #
   r_uppercase "${configuration}"
   key="${RVAL}_OTHER_CFLAGS"
   r_shell_indirect_expand "${key}"
   value="${RVAL}"

   log_setting "${key}  : ${value}"

   r_concat "${c_flags}" "${value}"
   c_flags="${RVAL}"

   log_setting "OTHER_CFLAGS        : ${OTHER_CFLAGS}"

   r_concat "${c_flags}" "${OTHER_CFLAGS}"
   c_flags="${RVAL}"

   if [ ! -z "${APPLE_SDKPATH}" ]
   then
      r_concat "${c_flags}" "-isysroot '${APPLE_SDKPATH}'"
      c_flags="${RVAL}"
   fi

   RVAL="${c_flags}"
}
