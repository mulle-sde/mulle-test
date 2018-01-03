#!/usr/bin/env bash
#  run-test.sh
#  MulleObjC
#
#  Created by Nat! on 01.11.13.
#  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
#  (was run-mulle-scion-test)

set -m # job control enable

#
# this is system wide, not so great
# and also not trapped...
#
suppress_crashdumping()
{
   local restore

   case "${UNAME}" in
      darwin)
         restore="`defaults read com.apple.CrashReporter DialogType 2> /dev/null`"
         defaults write com.apple.CrashReporter DialogType none
         ;;
   esac

   echo "${restore}"
}


restore_crashdumping()
{
   local restore

   restore="$1"

   case "${UNAME}" in
      darwin)
         if [ -z "${restore}" ]
         then
            defaults delete com.apple.CrashReporter DialogType
         else
            defaults write com.apple.CrashReporter DialogType "${restore}"
         fi
         ;;
   esac
}


trace_ignore()
{
   restore_crashdumping "$1"
   return 0
}


#
#
#
maybe_show_diagnostics()
{
   local errput="$1"

   local contents

   contents="`head -2 "${errput}"`" 2> /dev/null
   if [ ! -z "${contents}" ]
   then
      log_info "DIAGNOSTICS:" >&2
      cat "${errput}" >&2
   fi
}


maybe_show_output()
{
   local output

   output="$1"

   local contents
   contents="`head -2 "${output}"`" 2> /dev/null
   if [ "${contents}" != "" ]
   then
      log_info "OUTPUT:"
      cat  "${output}"
   fi
}


search_for_strings()
{
   local errput
   local strings
   local banner

   banner="$1"
   errput="$2"
   strings="$3"

   local fail
   local expect
   local match
   local escaped

   fail=0
   while read expect
   do
      if [ ! -z "$expect" ]
      then
         match=`exekutor fgrep -s "${escaped}" "${errput}"`
         if [ -z "$match" ]
         then
            if [ $fail -eq 0 ]
            then
               log_error "${banner}" >&2
               fail=1
            fi
            echo "   $expect" >&2
         fi
      fi
   done < "$strings"

   return $fail
}

#
# more specialized exekutors
#
#
# also redirects error to output (for tests)
#
err_redirect_eval_exekutor()
{
   local output

   output="$1"
   shift

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" = "YES" -o "${MULLE_FLAG_LOG_EXEKUTOR}" = "YES" ]
   then
      if [ -z "${MULLE_EXEKUTOR_LOG_DEVICE}" ]
      then
         echo "==>" "$@" ">" "${output}" >&2
      else
         echo "==>" "$@" ">" "${output}" > "${MULLE_EXEKUTOR_LOG_DEVICE}"
      fi
   fi

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" != "YES" ]
   then
      local rval

      eval "$@" > "${output}" 2>&1
      rval=$?

      if [ "${MULLE_FLAG_LOG_EXEKUTOR}" = "YES" ]
      then
         cat "${output}" >&2 # get stderr mixed in :/
      fi

      return $rval
   fi
}


redirect_eval_exekutor()
{
   local output

   output="$1"
   shift

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" = "YES" -o "${MULLE_FLAG_LOG_EXEKUTOR}" = "YES" ]
   then
      if [ -z "${MULLE_EXEKUTOR_LOG_DEVICE}" ]
      then
         echo "==>" "$@" ">" "${output}" >&2
      else
         echo "==>" "$@" ">" "${output}" > "${MULLE_EXEKUTOR_LOG_DEVICE}"
      fi
   fi

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" != "YES" ]
   then
      eval "$@" > "${output}"
   fi
}


full_redirekt_eval_exekutor()
{
   local stdin
   local stdout
   local stderr

   stdin="$1"
   shift
   stdout="$1"
   shift
   stderr="$1"
   shift

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" = "YES" -o "${MULLE_FLAG_LOG_EXEKUTOR}" = "YES" ]
   then
      if [ -z "${MULLE_EXEKUTOR_LOG_DEVICE}" ]
      then
         echo "==>" "$@" "<" "${stdin}" ">" "${stdout}" "2>" "${stderr}" >&2
      else
         echo "==>" "$@" "<" "${stdin}" ">" "${stdout}" "2>" "${stderr}" > "${MULLE_EXEKUTOR_LOG_DEVICE}"
      fi
   fi

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" != "YES" ]
   then
      local rval

      eval "$@" < "${stdin}" > "${stdout}" 2> "${stderr}"
      rval=$?

      if [ "${MULLE_FLAG_LOG_EXEKUTOR}" = "YES" ]
      then
         cat "${stderr}" >&2
      fi

      return $rval
   fi
}


