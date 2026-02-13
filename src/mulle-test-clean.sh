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
MULLE_TEST_CLEAN_SH='included'


test::clean::usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} clean

   Cleans all produced .exe files and cmake build directories.
   If you want to remove the stash folder or the dependency folder use
   mulle-sde test clean instead.

Options:
   -q  : does not clean .mulle/var/test
EOF
   exit 1
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

         -*)
            test::clean::usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done


   [ $# -ne 0 ] && test::clean::usage "Superflous arguments \"$*\""

   log_verbose "Cleaning individual test kitchen directories"

   local dir

   while read -r dir
   do
      exekutor rmdir_safer "$dir"
   done < <(find * -type d -name 'kitchen' ! -path "${KITCHEN_DIR:-kitchen}")

   log_verbose "Cleaning test executables"

   local file

   while read -r file
   do
     remove_file_if_present "$file"
   done < <(find * -type f -name "*.exe")

   log_verbose "Cleaning test vibecode output"
   while read -r file
   do
     remove_file_if_present "$file"
   done < <(find * -type f \( -name "*.test.stderr" -o -name "*.test.stdout" -o -name "*.test.ccerr" \))

   log_verbose "Cleaning test coverage"
   while read -r file
   do
     remove_file_if_present "$file"
   done < <(find * -type f \( -name "*.gcno" -o -name "*.gcda" -o -name "*.profdata" \))


   if [ "${OPTION_CLEAN_VAR}" = 'YES' ]
   then
      log_verbose "Cleaning var"
      rmdir_safer "${MULLE_TEST_VAR_DIR}"
   fi
}
