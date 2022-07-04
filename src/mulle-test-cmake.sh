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


test::cmake::r_add_cmakeflag()
{
   local cmd="$1"
   local flag="$2"
   local value="$3"

   r_escaped_shell_string "${value}"
   r_concat "${cmd}" "-D${flag}=${RVAL}"
}


test::cmake::r_add_flag()
{
   local cmd="$1"
   local flag="$2"
   local value="$3"

   r_escaped_shell_string "${value}"
   r_concat "${cmd}" "${flag} ${RVAL}"
}


test::cmake::r_add()
{
   local cmd="$1"
   local value="$2"

   if [ -z "${value}" ]
   then
      RVAL="${cmd}"
      return
   fi

   r_escaped_shell_string "${value}"
   r_concat "${cmd}" "${RVAL}"
}


test::cmake::r_convert_to_list()
{
   local s
   local o
   local c

   s="$1"
   while [ ! -z "$s" ]
   do 
      c="${s:0:1}"
      s="${s:1}"

      case "${c}" in 
         \"|\')
            if [ -z "${mode}" ]
            then
               mode="$c"
            else
               if [ "${mode}" = "${c}" ]
               then
                  mode=""
               fi
            fi
         ;;

         \\)
            case "${s:0:1}" in
               \"|\')
                  c="\\${s:0:1}"
                  s="${s:1}"
               ;;

               *)
                  c="\\\\" # hack
               ;;
            esac
         ;;

         ' ')
            if [ -z "${mode}" ]
            then
               c="\\;"
            fi
         ;;
      esac   
      o="$o$c"
   done

   RVAL="${o}"
}


test::cmake::eval_mulle_make()
{
   log_entry "test::cmake::eval_mulle_make" "$@"

   local build_type="$1"; shift

   # fix for mingw, which demangles the first -I path
   # but not subsequent ones
   #
   # (where is this fix ?)
   #
   local cmake_c_flags

   # dem flags are already quoted
   test::flagbuilder::r_include_cflags ""
   cmake_c_flags="${RVAL}"

   r_concat "${cmake_c_flags}" "${OTHER_CFLAGS}"
   cmake_c_flags="${RVAL}"

   r_concat "${cmake_c_flags}" "-DMULLE_TEST=1"
   cmake_c_flags="${RVAL}"

   r_concat "${cmake_c_flags}" "-DMULLE_INCLUDE_DYNAMIC=1"
   cmake_c_flags="${RVAL}"

   # add sanitizer flags
   if test::compiler::r_c_sanitizer_flags "${SANITIZER}"
   then
      cmake_c_flags="${cmake_c_flags} ${RVAL}"
   fi

   local cmake_exe_linker_flags

   cmake_exe_linker_flags="${RPATH_FLAGS}"

   # add sanitizer flags
   if test::compiler::r_ld_sanitizer_flags "${SANITIZER}"
   then
      cmake_exe_linker_flags="${cmake_exe_linker_flags} ${RVAL}"
   fi

   local cmake_shared_linker_flags

   cmake_shared_linker_flags="${RPATH_FLAGS}"

   # experimental not really sure if this is useful
   # case "${MULLE_UNAME}" in
   #    darwin)
   #       cmake_shared_linker_flags="${cmake_shared_linker_flags} -exported_symbol __mulle_atinit"
   #       cmake_shared_linker_flags="${cmake_shared_linker_flags} -exported_symbol _mulle_atexit"
   #       cmake_shared_linker_flags="${cmake_shared_linker_flags} -exported_symbol __register_mulle_objc_universe"
   #       cmake_shared_linker_flags="${cmake_shared_linker_flags} -exported_symbol ___register_mulle_objc_universe"
   #    ;;
   # esac

   # TODO: build commandline nicer (definitions need MULLE_HOSTNAME check)
   # MEMO: unfortunately on linux, the order of linkage matters, but
   #       the CMAKE_EXE_LINKER_FLAGS are prepended to our .o files (bummer)

   local environment
   local cmd

   environment="CC='${CC}' CXX='${CXX}' MULLE_TEST_ENVIRONMENT="

   cmd="'${MULLE_MAKE:-mulle-make}'"
   r_concat "${cmd}" "${MULLE_TECHNICAL_FLAGS}"
   cmd="${RVAL}"
   r_concat "${cmd}" "build"
   cmd="${RVAL}"
   r_concat "${cmd}" "--clean"
   cmd="${RVAL}"

#  case "${build_type}" in
#     Test)
#        build_type="Debug"
#     ;;
#  esac

   test::cmake::r_add_flag "${cmd}" "--configuration" "${build_type}"
   cmd="${RVAL}"
   test::cmake::r_add_flag "${cmd}" "--build-dir" "${TEST_KITCHEN_DIR:-kitchen}"
   cmd="${RVAL}"
   test::cmake::r_add_flag "${cmd}" "--info-dir" "${MULLE_VIRTUAL_ROOT}/.mulle/etc/craft/definition"
   cmd="${RVAL}"
   test::cmake::r_add_cmakeflag "${cmd}" "CMAKE_RULE_MESSAGES" "OFF"
   cmd="${RVAL}"

   test::cmake::r_add_cmakeflag "${cmd}" "CMAKE_C_FLAGS" "${cmake_c_flags}"
   cmd="${RVAL}"
   test::cmake::r_add_cmakeflag "${cmd}" "CMAKE_CXX_FLAGS" "${cmake_c_flags}"
   cmd="${RVAL}"
   test::cmake::r_add_cmakeflag "${cmd}" "CMAKE_EXE_LINKER_FLAGS" "${cmake_exe_linker_flags}"
   cmd="${RVAL}"
   test::cmake::r_add_cmakeflag "${cmd}" "CMAKE_SHARED_LINKER_FLAGS" "${cmake_shared_linker_flags}"
   cmd="${RVAL}"

   local cmake_libraries

   cmake_libraries="${LINK_COMMAND}"
   test::cmake::r_convert_to_list "${cmake_libraries}"
   cmake_libraries="${RVAL}"

   # already escaped
   r_concat "${cmd}" "-DTEST_LIBRARIES=${cmake_libraries} ${RPATH_FLAGS}"
   cmd="${RVAL}"

   local argv
   local arg
   local quote

   quote="'"
   argv=
   for arg in "$@"
   do
      arg="${arg//${quote}/${quote}\"${quote}\"${quote}}"
      argv="$argv '$arg'"
   done

   local old_MULLE_FLAG_LOG_EXEKUTOR

   old_MULLE_FLAG_LOG_EXEKUTOR="${MULLE_FLAG_LOG_EXEKUTOR}"
   if [ "${MULLE_FLAG_LOG_VERBOSE}" = 'YES' ]
   then
      MULLE_FLAG_LOG_EXEKUTOR="YES"
   fi

   local rval

   eval_exekutor "${environment}" "${cmd}" "${argv}"
   rval=$?

   MULLE_FLAG_LOG_EXEKUTOR="${old_MULLE_FLAG_LOG_EXEKUTOR}"

   return $rval
}


