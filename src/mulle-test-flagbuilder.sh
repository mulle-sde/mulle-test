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
MULLE_TEST_FLAGBUILDER_SH="included"


test::flagbuilder::r_include_cflags()
{
   log_entry "test::flagbuilder::r_include_cflags" "$@"

   local quote="$1"

   local cflags

   if [ ! -z "${DEPENDENCY_DIR}" -a ! -z "${ADDICTION_DIR}" ]
   then
      include "platform::flags"
   fi

   local frameworkpath

   frameworkpath="`mulle-craft searchpath --if-exists --configuration "${OPTION_CONFIGURATION:-Debug}" framework`"

   local headerpath

   headerpath="`mulle-craft searchpath --if-exists --configuration "${OPTION_CONFIGURATION:-Debug}" header`"

   local directory

   .foreachpath directory in ${headerpath}
   .do
      platform::flags::r_cc_include_dir "${directory}" "${quote}"
      r_concat "${cflags}" "${RVAL}"
      cflags="${RVAL}"
   .done

   .foreachpath directory in ${frameworkpath}
   .do
      platform::flags::r_cc_framework_dir "${directory}" "${quote}"
      r_concat "${cflags}" "${RVAL}"
      cflags="${RVAL}"
   .done

   RVAL="${cflags}"
}


test::flagbuilder::r_cflags()
{
   log_entry "test::flagbuilder::r_cflags" "$@"

   local cflags="$1"
   local srcfile="$2"

#     log_setting "STATICLIB_PREFIX    : ${STATICLIB_PREFIX}"
   log_setting "CFLAGS              : ${cflags}"
   log_setting "OTHER_CFLAGS        : ${OTHER_CFLAGS}"
   log_setting "APPLE_SDKPATH       : ${APPLE_SDKPATH}"

   local cflagsname

   r_extensionless_basename "${srcfile}"
   cflagsname="${RVAL}.CFLAGS"

   if [ -f "${cflagsname}.${MULLE_UNAME}" ]
   then
      cflags="`cat "${cflagsname}.${MULLE_UNAME}"`"
      log_fluff "Got CFLAGS=\"${cflags}\" from \"${cflagsname}.${MULLE_UNAME}\""
   else
      if [ -f "${cflagsname}" ]
      then
         cflags="`cat "${cflagsname}"`"
         log_fluff "Got CFLAGS=\"${cflags}\" from \"${cflagsname}\""
      fi
   fi

   r_concat "${cflags}" "${OTHER_CFLAGS}"
   cflags="${RVAL}"

   if [ ! -z "${APPLE_SDKPATH}" ]
   then
      r_concat "${cflags}" "-isysroot '${APPLE_SDKPATH}'"
      cflags="${RVAL}"
   fi

   RVAL="${cflags}"
}