suggest_debugger_commandline()
{
   local a_out_ext
   local stdin

   a_out_ext="$1"
   stdin="$2"

   case "${UNAME}" in
      darwin)
         echo "MULLE_OBJC_AUTORELEASEPOOL_TRACE=15 \
MULLE_OBJC_TEST_ALLOCATOR=1 \
MULLE_TEST_ALLOCATOR_TRACE=2 \
MULLE_OBJC_TRACE_ENABLED=YES \
MULLE_OBJC_WARN_ENABLED=YES \
DYLD_INSERT_LIBRARIES=/usr/lib/libgmalloc.dylib \
${DEBUGGER} ${a_out_ext}" >&2
         if [ "${stdin}" != "/dev/null" ]
         then
            echo "run < ${stdin}" >&2
         fi
      ;;

      linux)
         echo "MULLE_OBJC_AUTORELEASEPOOL_TRACE=15 \
MULLE_OBJC_TEST_ALLOCATOR=1 \
MULLE_TEST_ALLOCATOR_TRACE=2 \
MULLE_OBJC_TRACE_ENABLED=YES \
MULLE_OBJC_WARN_ENABLED=YES \
LD_LIBRARY_PATH=\"${LD_LIBRARY_PATH}\" \
${DEBUGGER} ${a_out_ext}" >&2
         if [ "${stdin}" != "/dev/null" ]
         then
            echo "run < ${stdin}" >&2
         fi
     ;;
   esac
}


emit_include_cflags()
{
   local quote="$1"
   local cflags

   if [ ! -z "${LIBRARY_INCLUDE}" ]
   then
      cflags="-I${quote}${LIBRARY_INCLUDE}${quote}"
   fi

   if [ ! -z "${DEPENDENCIES_INCLUDE}" ]
   then
      if [ -z "${cflags}" ]
      then
         cflags="-I${quote}${DEPENDENCIES_INCLUDE}${quote}"
      else
         cflags="${cflags} -I${quote}${DEPENDENCIES_INCLUDE}${quote}"
      fi
   fi

   if [ ! -z "${ADDICTIONS_INCLUDE}" ]
   then
      if [ -z "${cflags}" ]
      then
         cflags="-I${quote}${ADDICTIONS_INCLUDE}${quote}"
      else
         cflags="${cflags} -I${quote}${ADDICTIONS_INCLUDE}${quote}"
      fi
   fi

   if [ ! -z "${cflags}" ]
   then
      echo "${cflags}"
   fi
}


emit_cflags()
{
   local srcfile="$1"

   local cflagsname
   local cflags

   cflags="${CFLAGS}"
   cflagsname="`echo "${srcfile}" | sed 's/\.[^.]*$//'`.CFLAGS"

   if [ -f "${cflagsname}.${UNAME}" ]
   then
      cflags="`cat "${cflagsname}.${UNAME}"`"
      log_fluff "Got CFLAGS=\"${cflags}\" from \"${cflagsname}.${UNAME}\""
   else
      if [ -f "${cflagsname}" ]
      then
         cflags="`cat "${cflagsname}"`"
         log_fluff "Got CFLAGS=\"${cflags}\" from \"${cflagsname}\""
      fi
   fi


   echo "${cflags}"
}


