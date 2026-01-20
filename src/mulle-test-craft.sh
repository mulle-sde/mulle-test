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


#test::craft::emit_include_private_h()
#{
#   log_entry "test::craft::emit_include_private_h" "$@"
#
#   local dialect="${1:-}"        # "", "c" or "objc"
#   local configuration="${2:-Debug}"
#   local guard_identifier="$3"
#
#   include "case"
#
#  # Prepare the output file with include guards
#  r_smart_file_downcase_identifier "${PROJECT_NAME}"
#  {
#    printf "#ifndef ${guard_identifier}\n"
#    printf "#define ${guard_identifier}\n\n"
#    printf "// THIS FILE WILL BE CLOBBERED BY mulle-sde test craft\n\n"
#    if [ "${dialect}" = "objc" ]; then
#      printf "#import \"import.h\"\n"
#    else
#      printf "#include \"include.h\"\n"
#    fi
#    printf "\n#endif /* ${guard_identifier} */\n"
#  }
#}
#

test::craft::emit_include_h()
{
   log_entry "test::craft::emit_include_h" "$@"

   local dialect="${1:-}"        # "", "c" or "objc"
   local configuration="${2:-Debug}"
   local meta_dialect="$3"
   local guard_identifier="$4"

   local DEPENDENCY_DIR

   # 1) Resolve dependency directory
   if ! DEPENDENCY_DIR="$(mulle-sde dependency-dir)" 
   then
      fail "Error: failed to get dependency-dir"
   fi

   # 2) Locate include root
   # MEMO: need to ask craft where stuff is placed
   local style 

   style="$(mulle-craft style --configuration "${configuration}")"

   local INC_ROOT

   r_filepath_concat "${DEPENDENCY_DIR}" "$style" "include"
   INC_ROOT="${RVAL}"

   if [ ! -d "$INC_ROOT" ]
   then
      INC_ROOT="${DEPENDENCY_DIR}/include"
      if [ ! -d "$INC_ROOT" ]
      then
         log_setting "DEPENDENCY_DIR=${DEPENDENCY_DIR}"
         log_setting "style=${style}"
         log_setting "configuration=${configuration}"

         log_warning "Warning: include directory '$INC_ROOT' does not exist"
         return 0
      fi
   fi

   {
      if [ "${dialect}" != "objc" ]
      then
         printf "#ifndef %s\n" "${guard_identifier}"
         printf "#define %s\n\n" "${guard_identifier}"
      fi

      printf "// THIS FILE WILL BE CLOBBERED BY mulle-sde test craft\n\n"

      if [ "${dialect}" = "objc" ]
      then
         printf "#include \"include.h\"\n\n"
      fi

      # Helper to decide emission based on dialect and language
      emit_line()
      {
         local path="$1"
         local is_objc="$2"   # "yes" or "no"

         # Skip if dialect excludes this language
         if [ "${dialect}" = "c" ]   && [ "${is_objc}" = "yes" ];  then return 0; fi
         if [ "${dialect}" = "objc" ] && [ "${is_objc}" = "no" ];   then return 0; fi

         # Emit directive
         if [ "${dialect}" = "objc" ] && [ "${is_objc}" = "yes" ]; then
            printf "#import <%s>\n" "${path}"
         else
            printf "#include <%s>\n" "${path}"
         fi
      }

      local hdr
      local rel

      # 4) Top-level headers (always C)
      for hdr in $(find "$INC_ROOT" -maxdepth 1 -type f -name '*.h' | sort)
      do
         rel="${hdr#$INC_ROOT/}"
         emit_line "${rel}" "no"
      done

      # blank line if any top-level headers
      if [ -n "$(find "$INC_ROOT" -maxdepth 1 -type f -name '*.h')" ]
      then
         printf "\n"
      fi

      local root_hdr
      local depdir
      local depname

      # 5) Per-dependency headers
      for depdir in $(find "$INC_ROOT" -maxdepth 1 -mindepth 1 -type d | sort)
      do
         r_basename "${depdir}"
         depname="${RVAL}"

         root_hdr="${depdir}/${depname}.h"

         # HACK:
         # do not emit #include <mulle-objc-runtime/mulle-objc-runtime.h>
         # as it conflicts with MulleObjC.
         # Future: use .no-mulle-test file ?
         if [ "${meta_dialect}" = "objc" ]
         then
            case "${depname}" in
               'mulle-objc-'*)
                  # except if we are actually in mulle-objc-runtime
                  if [ "${PROJECT_NAME}" != 'mulle-objc-runtime' -a \
                       "${PROJECT_NAME}" != 'mulle-objc-debug' ]
                  then
                     log_debug "Skip \"${depname}\""
                     continue
                  fi
               ;;
            esac
         fi

         # HACK:
         # do not emit #include <mintomic/mintomic.h>
         # as its private (and gives problems)
         # Future: use .no-mulle-test file ?
         case "${depname}" in
            *'mintomic')
               log_debug "Skip \"${depname}\""
               continue
            ;;
         esac

         # Check if root header exists
         if [ -f "$root_hdr" ]
         then
            if [ ! -e "${depdir}/.no-mulle-test" ]  # a way to keep it out of include
            then
               # ObjC heuristic
               if [[ "${depname:0:1}" =~ [A-Z] ]]
               then
                  emit_line "${depname}/${depname}.h" "yes"
               else
                  emit_line "${depname}/${depname}.h" "no"
               fi
            fi
            continue
         fi

         # no root header: include all headers under this directory
         while IFS= read -r hdr
         do
            rel="${hdr#$INC_ROOT/}"
            emit_line "${rel}" "no"
         done < <(find "$depdir" -type f -name '*.h' ! -path "*/cmake/*" | sort)
      done

      if [ "${dialect}" != "objc" ]
      then
         printf "\n#endif /* %s */\n" "${GUARD}"
      else
         printf "\n"
      fi
   }
}


