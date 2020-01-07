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


r_locate_script_test_dir()
{
   log_entry "r_locate_script_test_dir" "$@"

   local i

   for i in "$@" . test tests
   do
      if [ -x "${i}/run-test" ]
      then
         r_absolutepath "$i"
         return 0
      fi
   done
   RVAL=""
   return 1
}


r_locate_test_dir()
{
   log_entry "r_locate_test_dir" "$@"

   local testdir="$1"

   local project_dir

   project_dir="`mulle-sde project-dir`"
   if [ -z "${project_dir}" ]
   then
      # not a mulle project, lets just check that there isn't a run-test
      # script there, wh
      if ! r_locate_script_test_dir "$@"
      then
         return 1
      fi
      return 4  # make it a script test (relaxed)
   fi

   local name

   r_basename "${project_dir}"
   name="${RVAL}"

   case "${name}" in
      ${testdir}*)
         RVAL="${project_dir}"
         return 0
      ;;
   esac

   if [ -d "${testdir}" ]
   then
      RVAL="${testdir}"
      return 0
   fi

   local directory

   directory="${project_dir}/${testdir}"
   if [ -d "${directory}" ]
   then
      RVAL="${directory}"
      return 0
   fi

   local name

   r_basename "${testdir}"
   dir_name="${RVAL}"

   directory="${project_dir}/${dir_name}"
   if [ -d "${directory}" ]
   then
      RVAL="${directory}"
      return 0
   fi

   RVAL=""
   return 1
}


r_locate_main()
{
   log_entry "r_locate_main" "$@"

   r_locate_test_dir "${MULLE_TEST_DIR:-test}"
}
