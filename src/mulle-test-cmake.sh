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
MULLE_TEST_CMAKE_SH="included"


eval_mulle_make()
{
   log_entry "eval_mulle_make" "$@"

   local build_type="$1"; shift

   # fix for mingw, which demangles the first -I path
   # but not subsequent ones
   #
   # (where is this fix ?)
   #
   local cmake_c_flags
   r_emit_include_cflags
   cmake_c_flags="${RVAL}"

   r_concat "${cmake_c_flags}" "${OTHER_CFLAGS}"
   cmake_c_flags="${RVAL}"

   r_concat "${cmake_c_flags}" "-DMULLE_TEST=1"
   cmake_c_flags="${RVAL}"

   local cmake_libraries

   cmake_libraries="${LINK_COMMAND}"

   # TODO: build commandline nicer (definitions need MULLE_HOSTNAME check)
   # MEMO: unfortunately on linux, the order of linkage matters, but
   #       the CMAKE_EXE_LINKER_FLAGS are prepended to our .o files (bummer)

   eval_exekutor CC="${CC}" \
                 CXX="${CXX}" \
                 ${MULLE_MAKE:-mulle-make} \
                    "${MULLE_TECHNICAL_FLAGS}" \
                    "${MULLE_MAKE_FLAGS}" \
                 build --clean \
                    --info-dir "'${MULLE_VIRTUAL_ROOT}/.mulle/etc/craft/definition'" \
                    "${cmake_definitions}" \
                    -DCMAKE_BUILD_TYPE="'${build_type}'" \
                    -DCMAKE_RULE_MESSAGES="'OFF'" \
                    -DCMAKE_C_FLAGS="'${cmake_c_flags}'" \
                    -DCMAKE_CXX_FLAGS="'${cmake_c_flags}'" \
                    -DCMAKE_EXE_LINKER_FLAGS="'${RPATH_FLAGS}'" \
                    -DTEST_LIBRARIES="'${cmake_libraries} ${RPATH_FLAGS}'" \
                    "$@"

}


# do not exit
fail_test_cmake()
{
   log_entry "fail_test_cmake" "$@"

   local sourcefile="$1"; shift
   local a_out_ext="$1"; shift
   local ext="$1"; shift
   local name="$1"; shift

   [ -z "${srcfile}" ] && internal_fail "srcfile is empty"
   [ -z "${a_out_ext}" ] && internal_fail "a_out_ext is empty"

   if [ "${MULLE_FLAG_MAGNUM_FORCE}" = 'YES' ]
   then
      return
   fi

   #hacque
   local executable
   r_fast_basename "${a_out_ext}"
   executable="${RVAL}"

   if [ "${MULLE_TEST_CONFIGURATION}" != "Debug" ]
   then
      log_info "DEBUG: " >&2
      log_info "Rebuilding as \"${executable}\" with -O0 and debug symbols..."

      local directory

      r_fast_dirname "${srcfile}"
      directory="${RVAL}"

      exekutor cd "${directory}" &&
      eval_mulle_make "Debug" "$@" &&
      exekutor cp -p "build/${executable}" "./${executable}.debug"

      suggest_debugger_commandline "${a_out_ext}" "${stdin}"
   fi
}


run_cmake()
{
   log_entry "run_cmake" "$@"

   local srcfile="$1"; shift
   local a_out_ext="$1"; shift
   local errput="$1"; shift # unused

   [ -z "${srcfile}" ] && internal_fail "srcfile is empty"
   [ -z "${a_out_ext}" ] && internal_fail "a_out_ext is empty"

   local directory
   local executable
   r_fast_basename "${a_out_ext}"
   executable="${RVAL}"
   r_fast_dirname "${srcfile}"
   directory="${RVAL}"
   (
      exekutor cd "${directory}"

      eval_mulle_make "${MULLE_TEST_CONFIGURATION}" "$@" &&
      exekutor cp -p "build/${executable}" "./${executable}"
   ) || exit 1
}




