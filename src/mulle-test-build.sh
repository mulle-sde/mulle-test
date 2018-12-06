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
MULLE_TEST_BUILD_SH="included"


#
# build our project into the test environment. Just a glorified wrapper around
# mulle-make
#
#
# pwd must be ./tests
#
build_main()
{
   log_entry "build_main" "$@"

   local flags="$1"; shift
   local options="$1"; shift

   local prefix
   local cmdline

   prefix="${PWD}"

   local testdirname
   local RVAL

   r_fast_basename "${MULLE_TEST_DIR:-test}"
   testdirname="${RVAL}"

   r_fast_basename "${prefix}"
   if [ "${RVAL}" != "${testdirname}" ]
   then
      fail "Must be started from directory \"${testdirname}\""
   fi

   cmdline="${MULLE_MAKE:-mulle-make}"

   r_concat "${cmdline}" "${MULLE_TECHNICAL_FLAGS}"
   cmdline="${RVAL}"
   r_concat "${cmdline}" "${MULLE_MAKE_FLAGS}"
   cmdline="${RVAL}"
   r_concat "${cmdline}" "${flags}"
   cmdline="${RVAL}"

   r_concat "${cmdline}" "install"
   cmdline="${RVAL}"

   r_concat "${cmdline}" "${options}"
   cmdline="${RVAL}"
   r_concat "${cmdline}" "--configuration '${MULLE_TEST_CONFIGURATION}'"
   cmdline="${RVAL}"
   r_concat "${cmdline}" "--build-dir build"
   cmdline="${RVAL}"
   r_concat "${cmdline}" "--prefix '${prefix}'"
   cmdline="${RVAL}"
   r_concat "${cmdline}" "-DSTANDALONE=ON"
   cmdline="${RVAL}"

   MULLE_SDE="${MULLE_SDE:-`command -v "mulle-sde"`}"
   if [ ! -z "${MULLE_SDE}" ]
   then
      local makeinfo

      makeinfo="`rexekutor "${MULLE_SDE}" ${MULLE_TECHNICAL_FLAGS} definition search`"
      if [ ! -z "${makeinfo}" ]
      then
         log_fluff "Makeinfo \"${makeinfo}\" found"

         r_concat "${cmdline}" "--definition-dir '${makeinfo}'"
         cmdline="${RVAL}"
      fi
   fi

   while [ $# -ne 0 ]
   do
      cmdline="${cmdline} '$1'"
      shift
   done

   CMAKEFLAGS="-DMULLE_TEST=ON" eval_exekutor "${cmdline}" ".."
}