emit_libraries()
{
   local s

   while [ $# -ne 0 ]
   do
      if [ -z "${s}" ]
      then
         s="$1"
      else
         s="${s};$1"
      fi
      shift
   done

   if [ ! -z "${s}" ]
   then
      echo "${s}"
   fi
}


eval_cmake()
{
   # fix for mingw, which demangles the first -I path
   # but not subsequent ones
   #
   # (where is this fix ?)
   #
   local cmake_c_flags

   cmake_c_flags="`emit_include_cflags`"

   local cmake_libraries

   cmake_libraries="`emit_libraries "${LIBRARY_PATH}" ${ADDITIONAL_LIBRARY_PATHS}`"

   eval_exekutor "'${CMAKE}'" \
      -G "'${CMAKE_GENERATOR}'" \
      -DCMAKE_BUILD_TYPE="'$1'" \
      -DCMAKE_RULE_MESSAGES="OFF" \
      -DDEPENDENCIES_DIR="${DEPENDENCIES_DIR}" \
      -DADDICTIONS_DIR="${ADDICTIONS_DIR}" \
      -DCMAKE_C_COMPILER="'${CC}'" \
      -DCMAKE_CXX_COMPILER="'${CXX}'" \
      -DCMAKE_C_FLAGS="'${cmake_c_flags}'" \
      -DCMAKE_CXX_FLAGS="'${cmake_c_flags}'" \
      -DTEST_LIBRARIES="'${cmake_libraries}'" \
      -DCMAKE_EXE_LINKER_FLAGS="'${RPATH_FLAGS}'" \
      ..
}


fail_test_cmake()
{
   local sourcefile
   local a_out
   local stdin
   local ext

   sourcefile="$1"
   a_out_ext="$2"
   stdin="$3"
   ext="$4"

   #hacque
   local a_paths

   a_paths="`/bin/echo -n "${ADDITIONAL_LIBRARY_PATHS}" | tr '\012' ' '`"

   if [ -z "${MULLE_TEST_IGNORE_FAILURE}" ]
   then
      if [ "${BUILD_TYPE}" != "Debug" ]
      then
         log_info "DEBUG: " >&2
         log_info "Rebuilding as `basename -- ${a_out_ext}` with -O0 and debug symbols..."

         local directory

         directory="`dirname -- "${srcfile}"`"

         exekutor cd "${directory}"

         rmdir_safer "build.debug"
         mkdir_if_missing  "build.debug"
         exekutor cd "build.debug"

         eval_cmake "Debug"

         eval_exekutor ${MAKE} ${MAKEFLAGS}

         suggest_debugger_commandline "${a_out_ext}" "${stdin}"
      fi

      exit 1
   fi
}


run_cmake()
{
   local srcfile="$1"
   local owd="$2"
   local a_out_ext="$3"

   local directory

   directory="`dirname -- "${srcfile}"`"
   (
      exekutor cd "${directory}"
      rmdir_safer "build" &&
      mkdir_if_missing  "build" &&
      exekutor cd "build" &&

      eval_cmake "${BUILD_TYPE}" &&

      eval_exekutor "'${MAKE}'" ${MAKEFLAGS} &&

      exekutor install "`basename -- "${a_out_ext}"`" ..
   )
}


fail_test_c()
{
   local sourcefile="$1"
   local a_out_ext="$2"
   local stdin="$3"
   local ext="$4"

   if [ -z "${MULLE_TEST_IGNORE_FAILURE}" ]
   then
      return
   fi

   if [ "${BUILD_TYPE}" != "Debug" ]
   then
      local a_paths

      a_paths="`/bin/echo -n "${ADDITIONAL_LIBRARY_PATHS}" | tr '\012' ' '`"

      local cflags
      local incflags

      cflags="`emit_cflags "${sourcefile}"`"
      incflags="`emit_include_cflags "'"`"

      log_info "DEBUG: "
      log_info "rebuilding as `basename -- ${a_out_ext}` with -O0 and debug symbols..."

      eval_exekutor "'${CC}'" \
                    "${DEBUG_CFLAGS}"
                    -o "'${a_out_ext}'" \
                    "${cflags}" \
                    "${incflags}" \
                    "'${sourcefile}'" \
                    "'${LIBRARY_PATH}'" \
                    "${a_paths}" \
                    "${LDFLAGS}" \
                    "${RPATH_FLAGS}"

      suggest_debugger_commandline "${a_out_ext}" "${stdin}"
   fi

   exit 1
}


run_gcc_compiler()
{
   local srcfile="$1"
   local owd="$2"
   local a_out_ext="$3"
   local errput="$4"

   #hacque
   local a_paths

   a_paths="`/bin/echo -n "${ADDITIONAL_LIBRARY_PATHS}" | tr '\012' ' '`"

   local cflags
   local incflags

   cflags="`emit_cflags "${srcfile}"`"
   incflags="`emit_include_cflags "'"`"

   err_redirect_eval_exekutor "${errput}" "'${CC}'" \
                                          "${cflags}" \
                                          "${incflags}" \
                                          -o "'${a_out_ext}'" \
                                          "'${srcfile}'" \
                                          "'${LIBRARY_PATH}'" \
                                          "${a_paths}" \
                                          "${LDFLAGS}" \
                                          "${RPATH_FLAGS}"
}


run_compiler()
{
   case "${CC}" in
      cl|cl.exe|*-cl|*-cl.exe)
         run_gcc_compiler "$@"  #mingw magic
      ;;

      *)
         run_gcc_compiler "$@"
      ;;
   esac
}


run_a_out()
{
   local input="$1"
   local output="$2"
   local errput="$3"
   local a_out_ext="$4"

   if [ ! -x "${a_out_ext}" ]
   then
      log_error "Compiler unexpectedly did not produce ${a_out_ext}"
      return 1
   fi

   if [ "${MULLE_FLAG_LOG_EXEKUTOR}" = "YES" ]
   then
      echo "Environment:" >&2
      env | sort >&2
   fi

   case "${UNAME}" in
      darwin)
         full_redirekt_eval_exekutor "${input}" "${output}" "${errput}" MULLE_OBJC_TEST_ALLOCATOR=1 \
         "${a_out_ext}"
      ;;

      *)
         full_redirekt_eval_exekutor "${input}" "${output}" "${errput}" MULLE_OBJC_TEST_ALLOCATOR=1 "${a_out_ext}"
      ;;
   esac
}


