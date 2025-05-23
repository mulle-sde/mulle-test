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
MULLE_TEST_INIT_SH='included'


test::init::usage()
{
   [ $# -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} init [options]

   Initialize a "test" directory for mulle-test inside an existing mulle-sde
   project. This will setup a new mulle-sde project, separate and largely
   independent from the to be tested project.

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


test::init::r_find_initscript_filepath()
{
   log_entry "test::init::r_find_initscript_filepath" "$@"

   local filename="$1"

   local filepath

   RVAL="${PROJECT_ROOT_DIR}/.mulle/etc/test/${PROJECT_DIALECT}/${filename}.sh"
   [ -f "${RVAL}" ] && return 0

   RVAL="${PROJECT_ROOT_DIR}/.mulle/share/test/${PROJECT_DIALECT}/${filename}.sh"
   [ -f "${RVAL}" ] && return 0

   RVAL="${PROJECT_ROOT_DIR}/.mulle/etc/test/${PROJECT_LANGUAGE}/${filename}.sh"
   [ -f "${RVAL}" ] && return 0

   RVAL="${PROJECT_ROOT_DIR}/.mulle/share/test/${PROJECT_LANGUAGE}/${filename}.sh"
   [ -f "${RVAL}" ] && return 0

   return 1
}


test::init::execute_script()
{
   log_entry "test::init::execute_script" "$@"

   local script="$1"
   local standalone="$2"

   if ! test::init::r_find_initscript_filepath "${script}"
   then
      log_verbose "No \"${script}\" script found"
      return
   fi

   local scriptpath

   scriptpath="${RVAL}"

   if [ ! -x "${scriptpath}" ]
   then
      fail "\"${scriptpath#"${MULLE_USER_PWD}/"}\" is not installed as an executable"
   fi

   log_verbose "Executing \"${scriptpath#"${MULLE_USER_PWD}/"} ${args}\""

   local args

   if [ "${standalone}" = 'YES' ]
   then
      args="--standalone"
   fi

   eval_exekutor PROJECT_NAME="'${PROJECT_NAME}'" \
                 PROJECT_LANGUAGE="'${PROJECT_LANGUAGE}'" \
                 PROJECT_DIALECT="'${PROJECT_DIALECT}'" \
                 PROJECT_EXTENSIONS="'${PROJECT_EXTENSIONS}'" \
                 PROJECT_TYPE="'${PROJECT_TYPE}'" \
                 GITHUB_USER="'${GITHUB_USER}'" \
                 PROJECT_ROOT_DIR="'${PROJECT_ROOT_DIR}'" \
                 PREFERRED_STARTUP_LIBRARY="'${PREFERRED_STARTUP_LIBRARY}'" \
                 MULLE_BASHFUNCTIONS_LIBEXEC_DIR="'${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}'" \
                 "'${scriptpath}'" "${args}" || exit 1
}


test::init::main()
{
   log_entry "test::init::main" "$@"

   local OPTION_DIRECTORY="test"
   local OPTION_STANDALONE='NO'
   local OPTION_EXECUTABLE='NO'
   local APPEND_TEST_TO_NAME='YES'

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            test::init::usage
         ;;

         -d|--directory)
            [ $# -eq 1 ] && test::init::usage "missing argument to \"$1\""
            shift

            OPTION_DIRECTORY="$1"
         ;;

         --project-name)
            [ $# -eq 1 ] && test::init::usage "missing argument to \"$1\""
            shift

            PROJECT_NAME="$1"
            APPEND_TEST_TO_NAME='NO'
         ;;

         --project-language)
            [ $# -eq 1 ] && test::init::usage "missing argument to \"$1\""
            shift

            PROJECT_LANGUAGE="$1"
         ;;

         --project-dialect)
            [ $# -eq 1 ] && test::init::usage "missing argument to \"$1\""
            shift

            PROJECT_DIALECT="$1"
         ;;

         --project-extensions)
            [ $# -eq 1 ] && test::init::usage "missing argument to \"$1\""
            shift

            PROJECT_EXTENSIONS="$1"
         ;;

         --project-type)
            [ $# -eq 1 ] && test::init::usage "missing argument to \"$1\""
            shift

            PROJECT_TYPE="$1"
         ;;

         --executable)
            OPTION_EXECUTABLE='YES'
         ;;

         --github-name)
            [ $# -eq 1 ] && test::init::usage "missing argument to \"$1\""
            shift

            GITHUB_USER="$1"
          ;;

         --shared)
            OPTION_STANDALONE='NO'
         ;;

         --standalone)
            OPTION_STANDALONE='YES'
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -eq 0 ] || test::init::usage

   local parentdir

   r_simplified_path "${PWD}/${OPTION_DIRECTORY}/.."
   parentdir="${RVAL}"

   if [ -z "${PROJECT_ROOT_DIR}" ]
   then
      PROJECT_ROOT_DIR="`rexekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} \
                      project-dir 2> /dev/null`"
   fi

   if [ ! -z "${PROJECT_ROOT_DIR}" ]
   then
      if [ -z "${PROJECT_NAME}" ]
      then
         local envfile

         envfile="`rexekutor mulle-env ${MULLE_TECHNICAL_FLAGS} \
                         environment scope file --if-exists project`"
         if [ ! -z "${envfile}" ]
         then
            . "${envfile}" || exit 1
         fi
      fi
   else
      [ ! -d "${parentdir}/.mulle/share/sde" ] && \
      log_warning "warning: Test folder should be at the top level of a mulle-sde project"
   fi

   if [ -z "${PROJECT_NAME}" ]
   then
      r_basename "${PWD}"
      PROJECT_NAME="${RVAL}"
   fi

   if [ "${OPTION_EXECUTABLE}" = 'YES' ]
   then
      PROJECT_TYPE="executable"
      PROJECT_EXTENSIONS="args"
   fi

   # normalize...
   case "${PROJECT_TYPE}" in
      library)
         # PROJECT_TYPE="library"
      ;;

      *)
         PROJECT_TYPE="executable"
      ;;
   esac

   if [ -z "${PREFERRED_STARTUP_LIBRARY}" -a -d .mulle ]
   then
      PREFERRED_STARTUP_LIBRARY="`rexekutor mulle-env -s ${MULLE_TECHNICAL_FLAGS} \
                                              environment get PREFERRED_STARTUP_LIBRARY`"
   fi

   TEST_PROJECT_NAME="${PROJECT_NAME}"
   if [ "${APPEND_TEST_TO_NAME}" = 'YES' ]
   then
      PROJECT_NAME="${PROJECT_NAME}-test"
   fi

   #
   # also set project language and dialect from main project
   # use wild, since we don't want to copy all the tools and optionaltools
   # over and have them get out of sync eventually
   #
   PROJECT_LANGUAGE="${PROJECT_LANGUAGE:-c}"
   PROJECT_DIALECT="${PROJECT_DIALECT:-c}"
   PROJECT_EXTENSIONS="${PROJECT_EXTENSIONS:-c}"

   eval_exekutor PREFERRED_STARTUP_LIBRARY="${PREFERRED_STARTUP_LIBRARY}" \
      mulle-sde ${MULLE_TECHNICAL_FLAGS} \
                         -s \
                  init --no-motd \
                       --style 'mulle/wild' \
                       --github-user "'${GITHUB_USER}'" \
                       --project-name "'${PROJECT_NAME}'" \
                       --test-project-name "'${TEST_PROJECT_NAME}'" \
                       --project-language "'${PROJECT_LANGUAGE}'" \
                       --project-dialect "'${PROJECT_DIALECT}'" \
                       --project-extensions "'${PROJECT_EXTENSIONS}'" \
                       -d "'${OPTION_DIRECTORY}'" \
                       -m "'mulle-sde/${PROJECT_DIALECT}-test-${PROJECT_TYPE:-executable}'" \
                       none || return $?

   # move below startup code if any (don't do this anymore because
   # of mulle-testallocator which needs to get the amalgamated libraries from
   # mulle-core)
   #
   # (
   #    rexekutor cd "${OPTION_DIRECTORY}" &&
   #    exekutor mulle-sourcetree -N -s move "${PROJECT_NAME}" bottom
   # )
}

