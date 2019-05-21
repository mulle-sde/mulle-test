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

   makeargs="'-DCFLAGS+=-DMULLE_TEST=1' --library-style dynamic"

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

   while [ $# -ne 0 ]
   do
      r_concat "${args}" "'$1'"
      args="${RVAL}"
      shift
   done

   if ! eval_exekutor mulle-sde \
                            "${MULLE_TECHNICAL_FLAGS}" \
                            "${MULLE_SDE_FLAGS}" \
                         craft \
                            --configuration 'Test' \
                            "${craftargs}" \
                            -- \
                            "${makeargs}"
   then
      return 1
   fi

   #
   # cache linkorder for tests
   #
}