check_compiler_output()
{
   local ccdiag="$1"
   local errput="$2"
   local rval="$3"
   local pretty_source="$4"

   if [ "${rval}" -eq 0 ]
   then
      return 0
   fi

   if [ "${ccdiag}" = "-" ]
   then
      log_error "COMPILER ERRORS: \"${TEST_PATH_PREFIX}${pretty_source}\""
   else
      search_for_strings "COMPILER FAILED TO PRODUCE ERRORS: \"${TEST_PATH_PREFIX}${pretty_source}\" (${errput})" \
                         "${errput}" "${ccdiag}"
      if [ $? -eq 0 ]
      then
         return 3
      fi
   fi

   FAILS=`expr "$FAILS" + 1`

   maybe_show_diagnostics "${errput}"
   if [ -z "${MULLE_TEST_IGNORE_FAILURE}" ]
   then
      exit 1
   fi
   return 1
}


_check_test_output()
{
   local stdout="$1" # test provided
   local stderr="$2"
   local errors="$3"
   local output="$4" # test output
   local errput="$5"
   local rval="$6"
   local pretty_source="$7"  # environment
   local a_out_ext="$8"
   local ext="$9"

   if [ ${rval} -ne 0 ]
   then
      if [ ! -f "${errors}" ]
      then
         log_error "TEST CRASHED: \"${TEST_PATH_PREFIX}${pretty_source}\" (${TEST_PATH_PREFIX}${a_out_ext}, ${errput})"
         return 1
      fi

      search_for_strings "TEST FAILED TO PRODUCE ERRORS: \"${TEST_PATH_PREFIX}${pretty_source}\" (${errput})" \
                         "${errput}" "${errors}"
      return $?
   fi

   if [ -f "${errors}" ]
   then
      log_error "TEST FAILED TO CRASH: \"${TEST_PATH_PREFIX}${pretty_source}\" (${TEST_PATH_PREFIX}${a_out_ext})"
      return 1
   fi

   if [ "${stdout}" != "-" ]
   then
      local result

      result=`exekutor diff -q "${stdout}" "${output}"`
      if [ "${result}" != "" ]
      then
         white=`exekutor diff -q -w "${stdout}" "${output}"`
         if [ "$white" != "" ]
         then
            log_error "FAILED: \"${TEST_PATH_PREFIX}${pretty_source}\" produced unexpected output"
            log_info  "DIFF: (${output} vs. ${stdout})"
            exekutor diff -y "${output}" "${stdout}" >&2
         else
            log_error "FAILED: \"${TEST_PATH_PREFIX}${pretty_source}\" produced different whitespace output"
            log_info  "DIFF: (${TEST_PATH_PREFIX}${stdout} vs. ${output})"
            redirect_exekutor "${output}.actual.hex" od -a "${output}"
            redirect_exekutor "${output}.expect.hex" od -a "${stdout}"
            exekutor diff -y "${output}.expect.hex" "${output}.actual.hex" >&2
         fi

         return 2
      fi
   else
      local contents

      contents="`exekutor head -2 "${output}"`" 2> /dev/null
      if [ "${contents}" != "" ]
      then
         log_warning "WARNING: \"${TEST_PATH_PREFIX}${pretty_source}\" produced unexpected output (${output})" >&2
         return 2
      fi
   fi

   if [ "${stderr}" != "-" ]
   then
      result=`exekutor diff "${stderr}" "${errput}"`
      if [ "${result}" != "" ]
      then
         log_warning "WARNING: \"${TEST_PATH_PREFIX}${pretty_source}\" produced unexpected diagnostics (${errput})" >&2
         exekutor echo "" >&2
         exekutor diff "${stderr}" "${errput}" >&2
         return 1
      fi
   fi
}


check_test_output()
{
   local errput
   local output

   output="$4"
   errput="$5"

   local rval

   _check_test_output "$@"
   rval=$?

   if [ $rval -ne 0 ]
   then
      FAILS=`expr "$FAILS" + 1`
      maybe_show_diagnostics "${errput}"
   fi

   if [ ${rval} -gt 1 ]
   then
      maybe_show_output "${output}"
   fi

   return $rval
}


