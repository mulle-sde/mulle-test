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
MULLE_TEST_CLEAN_SH="included"


test_clean_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} clean [domain]

   By default cleans everything including produced .exe files and inferior
   cmake build directories. If you want to remove the stash folder too,
   specify "tidy" as the clean domain.

EOF
   exit 1
}


depth_find_pwd()
{
   case "${MULLE_UNAME}" in
      darwin|freebsd)
         exekutor find -d . "$@"
      ;;

      *)
         exekutor find . -depth "$@"
      ;;
   esac
}


test_clean_main()
{
   log_entry "test_clean_main" "$@"

   [ -z "${MULLE_TEST_CONFIGURATION}" ] && internal_fail "MULLE_TEST_CONFIGURATION is empty"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|--help|help)
            test_clean_usage
         ;;

         -*)
            test_clean_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   exekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} \
                      ${MULLE_SDE_FLAGS} \
               clean \
                  "${1:-all}" &&
   depth_find_pwd -type d -name build -exec rm -rf {} \;
   exekutor find . -type f -name "*.exe" -exec rm {} \;
}
