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
MULLE_TEST_LINK_ARGS_SH='included'


test::link_args::usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} link_args [options]

   Produce the link_args required for test executables to link. This can
   be useful, if you are using external test scripts.

   There are two files for linking. One with the startup code for executables
   and the other without for shared libraries. 

Options:
   --startup       : include startup libraries
   --no-startup    : exclude startup libraries
   --platform      : specify platform (default: current platform)
EOF
   exit 1
}



test::link_args::main()
{
   log_entry "test::link_args::main" "$@"

   local OPTION_STARTUP='DEFAULT'
   local OPTION_PLATFORM="${MULLE_PLATFORM}"
   local OPTION_CONFIGURATION="${OPTION_CONFIGURATION:-Debug}"
   local OPTION_SDK="${OPTION_SDK:-Default}"
   local OPTION_TERSE


   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|--help|help)
            test::link_args::usage
         ;;

         -s)
            OPTION_TERSE='YES'
         ;;

         --startup)
            OPTION_STARTUP='YES'
         ;;

         --no-startup)
            OPTION_STARTUP='NO'
         ;;

         --configuration)
            [ $# -eq 1 ] && test::link_args::usage "Missing argument to \"$1\""
            shift

            OPTION_CONFIGURATION="${1:-${OPTION_CONFIGURATION}}"
         ;;

         --platform)
            [ $# -eq 1 ] && test::link_args::usage "Missing argument to \"$1\""
            shift

            OPTION_PLATFORM="${1:-${OPTION_PLATFORM}}"
         ;;

         --sdk)
            [ $# -eq 1 ] && test::link_args::usage "Missing argument to \"$1\""
            shift

            OPTION_SDK="${1:-${OPTION_SDK}}"
         ;;

         -*)
            test::link_args::usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ -z "${DEPENDENCY_DIR}" ] && _internal_fail "DEPENDENCY_DIR is empty."$'\n'\
"${C_INFO}Run this command in the proper envrionment with ${C_RESET_BOLD}mulle-sde exec"

   local style  

   style="${OPTION_SDK}-${OPTION_PLATFORM}-${OPTION_CONFIGURATION}"

   local LINKORDER_FILE 

   r_filepath_concat "${DEPENDENCY_DIR}" "etc" "link--${style}"
   LINKORDER_FILE="${RVAL}"

   if [ ! -f "${LINKORDER_FILE}" ]
   then
      fail "Link command file ${C_RESET_BOLD}${LINKORDER_FILE#${MULLE_USER_PWD}/}${C_ERROR} is missing"$'\n'"${C_INFO}A ${C_RESET_BOLD}mulle-sde test craft${C_INFO} is needed."
   fi

   case "${1:-cat}" in
      cat)
         case "${OPTION_STARTUP}" in 
            'DEFAULT')
               [ "${OPTION_TERSE}" != 'YES' ] && log_info "Startup"
               cat "${LINKORDER_FILE}--startup"

               [ "${OPTION_TERSE}" != 'YES' ] && log_info "No Startup"
               cat "${LINKORDER_FILE}"
            ;;

            'YES')
               [ "${OPTION_TERSE}" != 'YES' ] && log_info "Startup"
               cat "${LINKORDER_FILE}--startup"
            ;;

            'NO')
               [ "${OPTION_TERSE}" != 'YES' ] && log_info "No Startup"
               cat "${LINKORDER_FILE}"
            ;;
         esac
      ;;

      list)
         [ "${OPTION_TERSE}" != 'YES' ] && log_info "Startup"
         printf "%s\n" "${LINKORDER_FILE}--startup"
         [ "${OPTION_TERSE}" != 'YES' ] && log_info "No Startup"
         printf "%s\n" "${LINKORDER_FILE}"
      ;;

      *)
         fail "Unknown link_args command \"$1\""
      ;;
   esac
}