#
# this function defines some quasi-global variables
# and does some other stuff, it's hackish but....
#
#    output
#    errput
#    errors
#    owd
#    pretty_source
#
__preamble()
{
   local name="$1"
   local root="$2"
   local sourcefile="$3"

   local random

   RUNS=`expr "$RUNS" + 1`
   random=`mktemp -t "${LIBRARY_SHORTNAME}.XXXX"`
   output="${random}.stdout"
   errput="${random}.stderr"
   cc_errput="${random}.ccerr"
   errors="${name}.errors"

   owd="`pwd -P`"
   pretty_source=`relative_path_between "${owd}"/"${sourcefile}" "${root}"`

   log_info "${TEST_PATH_PREFIX}${pretty_source}"
}


run_common_test()
{
   local a_out="$1"
   local name="$2"
   local root="$3"
   local ext="$4"
   local stdin="$5"
   local stdout="$6"
   local stderr="$7"
   local ccdiag="$8"

   local output
   local cc_errput
   local errput
   local random
   local fail
   local match
   local pretty_source

   local srcfile

   srcfile="${name}${ext}"

   __preamble "${name}" "${root}" "${srcfile}"

   # plz2shutthefuckup bash
   set +m
   set +b
   set +v
   # denied, will always print TRACE/BPT

   local rval
   local a_out_ext

   log_verbose "Build test"

   a_out_ext="${a_out}${EXE_EXTENSION}"

   "${TEST_BUILDER}" "${srcfile}" "${owd}" "${a_out_ext}" "${cc_errput}"
   rval="$?"

   check_compiler_output "${ccdiag}" "${cc_errput}" "${rval}" "${pretty_source}"
   rval="$?"

   case "$rval" in
      0)
      ;;

      3)
         return 0
      ;;

      *)
         return $rval
      ;;
   esac

   log_verbose "Run test"

   run_a_out "${stdin}" "${output}.tmp" "${errput}.tmp" "${a_out_ext}"
   rval=$?

   log_verbose "Check test output"

   redirect_eval_exekutor "${output}" "${CRLFCAT}" "<" "${output}.tmp"
   redirect_eval_exekutor "${errput}" "${CRLFCAT}" "<" "${errput}.tmp"
   exekutor rm "${output}.tmp" "${errput}.tmp"

   check_test_output  "${stdout}" \
                      "${stderr}" \
                      "${errors}" \
                      "${output}" \
                      "${errput}" \
                      "${rval}"   \
                      "${pretty_source}" \
                      "${a_out_ext}" \
                      "${ext}"

   rval=$?
   if [ "${rval}" -ne 0 ]
   then
      a_out_ext="${a_out}${DEBUG_EXE_EXTENSION}"

      "${FAIL_TEST}" "${srcfile}" "${a_out_ext}" "${stdin}" "${ext}"
   fi
   return $rval
}


run_cmake_test()
{
   local name="$1"

   local a_out
   local owd

   owd="`pwd -P`"
   a_out="${owd}/${name}"

   TEST_BUILDER=run_cmake
   FAIL_TEST=fail_test_cmake
   run_common_test "${a_out}" "$@"
}


run_c_test()
{
   local name="$1"
   local ext="$3"

   local a_out
   local owd

   owd="`pwd -P`"
   a_out="${owd}/${name}"

   TEST_BUILDER="run_compiler"
   FAIL_TEST="fail_test_c"
   run_common_test "${a_out}" "$@"
}


run_m_test()
{
   run_c_test "$@"
}


run_cpp_test()
{
   log_error "$1: cpp testing is not available yet"
}


# we are in the test directory
#
# testname: is either the test.m or "" for Makefile
# runtest : is where the user started the search, its only used for printing
# ext     : extension of the file used for tmp filename construction
#
run_test()
{
   local name="$1"
   local root="$2"
   local ext="$3"

   local name

   local stdin
   local stdout
   local stderr

   log_fluff "Looking for test files in $PWD"

   stdin="${name}.stdin"
   if exekutor [ ! -f "${stdin}" ]
   then
      stdin="provide/${name}.stdin"
   fi
   if exekutor [ ! -f "${stdin}" ]
   then
      stdin="default.stdin"
   fi
   if exekutor [ ! -f "${stdin}" ]
   then
      stdin="/dev/null"
   fi

   stdout="${name}.stdout"
   if exekutor [ ! -f "${stdout}" ]
   then
      stdout="expect/${name}.stdout"
   fi
   if exekutor [ ! -f "${stdout}" ]
   then
      stdout="default.stdout"
   fi
   if exekutor [ ! -f "${stdout}" ]
   then
      stdout="-"
   fi

   stderr="${name}.stderr"
   if exekutor [ ! -f "${stderr}" ]
   then
      stderr="expect/${name}.stderr"
   fi
   if exekutor [ ! -f "${stderr}" ]
   then
      stderr="default.stderr"
   fi
   if exekutor [ ! -f "${stderr}" ]
   then
      stderr="-"
   fi

   ccdiag="${name}.ccdiag"
   if exekutor [ ! -f "${ccdiag}" ]
   then
      ccdiag="expect/${name}.ccdiag"
   fi
   if exekutor [ ! -f "${ccdiag}" ]
   then
      ccdiag="default.ccdiag"
   fi
   if exekutor [ ! -f "${ccdiag}" ]
   then
      ccdiag="-"
   fi


   case "${ext}" in
      cmake)
         run_cmake_test "${name}" "${root}" "" "${stdin}" "${stdout}" "${stderr}" "${ccdiag}"
      ;;

      .m|.aam)
         run_m_test "${name}" "${root}" "${ext}" "${stdin}" "${stdout}" "${stderr}" "${ccdiag}"
      ;;

      .c)
         run_c_test "${name}" "${root}" "${ext}" "${stdin}" "${stdout}" "${stderr}" "${ccdiag}"
      ;;

      .cxx|.cpp)
         run_cpp_test "${name}" "${root}" "${ext}" "${stdin}" "${stdout}" "${stderr}" "${ccdiag}"
      ;;
   esac
}


