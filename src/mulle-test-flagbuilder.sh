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
MULLE_TEST_FLAGBUILDER_SH="included"


emit_include_cflags()
{
   log_entry "emit_include_cflags" "$@"

   local quote="$1"

   local cflags

   if [ ! -z "${LIBRARY_INCLUDE}" ]
   then
      cflags="-I${quote}${LIBRARY_INCLUDE}${quote}"
   fi

   if [ ! -z "${DEPENDENCY_DIR}" ]
   then
      if [ -z "${cflags}" ]
      then
         cflags="-I${quote}${DEPENDENCY_DIR}/include${quote}"
      else
         cflags="${cflags} -I${quote}${DEPENDENCY_DIR}/include${quote}"
      fi
   fi

   if [ ! -z "${ADDICTION_DIR}" ]
   then
      if [ -z "${cflags}" ]
      then
         cflags="-I${quote}${ADDICTION_DIR}/include${quote}"
      else
         cflags="${cflags} -I${quote}${ADDICTION_DIR}/include${quote}"
      fi
   fi

   if [ ! -z "${cflags}" ]
   then
      echo "${cflags}"
   fi
}


emit_cflags()
{
   log_entry "emit_cflags" "$@"

   local srcfile="$1"

   log_debug "PWD: ${PWD}"

   local cflagsname
   local cflags

   cflags="${CFLAGS}"
   cflagsname="`echo "${srcfile}" | sed 's/\.[^.]*$//'`.CFLAGS"

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

   if [ ! -z "${APPLE_SDKPATH}" ]
   then
      cflags="`concat "${cflags}" "-isysroot '${APPLE_SDKPATH}'" `"
   fi
   echo "${cflags}"
}


emit_libraries()
{
   log_entry "emit_libraries" "$@"

   local s

   while [ $# -ne 0 ]
   do
      if [ -z "${s}" ]
      then
         s="$1"
      else
         s="${s};$1"
      fi
      shift
   done

   if [ ! -z "${s}" ]
   then
      echo "${s}"
   fi
}
