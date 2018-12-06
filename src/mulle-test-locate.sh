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
MULLE_TEST_LOCATE_SH="included"


r_locate_path()
{
   log_entry "r_locate_path" "$@"

   local path="$1"

   RVAL="`ls -1 "${path}" 2> /dev/null | tail -1`"

   if [ ! -z "${MULLE_TEST_TRACE_LOOKUP}" ]
   then
      if [ -z "${RVAL}" ]
      then
         log_fluff "\"${path}\" does not exist"
      else
         log_fluff "Found \"${RVAL}\""
      fi
   fi

   [ ! -z "${RVAL}" ]
}


_r_locate_library()
{
   log_entry "_r_locate_library" "$@"

   local filename="$1"

   local library_path

   if [ ! -z "${LIB_PATH}" ]
   then
      r_locate_path "${LIB_PATH}/${filename}" && return
   fi

   r_locate_path "./lib/${filename}" && return
   r_locate_path "../lib/${filename}" && return
   r_locate_path "${DEPENDENCY_DIR}/Debug/lib/${filename}" && return
   r_locate_path "${DEPENDENCY_DIR}/lib/${filename}" && return
   r_locate_path "${ADDICTIONS_DIR}/lib/${filename}" && return
   r_locate_path "./build/Products/Debug/${filename}" && return
   r_locate_path "../build/Products/${filename}"
}


r_locate_library()
{
   log_entry "r_locate_library" "$@"

   local filename="$1"
   local library_path="$2"

   if [ -z "${library_path}" ]
   then
      _r_locate_library "${filename}"
   else
      RVAL="$2"
   fi

   [ ! -z "${RVAL}" ]
}


r_locate_test_dir()
{
   log_entry "r_locate_test_dir" "$@"

   local testdir="$1"

   # ez shortcut

   if [ ! -d "${testdir}" ]
   then
      r_fast_basename "${testdir}"
      testdirname="${RVAL}"

      testdir="${MULLE_VIRTUAL_ROOT:-${PWD}}/${testdirname}"
      if [ ! -d "${testdir}" ]
      then
         RVAL=
         return 1
      fi
   fi

   RVAL="${testdir}"
   return 0
}


r_locate_main()
{
   log_entry "r_locate_main" "$@"

   r_locate_test_dir "${MULLE_TEST_DIR:-test}"
}