scan_current_directory()
{
   local root="$1"

   local i
   local owd
   local name

   if [ -f CMakeLists.txt ]
   then
      run_test "`basename -- "${PWD}"`" "${root}" "cmake"
      return 0
   fi

   log_fluff "Scanning \"${PWD}\" ..."

   IFS="
"
   for i in `ls -1`
   do
      IFS="${DEFAULT_IFS}"

      case "${i}" in
         _*|build|include|lib|bin|tmp|etc|share|stashes)
         ;;

         *)
            if [ -d "${i}" ]
            then
               owd="`pwd -P`"
               cd "${i}"
                  scan_current_directory "${root}"
               cd "${owd}"
            else
               for ext in ${SOURCE_EXTENSION}
               do
                  name=`basename -- "${i}" "${ext}"`
                  if [ "${name}" != "${i}" ]
                  then
                     run_test "${name}" "${root}" "${ext}"
                     break
                  fi
               done
            fi
         ;;
      esac
   done

   IFS="${DEFAULT_IFS}"
}


assert_binary()
{
   local bin

   bin="`which_binary "$1"`"
   if [ -z "$bin" ]
   then
      fail "$1 can not be found"
   fi
}


locate_path()
{
   local path

   path="$1"

   local found
   found="`ls -1 "${path}" 2> /dev/null | tail -1`"

   if [ ! -z "${MULLE_TEST_TRACE_LOOKUP}" ]
   then
      if [ -z "${found}" ]
      then
         log_fluff "\"${path}\" does not exist"
      else
         log_fluff "Found \"${found}\""
      fi
   fi

   echo "${found}"
}


_locate_library()
{
   local filename

   filename="$1"

   local library_path

   if [ ! -z "${LIB_PATH}" ]
   then
      library_path="`locate_path "${LIB_PATH}/${filename}"`"
   fi
   [ ! -z "${library_path}" ] && echo "${library_path}" && return

   library_path="`locate_path "./lib/${filename}"`"
   [ ! -z "${library_path}" ] && echo "${library_path}" && return

   library_path="`locate_path "../lib/${filename}"`"
   [ ! -z "${library_path}" ] && echo "${library_path}" && return

   library_path="`locate_path "${DEPENDENCIES_DIR}/lib/${filename}"`"
   [ ! -z "${library_path}" ] && echo "${library_path}" && return

   library_path="`locate_path "${ADDICTIONS_DIR}/lib/${filename}"`"
   [ ! -z "${library_path}" ] && echo "${library_path}" && return

   library_path="`locate_path "./build/Products/Debug/${filename}"`"
   [ ! -z "${library_path}" ] && echo "${library_path}" && return

   library_path="`locate_path "../build/Products/Debug/${filename}"`"
   [ ! -z "${library_path}" ] && echo "${library_path}" && return

   echo "${library_path}"
}


locate_library()
{
  local library_path
  local filename

  filename="$1"
  library_path="$2"

   if [ -z "${library_path}" ]
   then
      library_path="`_locate_library "${filename}"`"
   fi

   if [ -z "${library_path}" ]
   then
      log_error "error: ${filename} can not be found."

      log_info "Maybe you have not run \"build-test.sh\" yet ?

You commonly need a shared library target in your CMakeLists.txt that
links in all the platform dependencies for your platform. This library
should be installed into \"./lib\" (and headers into \"./include\").

By convention a \"build-test.sh\" script does this using the
\"CMakeLists.txt\" file of your project."
      exit 1
   fi

   echo "${library_path}"
}


