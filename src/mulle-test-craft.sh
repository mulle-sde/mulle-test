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
MULLE_TEST_CRAFT_SH="included"


test_craft_usage()
{
   fail "$*"
   exit 1
}


test_craft_main()
{
   log_entry "test_craft_main" "$@"

   local args
   local makeargs
   local craftargs
   local OPTION_STANDALONE

   craftargs="--mulle-test"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|--help|help)
            test_craft_usage
         ;;

         --run-args)
            while [ $# -ne 0 ]
            do
               shift
            done
         ;;

         --standalone)
            OPTION_STANDALONE='YES'
         ;;

         --build-args)
            while [ $# -ne 0 ]
            do
               if [ "$1" == "--run-args" ]
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

         --serial|--no-parallel|--parallel)
            r_concat "${craftargs}" "'$1'"
            craftargs="${RVAL}"
         ;;

         --debug)
            OPTION_CMAKE_BUILD_TYPE='Debug';
         ;;

         --release)
            OPTION_CMAKE_BUILD_TYPE='Release';
         ;;

         --valgrind)
            # ignore, don't complain
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

   if [ "${OPTION_STANDALONE}" != 'YES' ]
   then
      makeargs="${makeargs} --preferred-library-style dynamic"
   fi

   if [ ! -z "${OPTION_CMAKE_BUILD_TYPE}" ]
   then
      craftargs="${craftargs} --configuration '${OPTION_CMAKE_BUILD_TYPE}'"
#      makeargs="${makeargs} -DCMAKE_BUILD_TYPE='${OPTION_CMAKE_BUILD_TYPE}'"
   fi

   #  a bit too clang specific here or ?
   local makeargs

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
   esac

   while [ $# -ne 0 ]
   do
      r_concat "${args}" "'$1'"
      args="${RVAL}"
      shift
   done

   (
      #
      # Crafting might use their own mulle-sde commands in cmake. So don't
      # appear as if we are in a test environment Unset MULLE_TEST_ENVIRONMENT
      # and craft without test check.
      #
      unset MULLE_TEST_ENVIRONMENT
      if ! eval_exekutor mulle-sde \
                               "${MULLE_TECHNICAL_FLAGS}" \
                               "${MULLE_SDE_FLAGS}" \
                               --no-test-check \
                            craft \
                               "${craftargs}" \
                               -- \
                               "${makeargs}"
      then
         exit 1
      fi
   )
}