test::craft::emit_import_h()
{
   log_entry "test::craft::emit_import_h" "$@"

   local configuration="$1"
   shift

   test::craft::emit_include_h 'objc' "${configuration}" 'objc' "$@"
}



test::craft::generate_generic_c_headers()
{
   log_entry "test::craft::generate_generic_headers" "$@"

   local text

   if ! text=`test::craft::emit_include_h 'c' "$@"`
   then
      return 1
   fi
   redirect_exekutor "include.h" printf "%s\n" "${text}"

#   if ! text=`test::craft::emit_include_private_h 'c' "$@"`
#   then
#      return 1
#   fi
#   redirect_exekutor "include-private.h" printf "%s\n" "${text}"
}


test::craft::generate_generic_objc_headers()
{
   log_entry "test::craft::generate_generic_objc_headers" "$@"

   local text

   if ! text=`test::craft::emit_import_h "$@"`
   then
      return 1
   fi
   redirect_exekutor "import.h" printf "%s\n" "${text}"

#   if ! text=`test::craft::emit_import_private_h "$@"`
#   then
#      return 1
#   fi
#   redirect_exekutor "import-private.h" printf "%s\n" "${text}"
}


test::craft::postprocess()
{
   log_entry "test::craft::postprocess" "$@"

   local configuration="$1"

   if [ -z "${PROJECT_NAME}" ]
   then
      fail "PROJECT_NAME not set, but is required for post-processing"
   fi

   local guard_name

   guard_name="${PROJECT_NAME}"
   if [ -z "${TEST_PROJECT_NAME}" ]
   then
      guard_name="${PROJECT_NAME}-test"
   fi

   include "case"

   # 3) Prepare include guard
   r_smart_file_downcase_identifier "${guard_name}"
   guard_name="${RVAL}"

   case "${PROJECT_LANGUAGE}" in
      'c')
         test::craft::generate_generic_c_headers "${configuration}" \
                                                 "${PROJECT_DIALECT:-c}" \
                                                 "${guard_name}_include_h__"

         case "${PROJECT_DIALECT}" in
            'objc')
               test::craft::generate_generic_objc_headers "${configuration}"
            ;;
         esac
      ;;
   esac
}

test::craft::main()
{
   log_entry "test::craft::main" "$@"

   local args
   local craftargs
   local sdeargs
   local OPTION_STANDALONE
   local OPTION_POSTPROCESS='DEFAULT'

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

         --postprocess)
            OPTION_POSTPROCESS='YES';
         ;;

         --postprocess-only|--only-postprocess)
            OPTION_POSTPROCESS='ONLY';
         ;;

         --no-postprocess)
            OPTION_POSTPROCESS='NO';
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

   if [ "${OPTION_POSTPROCESS}" != 'ONLY' ]
   then
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
   ) || return $?
   fi

   #
   # post processing depending on language, currently hardcoded argh
   #
   if [ "${OPTION_POSTPROCESS}" != 'NO' ]
   then
      test::craft::postprocess "${OPTION_CONFIGURATION}"
   fi
}