#####################################################################
# main
#
# if you really want to you can also specify the LIB_EXTENSION as
# .a, and then pass in the link dependencies as LDFLAGS. But is i
# easier, than a shared library ?
#
usage()
{
   cat <<EOF >&2
usage:
   run-test.sh [options] [tests]

   You may optionally specify a source test file, to run
   a certain test.

   Options:
         -f  : keep going, if tests fail
         -q  : quiet
         -t  : shell trace
         -v  : verbose
         -V  : show commands
EOF
   exit 1
}


run_named_test()
{
   local directory
   local found
   local filename
   local name
   local old
   local ext

   directory=`dirname -- "$1"`
   filename=`basename -- "$1"`
   found="NO"

   if [ -d "${1}" ]
   then
      cd "${1}"
      scan_current_directory "`pwd -P`"
      return
   fi

   if [ ! -f "${1}" ]
   then
      fail "error: source file \"${TEST_PATH_PREFIX}${1}\" not found"
   fi

   for ext in ${SOURCE_EXTENSION}
   do
      name=`basename -- "${filename}" "${ext}"`

      if [ "${name}" != "${filename}" ]
      then
        found="YES"
        break
      fi
   done

   if [ "${found}" = "NO" ]
   then
      fail "error: source file must have ${SOURCE_EXTENSION} extension"
   fi

   root="`pwd -P`"

   cd "${directory}" || exit 1
   run_test "${name}" "${root}" "${ext}"
   rval=$?

   cd "${root}" || exit 1
   exit ${rval}
}


