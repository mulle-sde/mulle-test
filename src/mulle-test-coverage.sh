# shellcheck shell=bash
#
#   Copyright (c) 2023 Nat! - Mulle kybernetiK
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
MULLE_TEST_COVERAGE_SH='included'


test::coverage::usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} coverage ...

   Forthcoming

Options:
EOF
   exit 1
}


test::coverage::copy_object_files()
{
   log_entry "test::coverage::copy_object_files" "$@"

   local dstdir="$1"
   local srcdir="$2"
   local gcov="$3"

   local files

   files="`find "${srcdir}" \(  -name "*.gcno" \
                            -o -name "*.gcda" \
                            -o -name "*.o" \
                            -o -name "*.obj" \
                            \) -print`"

   local filename

   local name
   local ext

   .foreachline filename in ${files}
   .do
      r_extensionless_basename "${filename}"
      name="${RVAL}"

      r_path_extension "${filename}"
      ext="${RVAL}"

      if [ "${gcov}" = 'YES' ]
      then
         name="${name%%.*}"
      fi

      exekutor ln -s "${filename}" "${dstdir}/${name}.${ext}"
   .done
}


test::coverage::find_header_files()
{
   log_entry "test::coverage::find_header_files" "$@"
   local filepaths="$1"; shift

   local filepath

   .foreachpath filepath in ${filepaths}
   .do
      find "${srcdir}" \( -name "*.h" \
                          -o -name "*.[Hh][Pp][Pp]" \
                          -o -name "*.inc" \
                       \) "$@"
   .done
}


test::coverage::find_source_files()
{
   log_entry "test::coverage::find_source_files" "$@"
   local filepaths="$1"; shift

   local filepath

   .foreachpath filepath in ${filepaths}
   .do
      find "${filepath}" \( -name "*.[cmiCM]" \
                          -o -name "*.c[cp]" \
                          -o -name "*.mm" \
                          -o -name "*.[Cc][Pp][Pp]" \
                          -o -name "*.[Cc][Pp][Pp][Mm]" \
                          -o -name "*.[Cc][Xx][Xx]" \
                          -o -name "*.[Cc]++" \
                       \) "$@"
   .done
}


test::coverage::r_gcov_prepare_objects()
{
   log_entry "test::coverage::r_gcov_prepare_objects" "$@"
   local filepaths="$1"

   local OBJFLATROOT

   r_make_tmp_directory "cov-obj"
   OBJFLATROOT="${RVAL}"

   # avoid overwriting duplicate names
   local filepath
   local count
   local dir

   .foreachpath filepath in ${filepaths}
   .do
      if ! is_absolutepath "${filepath}"
      then
         r_absolutepath "${filepath}"
         filepath="${RVAL}"
      fi

      r_filepath_concat "${OBJFLATROOT}" "${count}"
      dir="${RVAL}"
      mkdir_if_missing "${dir}"

      test::coverage::copy_object_files "${dir}" "${filepath}" 'YES'
      count=$(( ${count:-0} + 1 ))
   .done
   RVAL="${OBJFLATROOT}"
}


test::coverage::r_gcov_prepare_sources()
{
   log_entry "test::coverage::r_gcov_prepare_sources" "$@"
   local filepaths="$1"

   local SRCFLATROOT

   r_make_tmp_directory "cov-src"
   SRCFLATROOT="${RVAL}"

   # avoid overwriting duplicate names
   local filepath
   local count
   local dir

   .foreachpath filepath in ${filepaths}
   .do
      if ! is_absolutepath "${filepath}"
      then
         r_absolutepath "${filepath}"
         filepath="${RVAL}"
      fi

      r_filepath_concat "${SRCFLATROOT}" "${count}"
      dir="${RVAL}"
      mkdir_if_missing "${dir}"

      test::coverage::find_source_files "${filepath}" -print0 \
      | exekutor xargs -0 -I {} ln -s {} "${dir}/"

      count=$(( ${count:-0} + 1 ))
   .done
   RVAL="${SRCFLATROOT}"
}


test::coverage::main()
{
   log_entry "test::coverage::main" "$@"

   local exe
   local exename

   if ! exe="`command -v "$1"`"
   then
      fatal "coverage tool \"$1\" is not in PATH"
   fi
   shift

   r_extensionless_basename "${exe}"
   exename="${RVAL}"

   local OBJROOT
   local SRCROOT
   local OBJFLATROOT

   OBJROOT="`rexekutor mulle-craft ${MULLE_TECHNICAL_FLAGS} craftorder-kitchen-dir "${PROJECT_NAME}"`" \
   || fatal "could not find object files for ${PROJECT_NAME}"
   # remove cruft that will give us warnings
   exekutor find "${OBJROOT}" -name "*CMakeCCompilerId.gcno" -exec rm {} \;
   SRCROOT="`( cd .. ; mulle-sde source-dir)`"

   log_setting "exe     : ${exe} "
   log_setting "exename : ${exename} "
   log_setting "OBJROOT : ${OBJROOT} "
   log_setting "SRCROOT : ${SRCROOT} "

   #
   # the whole gcov coverage thing is in dire need of innovation
   #
   case "${exename}" in
      gcovr)
         local gcovroptions

         if gcovroptions="`grep -E -v '^#' .gcovr-options 2> /dev/null`"
         then
            log_verbose "Using options ${C_RESET_BOLD}${gcovroptions}${C_VERBOSE} found in ${C_RESET_BOLD}.gcovr-options"
         fi
#         include "test::run"
#
#         test::run::r_all_test_roots 'YES' ':'
#         roots="${RVAL}"
#
#         test::coverage::r_gcov_prepare_objects "${OBJROOT}:${roots}"
#         OBJFLATROOT="${RVAL}"
#
#         test::coverage::r_gcov_prepare_sources "${SRCROOT}:${roots}"
#         SRCFLATROOT="${RVAL}"

         exekutor "${exe}" --object-directory="${OBJROOT}" \
                           --root="${SRCROOT}" \
                           ${gcovroptions} \
                           "$@"
         rc=$?

         # rmdir_safer "${OBJFLATROOT}"
         # rmdir_safer "${SRCFLATROOT}"
         return $rc
      ;;

      gcov)
         test::coverage::r_gcov_prepare_objects "${OBJROOT}"
         OBJFLATROOT="${RVAL}"

         test::coverage::find_source_files "${SRCROOT}" -print0 \
         | exekutor xargs -0 "${exe}" --object-directory "${OBJFLATROOT}" "$@"
         rc=$?

         rmdir_safer "${OBJFLATROOT}"
         return $rc
      ;;

      *)
         test::coverage::r_gcov_prepare "${SRCROOT}" "${OBJROOT}"
         export OBJFLATROOT="${RVAL}"
         export OBJROOT
         export SRCROOT
         exekutor "${exe}" "$@"
         rc=$?
         rmdir_safer "${OBJFLATROOT}"
         return $rc
      ;;
   esac
}

