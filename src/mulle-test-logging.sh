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
MULLE_TEST_LOGGING_SH="included"


#
# more specialized exekutors
#
#
# also redirects error to output (for tests)
#
err_redirect_eval_exekutor()
{
   local output

   output="$1"
   shift

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" = "YES" -o "${MULLE_FLAG_LOG_EXEKUTOR}" = "YES" ]
   then
      if [ -z "${MULLE_EXEKUTOR_LOG_DEVICE}" ]
      then
         echo "==>" "$@" ">" "${output}" >&2
      else
         echo "==>" "$@" ">" "${output}" > "${MULLE_EXEKUTOR_LOG_DEVICE}"
      fi
   fi

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" != "YES" ]
   then
      local rval

      ( eval "$@" ) > "${output}" 2>&1
      rval=$?

      if [ "${MULLE_FLAG_LOG_EXEKUTOR}" = "YES" ]
      then
         cat "${output}" >&2 # get stderr mixed in :/
      fi

      return $rval
   fi
}



#
# more specialized exekutors
#
#
# also redirects error to output (for tests)
#
err_redirect_grepping_eval_exekutor()
{
   local output

   output="$1"
   shift

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" = "YES" -o "${MULLE_FLAG_LOG_EXEKUTOR}" = "YES" ]
   then
      if [ -z "${MULLE_EXEKUTOR_LOG_DEVICE}" ]
      then
         echo "==>" "$@" ">" "${output}" >&2
      else
         echo "==>" "$@" ">" "${output}" > "${MULLE_EXEKUTOR_LOG_DEVICE}"
      fi
   fi

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" != "YES" ]
   then
      local rval

      ( eval "$@" )  2>&1 | tee "${output}" | log_grep_warning_error
      rval=$?

      if [ "${MULLE_FLAG_LOG_EXEKUTOR}" = "YES" ]
      then
         cat "${output}" >&2 # get stderr mixed in :/
      fi

      return $rval
   fi
}


redirect_eval_exekutor()
{
   local output

   output="$1"
   shift

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" = "YES" -o "${MULLE_FLAG_LOG_EXEKUTOR}" = "YES" ]
   then
      if [ -z "${MULLE_EXEKUTOR_LOG_DEVICE}" ]
      then
         echo "==>" "$@" ">" "${output}" >&2
      else
         echo "==>" "$@" ">" "${output}" > "${MULLE_EXEKUTOR_LOG_DEVICE}"
      fi
   fi

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" != "YES" ]
   then
      ( eval "$@" ) > "${output}"
   fi
}


full_redirekt_eval_exekutor()
{
   local stdin
   local stdout
   local stderr

   stdin="$1"
   shift
   stdout="$1"
   shift
   stderr="$1"
   shift

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" = "YES" -o "${MULLE_FLAG_LOG_EXEKUTOR}" = "YES" ]
   then
      if [ -z "${MULLE_EXEKUTOR_LOG_DEVICE}" ]
      then
         echo "==>" "$@" "<" "${stdin}" ">" "${stdout}" "2>" "${stderr}" >&2
      else
         echo "==>" "$@" "<" "${stdin}" ">" "${stdout}" "2>" "${stderr}" > "${MULLE_EXEKUTOR_LOG_DEVICE}"
      fi
   fi


   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" != "YES" ]
   then
      local rval

      ( eval "$@" ) < "${stdin}" > "${stdout}" 2> "${stderr}"
      rval=$?

      if [ "${MULLE_FLAG_LOG_EXEKUTOR}" = "YES" ]
      then
         cat "${stderr}" >&2
      fi

      return $rval
   fi

}

