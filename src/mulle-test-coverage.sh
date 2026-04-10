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


#
# Read the gcov format version from a .gcno file header (bytes 4-7)
# and find a matching gcov-N executable. The version is e.g. "*11B"
# meaning GCC 11 format. Returns the gcov executable path in RVAL.
#
test::coverage::r_find_matching_gcov()
{
   log_entry "test::coverage::r_find_matching_gcov" "$@"

   local objroot="$1"

   local gcno_file

   gcno_file="$(find "${objroot}" -name "*.gcno" -print -quit 2>/dev/null)"
   if [ -z "${gcno_file}" ]
   then
      log_verbose "No .gcno files found, using default gcov"
      RVAL="gcov"
      return 0
   fi

   #
   # bytes 4-7 of .gcno are the version e.g. 2a 31 31 42 = "*11B"
   # the two middle bytes (5-6) are the GCC major version as ASCII digits
   #
   local gcno_version

   gcno_version="$(dd if="${gcno_file}" bs=1 skip=5 count=2 2>/dev/null)"
   if [ -z "${gcno_version}" ]
   then
      RVAL="gcov"
      return 0
   fi

   # check if default gcov already matches
   local default_version

   default_version="$(gcov --version 2>/dev/null | sed -n 's/^gcov.* \([0-9][0-9]*\)\..*/\1/p')"
   if [ "${default_version}" = "${gcno_version}" ]
   then
      log_verbose "Default gcov (${default_version}) matches .gcno format"
      RVAL="gcov"
      return 0
   fi

   # try gcov-<version>
   if command -v "gcov-${gcno_version}" > /dev/null 2>&1
   then
      log_verbose "Using gcov-${gcno_version} to match .gcno format (default gcov is ${default_version:-unknown})"
      RVAL="gcov-${gcno_version}"
      return 0
   fi

   log_warning "gcov format is GCC ${gcno_version} but only gcov ${default_version:-unknown} is available (gcov-${gcno_version} not found)"
   RVAL="gcov"
   return 0
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

   # For llvm-cov and mulle-cov, try versioned variants if unversioned not found
   local tool="$1"
   if ! exe="`command -v "${tool}"`"
   then
      case "${tool}" in
         mulle-cov|llvm-cov)
            local _v
            for _v in 18 17 16 15 14
            do
               if exe="`command -v "llvm-cov-${_v}"`"
               then
                  break
               fi
               exe=''
            done
         ;;
      esac
      if [ -z "${exe}" ]
      then
         fail "coverage tool \"${tool}\" is not in PATH"
      fi
   fi
   shift

   r_extensionless_basename "${exe}"
   exename="${RVAL}"
   # strip version suffix and normalize for case matching
   case "${exename}" in
      llvm-cov-*)
         exename="llvm-cov"
      ;;
      mulle-cov)
         exename="llvm-cov"
      ;;
   esac

   local OBJROOT
   local SRCROOT
   local OBJFLATROOT

   OBJROOT="`rexekutor mulle-craft ${MULLE_TECHNICAL_FLAGS} craftorder-kitchen-dir "${TEST_PROJECT_NAME:-${PROJECT_NAME}}"`" \
   || fail "could not find object files for ${TEST_PROJECT_NAME:-${PROJECT_NAME}}"
   # remove cruft that will give us warnings
   exekutor find "${OBJROOT}" -name "*CMakeCCompilerId.gcno" -exec rm {} \;
   SRCROOT="`( cd .. ; mulle-sde source-dir)`"

   log_setting "exe     : ${exe}"
   log_setting "exename : ${exename}"
   log_setting "OBJROOT : ${OBJROOT}"
   log_setting "SRCROOT : ${SRCROOT}"

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

         local gcov_exe

         test::coverage::r_find_matching_gcov "${OBJROOT}"
         gcov_exe="${RVAL}"

         if [ "${gcov_exe}" != "gcov" ]
         then
            log_info "Using ${C_RESET_BOLD}${gcov_exe}${C_INFO} to match .gcno format"
         fi

         exekutor "${exe}" --gcov-executable="${gcov_exe}" \
                           --object-directory="${OBJROOT}" \
                           --root="${SRCROOT}" \
                           ${gcovroptions} \
                           "$@"
         rc=$?

         # rmdir_safer "${OBJFLATROOT}"
         # rmdir_safer "${SRCFLATROOT}"
         return $rc
      ;;

      llvm-cov)
         # Use gcovr with llvm-cov gcov as the gcov executable.
         # llvm-cov gcov understands clang's .gcno/.gcda format.
         local gcovr_exe
         if ! gcovr_exe="`command -v gcovr`"
         then
            fail "gcovr not found in PATH (needed for llvm-cov mode)"
         fi

         local gcovroptions
         if gcovroptions="`grep -E -v '^#' .gcovr-options 2> /dev/null`"
         then
            log_verbose "Using options ${C_RESET_BOLD}${gcovroptions}${C_VERBOSE} found in ${C_RESET_BOLD}.gcovr-options"
         fi

         exekutor "${gcovr_exe}" --gcov-executable="${exe} gcov" \
                                 --object-directory="${OBJROOT}" \
                                 --root="${SRCROOT}" \
                                 ${gcovroptions} \
                                 "$@"
         return $?
      ;;

      gcov)
         test::coverage::r_find_matching_gcov "${OBJROOT}"
         exe="${RVAL}"

         test::coverage::r_gcov_prepare_objects "${OBJROOT}"
         OBJFLATROOT="${RVAL}"

         test::coverage::find_source_files "${SRCROOT}" -print0 \
         | exekutor xargs -0 "${exe}" --object-directory "${OBJFLATROOT}" "$@"
         rc=$?

         rmdir_safer "${OBJFLATROOT}"
         return $rc
      ;;

      *)
         test::coverage::r_gcov_prepare_objects "${OBJROOT}"
         OBJFLATROOT="${RVAL}"
         export OBJFLATROOT
         export OBJROOT
         export SRCROOT
         exekutor "${exe}" "$@"
         rc=$?
         rmdir_safer "${OBJFLATROOT}"
         return $rc
      ;;
   esac
}