# do not exit
test::cmake::fail_test()
{
   log_entry "test::cmake::fail_test" "$@"

   local srcfile="$1"; shift
   local a_out="$1"; shift
   local ext="$1"; shift
   local name="$1"; shift

   [ -z "${srcfile}" ] && _internal_fail "srcfile is empty"
   [ -z "${a_out}" ] && _internal_fail "a_out is empty"

   if [ "${MULLE_FLAG_MAGNUM_FORCE}" != 'NO' ]
   then
      return
   fi

   local is_exe='NO'

   if egrep -s -q '^[Aa][Dd][Dd]_[Ee][Xx][Ee][Cc][Uu][Tt][Aa][Bb][Ll][Ee]\(' "CMakeLists.txt"
   then
      is_exe='YES'
   fi

   #hacque
   local shlib
   local produced
   local final

   r_extensionless_basename "${a_out}"
   r_extensionless_basename "${RVAL}"

   if [ "${is_exe}" = 'YES' ]
   then
      produced="${RVAL}.exe"
      final="${RVAL}.debug.exe"
   else
      produced="lib${RVAL}${SHAREDLIB_EXTENSION}"
      final="lib${RVAL}.debug${SHAREDLIB_EXTENSION}"
   fi

   log_info "DEBUG: " >&2
   log_info "Rebuilding \"${final}\" with -O0 and debug symbols..."

   local directory

   r_dirname "${srcfile}"
   directory="${RVAL}"

   (
      exekutor cd "${directory}" &&
      test::cmake::eval_mulle_make "Debug" "$@" &&
      exekutor cp -p "${TEST_KITCHEN_DIR:-kitchen}/${produced}" "./${final}"
   )

   test::compiler::suggest_debugger_commandline "${final}" "${stdin}" "${is_exe}"
}


test::cmake::run()
{
   log_entry "test::cmake::run" "$@"

   local srcfile="$1"; shift
   local a_out_ext="$1"; shift
   local errput="$1"; shift # unused

   [ -z "${srcfile}" ] && _internal_fail "srcfile is empty"
   [ -z "${a_out_ext}" ] && _internal_fail "a_out_ext is empty"
   [ ! -f "CMakeLists.txt" ] && _internal_fail "CMakeLists.txt is missing (${PWD#${MULLE_USER_PWD}/})"

   local is_exe='NO'

   if egrep -s -q '^[Aa][Dd][Dd]_[Ee][Xx][Ee][Cc][Uu][Tt][Aa][Bb][Ll][Ee]\(' "CMakeLists.txt"
   then
      is_exe='YES'
   fi

   local directory
   local executable
   local shlib

   r_basename "${a_out_ext}"
   executable="${RVAL}"

   r_extensionless_basename "${a_out_ext}"
   shlib="lib${RVAL}${SHAREDLIB_EXTENSION}"

   r_dirname "${srcfile}"
   directory="${RVAL}"
   (
      rexekutor cd "${directory}"

      test::cmake::eval_mulle_make "Test" "$@" || exit 1

      #
      # check if it produces a shlib or an exe
      #
      if [ "${is_exe}" = 'YES' ]
      then
         exekutor cp -p "${TEST_KITCHEN_DIR:-kitchen}/${executable}" "./${executable}"
      else
         exekutor cp -p "${TEST_KITCHEN_DIR:-kitchen}/${shlib}" "./${shlib}"
      fi
   ) || exit 1
}

