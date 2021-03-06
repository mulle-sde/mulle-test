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
MULLE_TEST_LINKORDER_SH="included"



test_linkorder_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} linkorder [options]

   Produce the linkorder required for test executables to link. This can
   be useful, if you are using external test scripts.

   There are two caches for the linkorder. One with the startup code and
   one without. To update both, run both commands:

   ${MULLE_USAGE_NAME} linkorder --update-cache
   ${MULLE_USAGE_NAME} linkorder --update-cache --startup

Options:
   --startup       : include startup libraries
   --no-startup    : exclude startup libraries
   --cached        : show cached valued (default)
   --uncached      : bypass cache
   --update-cache  : bypass cache but then update it
EOF
   exit 1
}


_get_link_command()
{
   log_entry "_get_link_command" "$@"

   if [ -z "${MULLE_PLATFORM_LIBEXEC_DIR}" ]
   then
      MULLE_PLATFORM_LIBEXEC_DIR="`exekutor "${MULLE_PLATFORM:-mulle-platform}" libexec-dir`" || exit 1
   fi

   [ -z "${MULLE_PATH_SH}" ] && \
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-path.sh"

   [ -z "${MULLE_PLATFORM_TRANSLATE_SH}" ] && \
      . "${MULLE_PLATFORM_LIBEXEC_DIR}/mulle-platform-translate.sh"

   local format

   r_platform_default_whole_archive_format
   format="${RVAL}"

   exekutor mulle-sde \
               ${MULLE_TECHNICAL_FLAGS} \
               ${MULLE_SDE_FLAGS} \
            linkorder \
               --output-format ld \
               --configuration "Test" \
               --output-no-final-lf \
               --whole-archive-format "${format}" \
               "$@"  # shared libs only ATM
}


r_get_link_command()
{
   log_entry "r_get_link_command" "$@"

   local withstartup="${1:-YES}"
   local caching="${2:-YES}"
   local updatecache="${3:-${caching}}"

   local linkorder_cache_filename
   local args

   [ -z "${MULLE_TEST_VAR_DIR}" ] && internal_fail "MULLE_TEST_VAR_DIR undefined"

   linkorder_cache_filename="${MULLE_TEST_VAR_DIR}/linkorder"
   args='--startup'
   if [ "${withstartup}" = 'NO' ]
   then
      args='--no-startup'
      linkorder_cache_filename="${linkorder_cache_filename}-no-startup"
   fi

   if [ "${caching}" = 'YES' -a -f "${linkorder_cache_filename}" ]
   then
      log_verbose "Using cached linkorder \"${linkorder_cache_filename}\""
      RVAL="`rexekutor cat ${linkorder_cache_filename}`"
      return 0
   fi

   local command

   log_verbose "Compiling linkorder"

   command="`_get_link_command ${args}`" || exit 1

   if [ "${updatecache}" = 'YES' ]
   then
      mkdir_if_missing "${MULLE_TEST_VAR_DIR}"
      redirect_exekutor "${linkorder_cache_filename}" printf "%s\n" "${command}"

      log_verbose "Linkorder has been cached in \"${linkorder_cache_filename}\""
   fi

   RVAL="${command}"
}



test_linkorder_main()
{
   log_entry "test_linkorder_main" "$@"

   [ -z "${MULLE_TEST_VAR_DIR}" ] && internal_fail "MULLE_TEST_VAR_DIR is empty"

   local OPTION_STARTUP='DEFAULT'
   local OPTION_CACHED='YES'
   local OPTION_UPDATE_CACHE='NO'

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|--help|help)
            test_linkorder_usage
         ;;

         --startup)
            OPTION_STARTUP='YES'
         ;;

         --no-startup)
            OPTION_STARTUP='NO'
         ;;

         --update-cache)
            OPTION_UPDATE_CACHE='YES'
            OPTION_CACHED='NO'
         ;;

         --cached)
            OPTION_CACHED='YES'
         ;;

         --uncached)
            OPTION_CACHED='NO'
         ;;

         -*)
            test_linkorder_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   case "${1:-list}" in
      clean)
         remove_file_if_present "${MULLE_TEST_VAR_DIR}/linkorder"
         remove_file_if_present "${MULLE_TEST_VAR_DIR}/linkorder-no-startup"
         return
      ;;


      list)
         if [ "${OPTION_STARTUP}" = 'DEFAULT' ]
         then
            log_info "Startup"
            r_get_link_command 'YES' "${OPTION_CACHED}" "${OPTION_UPDATE_CACHE}"
            printf "%s\n\n" "${RVAL}"

            log_info "No Startup"
            r_get_link_command 'NO' "${OPTION_CACHED}" "${OPTION_UPDATE_CACHE}"
            printf "%s\n" "${RVAL}"
         else
            r_get_link_command "${OPTION_STARTUP}" "${OPTION_CACHED}" "${OPTION_UPDATE_CACHE}"
            printf "%s\n" "${RVAL}"
         fi
      ;;

      *)
         fail "Unknown linkorder command \"$1\""
      ;;
   esac
}
