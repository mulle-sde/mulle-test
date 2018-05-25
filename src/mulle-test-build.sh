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
build_it()
{
   log_entry "build_it" "$@"

   local prefix
   local cmdline

   prefix="`pwd`"

   local testdirname

   testdirname="`fast_basename "${TEST_DIR:-test}"`"
   if [ "`fast_basename "${prefix}"`" != "${testdirname}" ]
   then
      fail "Must be started from directory \"${testdirname}\""
   fi

   cmdline="${MULLE_MAKE:-mulle-make}"

   cmdline="`concat "${cmdline}" "${MULLE_TECHNICAL_FLAGS}"`"
   cmdline="`concat "${cmdline}" "${MULLE_MAKE_FLAGS}"`"
   cmdline="`concat "${cmdline}" "${AUX_BUILD_FLAGS}"`"

   cmdline="${cmdline} install"
   cmdline="`concat "${cmdline}" "${BUILD_OPTIONS}" `"

   cmdline="`concat "${cmdline}" "--build-dir build" `"
   cmdline="`concat "${cmdline}" "--prefix '${prefix}'" `"
   cmdline="`concat "${cmdline}" "-DSTANDALONE=ON" `"

   MULLE_SDE="${MULLE_SDE:-`command -v "mulle-sde"`}"
   if [ ! -z "${MULLE_SDE}" ]
   then
      buildinfo="`"${MULLE_SDE}" -s buildinfo search`"
      if [ ! -z "${buildinfo}" ]
      then
         cmdline="`concat "${cmdline}" "--info-dir '${buildinfo}'" `"
      fi
   fi

   while [ $# -ne 0 ]
   do
      cmdline="${cmdline} '$1'"
      shift
   done

   CMAKEFLAGS="-DMULLE_TEST=ON" eval_exekutor "${cmdline}" ".."
}


#
# pwd must be ./tests
#
build_main()
{
   log_entry "build_main" "$@"

   local AUX_BUILD_FLAGS="-f"
   local BUILD_OPTIONS=

   while [ $# -ne 0 ]
   do
      case "$1" in
         --no-clean)
            BUILD_OPTIONS="`concat "${BUILD_OPTIONS}" "'$1'"`"
            AUX_BUILD_FLAGS=
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   options_setup_trace "${MULLE_TRACE}"

   build_it "$@"
}

