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
MULLE_TEST_INIT_SH="included"


test_init_usage()
{
   [ $# -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} init [options]

   Initialize a "test" directory for mulle-test inside an existing mulle-sde
   project. This will create setup a new mulle-sde project, to build the
   project library as a standalone shared library.

   The test project will try to inherit the language settings from the project
   but these values can be overridden with options.

   Example:
      mulle-test init

Options:
   -d <directory>              : test directory (test)
   --project-language <name>   : test language
   --project-dialect <name>    : specify as objc for Objective-C
   --project-name <name>       : name of the standalone library to use
   --project-extensions <name> : file extensions of test files
EOF

   exit 1
}

#
# We need to make sure that mulle_default_allocator only exists once.
# Therefore compile mulle_allocator as a shared library.
#
_test_init_standalone()
{
   exekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} \
                      ${MULLE_SDE_FLAGS} \
                dependency add \
                     --marks "no-import,no-singlephase,no-static-link,only-os-darwin" \
                     --github "mulle-core" \
                     "mulle-testallocator" &&

   exekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} \
                      ${MULLE_SDE_FLAGS} \
               dependency add \
                     --github "${PROJECT_GITHUB_NAME:-unknown}" \
                     --marks "no-all-load,only-standalone" \
                     "${PROJECT_NAME}" &&

   exekutor mulle-sourcetree ${MULLE_TECHNICAL_FLAGS} \
                             ${MULLE_SOURCETREE_FLAGS} \
                duplicate \
                     --marks "no-import,no-os-darwin,no-singlephase,no-static-link" \
                     mulle-testallocator  &&

   exekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} \
                      ${MULLE_SDE_FLAGS} \
                dependency add \
                     --marks "no-import,no-singlephase,no-static-link" \
                     --github "mulle-c" \
                     "mulle-allocator" &&

   exekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} \
                      ${MULLE_SDE_FLAGS} \
                dependency add \
                     --marks "no-all-load,no-import,no-singlephase" \
                     --github "mulle-core" \
                     "mulle-stacktrace"
}


_test_init_normal()
{
   exekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} \
                      ${MULLE_SDE_FLAGS} \
                dependency add \
                     --marks "no-import,no-singlephase,no-static-link" \
                     --github "mulle-core" \
                     "mulle-testallocator" &&

   exekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} \
                      ${MULLE_SDE_FLAGS} \
               dependency add \
                     --github "${PROJECT_GITHUB_NAME:-unknown}" \
                     "${PROJECT_NAME}"
}



test_init_main()
{
   log_entry "test_init_main" "$@"

   local OPTION_DIRECTORY="test"
   local OPTION_STANDALONE=NO

   while :
   do
      case "$1" in
         -h*|--help|help)
            test_init_usage
         ;;

         -d|--directory)
            [ $# -eq 1 ] && test_init_usage "missing argument to \"$1\""
            shift

            OPTION_DIRECTORY="$1"
         ;;

         --project-name)
            [ $# -eq 1 ] && test_init_usage "missing argument to \"$1\""
            shift

            PROJECT_NAME="$1"
         ;;

         --project-language)
            [ $# -eq 1 ] && test_init_usage "missing argument to \"$1\""
            shift

            PROJECT_LANGUAGE="$1"
         ;;

         --project-dialect)
            [ $# -eq 1 ] && test_init_usage "missing argument to \"$1\""
            shift

            PROJECT_DIALECT="$1"
         ;;

         --project-extensions)
            [ $# -eq 1 ] && test_init_usage "missing argument to \"$1\""
            shift

            PROJECT_EXTENSIONS="$1"
         ;;

         --github-name)
            [ $# -eq 1 ] && test_init_usage "missing argument to \"$1\""
            shift

            PROJECT_GITHUB_NAME="$1"
          ;;

         --standalone)
            OPTION_STANDALONE="YES"
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -eq 0 ] || test_init_usage


   [ ! -d ".mulle/share/sde" ] && \
         log_warning "Test folder should be top level of a mulle-sde project"

   if [ -z "${PROJECT_LANGUAGE}" ]
   then
      PROJECT_LANGUAGE="`rexekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} \
                      ${MULLE_SDE_FLAGS} environment get PROJECT_LANGUAGE`"
   fi

   if [ -z "${PROJECT_DIALECT}" ]
   then
      PROJECT_DIALECT="`rexekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} \
                      ${MULLE_SDE_FLAGS} environment get PROJECT_DIALECT`"
   fi

   if [ -z "${PROJECT_EXTENSIONS}" ]
   then
      PROJECT_EXTENSIONS="`rexekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} \
                      ${MULLE_SDE_FLAGS} environment get PROJECT_EXTENSIONS`"
   fi

   if [ -z "${PROJECT_NAME}" ]
   then
      PROJECT_NAME="`rexekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} \
                      ${MULLE_SDE_FLAGS} environment get PROJECT_NAME`"
   fi

   if [ -z "${PROJECT_NAME}" ]
   then
      r_fast_basename "${PWD}"
      PROJECT_NAME="${RVAL}"
   fi

   if [ -z "${PROJECT_GITHUB_NAME}" ]
   then
      PROJECT_GITHUB_NAME="${LOGNAME}"
   fi

   #
   # also set project language and dialect from main project
   # use wild, since we don't want to copy all the tools and optionaltools
   # over and have them get out of sync eventually
   #
   exekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} \
                      ${MULLE_SDE_FLAGS} \
                      -s \
               init --no-motd \
                    --style mulle/wild \
                    --project-name "${PROJECT_NAME}" \
                    --project-language "${PROJECT_LANGUAGE:-c}" \
                    --project-dialect "${PROJECT_DIALECT:-c}" \
                    --project-extensions "${PROJECT_EXTENSIONS:-c}" \
                    -d "${OPTION_DIRECTORY}" \
                    none &&
   (
      unset MULLE_VIRTUAL_ROOT

      #
      # mulle-testallocator markes as all-load, because we need it
      # always linked in. Also link it first, so its constructor gets
      # executed first. This only happens when it is a dynamic library though.
      #
      # More tricky stuff is needed to make this work on darwin and linux
      # including a "duplicate" entry for darwinthat is ignored by linux
      # The main thing, is that mulle-testallocator must be before standalone
      # on darwin and behind on linux
      #
      exekutor cd "${OPTION_DIRECTORY}" &&
      mkdir_if_missing ".mulle/share/sde" &&
      exekutor redirect_exekutor ".mulle/share/sde/mulle-test" date &&
      if [ "${OPTION_STANDALONE}" = YES ]
      then
         _test_init_standalone || exit 1
      else
         _test_init_normal || exit 1
      fi

      exekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} \
                         ${MULLE_SDE_FLAGS} \
               environment \
                  --global \
                  set MULLE_FETCH_SEARCH_PATH '${MULLE_VIRTUAL_ROOT}/../..'

   )
}
