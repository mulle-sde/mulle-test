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


test::clean::usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} clean [domain]

   By default cleans everything including produced .exe files and inferior
   cmake build directories. If you want to remove the stash folder too,
   specify "tidy" as the clean domain.

   If you changed the sourcetree, you can clean the linkorder chaches
   with "linkorder".

Domains:
EOF
   mulle-sde clean domains-usage >&2
   exit 1
}


test::clean::depth_find_pwd()
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


test::clean::main()
{
   log_entry "test::clean::main" "$@"

   [ -z "${MULLE_TEST_VAR_DIR}" ] && _internal_fail "MULLE_TEST_VAR_DIR is empty"

   local OPTION_CLEAN_VAR='YES'

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|--help|help)
            test::clean::usage
         ;;

         --no-var)
            OPTION_CLEAN_VAR='NO'
         ;;

         --no-graveyard)
            cleanoptions="$1"
         ;;

         -*)
            test::clean::usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   case "${1:-all}" in
      all|tidy)
         exekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} \
                     clean \
                        ${cleanoptions} \
                        "${1:-all}" &&

         log_verbose "Cleaning individual test kitchen directories"
         test::clean::depth_find_pwd -type d -name kitchen -exec rm -rf {} \;

         log_verbose "Cleaning test executables"
         exekutor find . -type f -name "*.exe" -exec rm {} \;

         log_verbose "Cleaning test coverage"
         exekutor find . -type f \( -name "*.gcda" -o -name "*.profdata" \) -exec rm {} \;

         if [ "${OPTION_CLEAN_VAR}" = 'YES' ]
         then
            log_verbose "Cleaning var"
            rmdir_safer "${MULLE_TEST_VAR_DIR}"
         fi
      ;;

      linkorder)
      ;;

      *)
         exekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} \
                     clean \
                        "$1"
         return $?
      ;;
   esac


   . "${MULLE_TEST_LIBEXEC_DIR}/mulle-test-linkorder.sh"

   test::linkorder::main clean
}
