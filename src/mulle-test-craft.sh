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
MULLE_TEST_CRAFT_SH='included'


test::craft::usage()
{
   fail "$*"
   exit 1
}


test::craft::main()
{
   log_entry "test::craft::main" "$@"

   local args
   local craftargs
   local sdeargs
   local OPTION_STANDALONE

   if [ "${MULLE_TEST_DEFINE}" = 'YES' ]
   then
      craftargs="--mulle-test"
   fi
   
   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|--help|help)
            test::craft::usage
         ;;

         --build-args)
            while [ $# -ne 0 ]
            do
               if [ "$1" = "--run-args" ]
               then
                  while [ $# -ne 0 ]
                  do
                     shift
                  done
                  break
               fi

               r_concat "${craftargs}" "'$1'"
               craftargs="${RVAL}"
               shift
            done
         ;;

         --coverage)
            r_colon_concat "${SANITIZER}" coverage
            SANITIZER="${RVAL}"
         ;;

         --valgrind|--sanitize*)
            # ignore, don't complain
         ;;

         -g|-a)
            r_concat "${sdeargs}" "$1"
            sdeargs="${RVAL}"
         ;;

         --debug)
            OPTION_CONFIGURATION='Debug';
         ;;

         --release)
            OPTION_CONFIGURATION='Release';
         ;;

         --run-args)
            while [ $# -ne 0 ]
            do
               shift
            done
         ;;

         --serial|--no-parallel|--parallel)
            r_concat "${sdeargs}" "'$1'"
            sdeargs="${RVAL}"
         ;;

# TODO: Doesn't work for some reason
#        --from)
#           shift
#           r_concat "${craftargs}" "--from '$1'"
#           craftargs="${RVAL}"
#        ;;

         --standalone)
            OPTION_STANDALONE='YES'
         ;;

         --)
            shift
            break
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   # we force no-clean since we don't have a project per se in test
   # only craftorders (also: the caller has clean beforehand...)
   sdeargs="${sdeargs} --no-clean"

   configuration="${OPTION_CONFIGURATION:-Debug}"

   if [ ! -z "${configuration}" ]
   then
      craftargs="${craftargs} --configuration '${configuration}'"
#      makeargs="${makeargs} -DCMAKE_BUILD_TYPE='${configuration}'"
   fi

   #  a bit too clang specific here or ?

   if [ "${OPTION_STANDALONE}" != 'YES' ]
   then
      craftargs="${craftargs} --preferred-library-style dynamic"
   fi

   local makeargs
   local envflags

   case ":${SANITIZER}:" in
      *:undefined:*)
         makeargs="${makeargs} -DOTHER_CFLAGS+=-fsanitize=undefined"
      ;;

      *:thread:*)
         makeargs="${makeargs} -DOTHER_CFLAGS+=-fsanitize=thread"
      ;;

      *:address:*)
         makeargs="${makeargs} -DOTHER_CFLAGS+=-fsanitize=address"
      ;;

      *:coverage:*)
#         makeargs="${makeargs} -DOTHER_CFLAGS+=--coverage"
         makeargs="${makeargs} -DOTHER_CFLAGS+=--coverage"
         makeargs="${makeargs} -DOTHER_CFLAGS+=-fno-inline"
         makeargs="${makeargs} -DOTHER_CFLAGS+=-DNDEBUG"
         makeargs="${makeargs} -DOTHER_CFLAGS+=-DNS_BLOCK_ASSERTIONS"
         # envflags="-DGCOV_PREFIX='${PWD}/gcovdata'"
      ;;
   esac

   while [ $# -ne 0 ]
   do
      r_concat "${makeargs}" "'$1'"
      makeargs="${RVAL}"
      shift
   done

   (
      #
      # Crafting might use their own mulle-sde commands in cmake. So don't
      # appear as if we are in a test environment. Unset MULLE_TEST_ENVIRONMENT
      # and craft without test check.
      #
      unset MULLE_TEST_ENVIRONMENT
      if ! eval_exekutor mulle-sde \
                               "${MULLE_TECHNICAL_FLAGS}" \
                               "${MULLE_SDE_FLAGS}" \
                               "${envflags}" \
                               --no-test-check \
                            craft \
                               "${sdeargs}" \
                               -- \
                               "${craftargs}" \
                               -- \
                               "${makeargs}"
      then
         exit 1
      fi
   )
}