run_all_tests()
{
   local directory

   directory=${1:-`pwd`}
   [ $# -ne 0 ] && shift

   cd "${directory}"
   scan_current_directory "`pwd -P`"

   if [ "$RUNS" -ne 0 ]
   then
      if [ "${FAILS}" -eq 0 ]
      then
         log_info "All tests ($RUNS) passed successfully" >&2
      else
         log_error "$FAILS tests out of $RUNS failed" >&2
         return 1
      fi
   else
      log_warning "No tests found"
   fi
}


main()
{
   local def_makeflags

   DEFAULT_IFS="${IFS}"

   CFLAGS="${CFLAGS:-${RELEASE_CFLAGS}}"
   BUILD_TYPE="${BUILD_TYPE:-Release}"
   def_makeflags="-s"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -v|--verbose)
            BOOTSTRAP_FLAGS="`concat "${BOOTSTRAP_FLAGS}" "$1"`"
            MULLE_FLAG_LOG_VERBOSE="YES"
         ;;

         -vv)
            BOOTSTRAP_FLAGS="`concat "${BOOTSTRAP_FLAGS}" "$1"`"
            MULLE_FLAG_LOG_FLUFF="YES"
            MULLE_FLAG_LOG_VERBOSE="YES"
            MULLE_FLAG_LOG_EXEKUTOR="YES"
            def_makeflags=""
         ;;

         -vvv)
            BOOTSTRAP_FLAGS="`concat "${BOOTSTRAP_FLAGS}" "$1"`"
            MULLE_TEST_TRACE_LOOKUP="YES"
            MULLE_FLAG_LOG_FLUFF="YES"
            MULLE_FLAG_LOG_VERBOSE="YES"
            MULLE_FLAG_LOG_EXEKUTOR="YES"
            def_makeflags=""
         ;;

         -le|-ld)
         ;;

         -V)
            def_makeflags="VERBOSE=1"
            MULLE_FLAG_LOG_EXEKUTOR="YES"
         ;;

         -n)
            MULLE_FLAG_EXEKUTOR_DRY_RUN="YES"
         ;;

         -f)
            MULLE_TEST_IGNORE_FAILURE="YES"
         ;;

         --debug)
            BUILD_TYPE=Debug
            CFLAGS="${DEBUG_CFLAGS}"
         ;;

         --release)
            BUILD_TYPE=Release
            CFLAGS="${RELEASE_CFLAGS}"
         ;;

         -s|--silent)
            MULLE_FLAG_LOG_TERSE="YES"
         ;;

         -t|--trace)
            set -x
         ;;

         -te|--trace-execution)
            BOOTSTRAP_FLAGS="`concat "${BOOTSTRAP_FLAGS}" "$1"`"
            MULLE_FLAG_LOG_EXEKUTOR="YES"
         ;;

         --path-prefix)
            shift
            [ $# -eq 0 ] && usage

            TEST_PATH_PREFIX="$1"
         ;;

         -*)
            log_verbose "ignored option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   MAKEFLAGS="${MAKEFLAGS:-${def_makeflags}}"

   if [ -z "${DEBUGGER}" ]
   then
      DEBUGGER=lldb
   fi

   DEBUGGER="`which "${DEBUGGER}" 2> /dev/null`"

   if [ -z "${DEBUGGER_LIBRARY_PATH}" ]
   then
      DEBUGGER_LIBRARY_PATH="`dirname -- "${DEBUGGER}"`/../lib"
   fi

   RESTORE_CRASHDUMP=`suppress_crashdumping`
   trap 'trace_ignore "${RESTORE_CRASHDUMP}"' 0 5 6

   [ -z "${LIBRARY_SHORTNAME}" ] && fail "LIBRARY_SHORTNAME not set"

   LIBRARY_FILENAME="${LIB_PREFIX}${LIBRARY_SHORTNAME}${LIB_SUFFIX}${LIB_EXTENSION}"

   DEPENDENCIES_DIR="`mulle-bootstrap paths dependencies`"
   ADDICTIONS_DIR="`mulle-bootstrap paths addictions`"

   if [ ! -z "${DEPENDENCIES_DIR}" ]
   then
      DEPENDENCIES_INCLUDE="${DEPENDENCIES_DIR}/include"
   fi

   if [ ! -z "${ADDICTIONS_DIR}" ]
   then
      ADDICTIONS_INCLUDE="${ADDICTIONS_DIR}/include"
   fi

   LIBRARY_PATH="`locate_library "${LIBRARY_FILENAME}" "${LIBRARY_PATH}"`" || exit 1

   #
   # figure out where the headers are
   #
   LIBRARY_FILENAME="`basename -- "${LIBRARY_PATH}"`"
   LIBRARY_DIR="`dirname -- "${LIBRARY_PATH}"`"
   LIBRARY_ROOT="`dirname -- "${LIBRARY_DIR}"`"

   if [ -d "${LIBRARY_ROOT}/usr/local/include" ]
   then
      LIBRARY_INCLUDE="${LIBRARY_INCLUDE}/usr/local/include"
   else
      LIBRARY_INCLUDE="${LIBRARY_ROOT}/include"
   fi

   LIBRARY_PATH="`absolutepath "${LIBRARY_PATH}"`"
   LIBRARY_INCLUDE="`absolutepath "${LIBRARY_INCLUDE}"`"
   DEPENDENCIES_INCLUDE="`absolutepath "${DEPENDENCIES_INCLUDE}"`"
   ADDICTIONS_INCLUDE="`absolutepath "${ADDICTIONS_INCLUDE}"`"

   LIBRARY_DIR="`dirname -- ${LIBRARY_PATH}`"

   case "${UNAME}" in
      darwin)
         RPATH_FLAGS="-Wl,-rpath ${LIBRARY_DIR}"

         log_verbose "RPATH_FLAGS=${RPATH_FLAGS}"
      ;;

      linux)
         LD_LIBRARY_PATH="${LIBRARY_DIR}:${LD_LIBRARY_PATH}"
         export LD_LIBRARY_PATH

         log_verbose "LD_LIBRARY_PATH=${LD_LIBRARY_PATH}"
      ;;

      mingw*)
         PATH="${LIBRARY_DIR}:${PATH}"
         export PATH

         log_verbose "PATH=${PATH}"
      ;;
   esac


   #
   # read os-specific-libs
   #
   if [ -f "build/os-specific-libs.txt" ]
   then
      IFS=";"
      for path in `cat "build/os-specific-libs.txt"`
      do
         IFS="${DEFAULT_IFS}"

         log_verbose "Additional library: ${path}"
         ADDITIONAL_LIBRARY_PATHS="`concat "${ADDITIONAL_LIBRARY_PATHS}" "${path}"`"
      done
      IFS="${DEFAULT_IFS}"
   else
      log_warning "build/os-specific-libs.txt not found"
   fi

   #
   # manage additional libraries, expected to be in same path
   # as library
   #
   local i
   local path
   local filename

   IFS="
"
   for i in ${ADDITIONAL_LIBS}
   do
      IFS="${DEFAULT_IFS}"

      filename="${LIB_PREFIX}${i}${LIB_SUFFIX}${LIB_EXTENSION}"
      path="`locate_library "${filename}"`" || exit 1
      path="`absolutepath "${path}"`"

      log_verbose "Additional library: ${path}"
      ADDITIONAL_LIBRARY_PATHS="`concat "${ADDITIONAL_LIBRARY_PATHS}" "${path}"`"
   done
   IFS="${DEFAULT_IFS}"

   if [ -z "${CC}" ]
   then
      fail "CC for C compiler not defined"
   fi

   assert_binary "$CC" "CC"

   HAVE_WARNED="NO"
   RUNS=0
   FAILS=0

   if [ "$RUN_ALL" = "YES" -o $# -eq 0 ]
   then
      run_all_tests "$@"
   else
      while [ $# -ne 0 ]
      do
         run_named_test "$1"
         shift
      done
   fi
}

MULLE_EXECUTABLE_PID=$$
main "$@"
