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


locate_path()
{
   log_entry "locate_path" "$@"

   local path="$1"

   local found
   found="`ls -1 "${path}" 2> /dev/null | tail -1`"

   if [ ! -z "${MULLE_TEST_TRACE_LOOKUP}" ]
   then
      if [ -z "${found}" ]
      then
         log_fluff "\"${path}\" does not exist"
      else
         log_fluff "Found \"${found}\""
      fi
   fi

   echo "${found}"
}


_locate_library()
{
   log_entry "_locate_library" "$@"

   local filename="$1"

   local library_path

   if [ ! -z "${LIB_PATH}" ]
   then
      library_path="`locate_path "${LIB_PATH}/${filename}"`"
   fi
   [ ! -z "${library_path}" ] && echo "${library_path}" && return

   library_path="`locate_path "./lib/${filename}"`"
   [ ! -z "${library_path}" ] && echo "${library_path}" && return

   library_path="`locate_path "../lib/${filename}"`"
   [ ! -z "${library_path}" ] && echo "${library_path}" && return

   library_path="`locate_path "${DEPENDENCY_DIR}/lib/${filename}"`"
   [ ! -z "${library_path}" ] && echo "${library_path}" && return

   library_path="`locate_path "${ADDICTIONS_DIR}/lib/${filename}"`"
   [ ! -z "${library_path}" ] && echo "${library_path}" && return

   library_path="`locate_path "./build/Products/Debug/${filename}"`"
   [ ! -z "${library_path}" ] && echo "${library_path}" && return

   library_path="`locate_path "../build/Products/Debug/${filename}"`"
   [ ! -z "${library_path}" ] && echo "${library_path}" && return

   echo "${library_path}"
}


locate_library()
{
   log_entry "locate_library" "$@"

   local filename="$1"
   local library_path="$2"

   if [ -z "${library_path}" ]
   then
      _locate_library "${filename}"
   else
      echo "${library_path}"
   fi
}


locate_test_dir()
{
   log_entry "locate_test_dir" "$@"

   local testdir="$1"

   # ez shortcut

   if [ -d "${testdir}" ]
   then
      echo "${testdir}"
      return 0
   fi

   testdirname="`fast_basename "${testdir}"`"
   testdir="${MULLE_VIRTUAL_ROOT:-`pwd -P`}/${testdirname}"
   if [ -d "${testdir}" ]
   then
      echo "${testdir}"
      return 0
   fi

   return 1
}


locate_main()
{
   log_entry "locate_main" "$@"

   locate_test_dir "${TEST_DIR:-test}"
}
