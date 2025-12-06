# shellcheck shell=bash
#
#   Copyright (c) 2024 Nat! - Mulle kybernetiK
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

MULLE_TEST_COMPILER_PLATFORM_SH='included'


#
# Build compiler command line using mulle-platform compiler run
# This replaces the old manual command line construction with a call to
# mulle-platform which handles all platform-specific compiler flags
#
test::compiler::platform::r_c_commandline()
{
   log_entry "test::compiler::platform::r_c_commandline" "$@"

   local c_flags="$1"
   local srcfile="$2"
   local a_out="$3"
   local configuration="$4"
   shift 4

   # Find mulle-platform
   local mulle_platform
   
   mulle_platform="`command -v mulle-platform`"
   if [ -z "${mulle_platform}" ]
   then
      fail "mulle-platform not found in PATH. Please install mulle-platform."
   fi

   # Build mulle-platform compiler run command
   local cmdline
   local extra_flags

   cmdline="${mulle_platform} compiler run"

   # Add platform
   if [ ! -z "${MULLE_UNAME}" ]
   then
      cmdline="${cmdline} --platform ${MULLE_UNAME}"
   fi

   # Add language/dialect
   if [ ! -z "${PROJECT_DIALECT}" ]
   then
      cmdline="${cmdline} --dialect ${PROJECT_DIALECT}"
      
      # Add objc-dialect if applicable
      if [ "${PROJECT_DIALECT}" = "objc" -a ! -z "${MULLE_TEST_OBJC_DIALECT}" ]
      then
         cmdline="${cmdline} --objc-dialect ${MULLE_TEST_OBJC_DIALECT}"
      fi
   fi

   # Add configuration
   if [ ! -z "${configuration}" ]
   then
      cmdline="${cmdline} --configuration ${configuration}"
   fi

   # Add defines
   if [ ! -z "${MULLE_TEST_DEFINES}" ]
   then
      local define

      .foreachline define in ${MULLE_TEST_DEFINES}
      .do
         cmdline="${cmdline} -D${define}"
      .done
   fi

   # Add include paths
   if [ ! -z "${MULLE_TEST_INCLUDE_PATH}" ]
   then
      local include

      .foreachpath include in ${MULLE_TEST_INCLUDE_PATH}
      .do
         cmdline="${cmdline} -I'${include}'"
      .done
   fi

   # Add library paths
   if [ ! -z "${MULLE_TEST_LIBRARY_PATH}" ]
   then
      local library

      .foreachpath library in ${MULLE_TEST_LIBRARY_PATH}
      .do
         cmdline="${cmdline} -L'${library}'"
      .done
   fi

   # Add link libraries
   if [ ! -z "${MULLE_TEST_LINK_LIBRARIES}" ]
   then
      local link_library

      .foreachline link_library in ${MULLE_TEST_LINK_LIBRARIES}
      .do
         cmdline="${cmdline} -l${link_library}"
      .done
   fi

   # Add whole archive libraries
   if [ ! -z "${MULLE_TEST_WHOLE_ARCHIVE_LIBRARIES}" ]
   then
      local whole_archive

      .foreachline whole_archive in ${MULLE_TEST_WHOLE_ARCHIVE_LIBRARIES}
      .do
         cmdline="${cmdline} --wholearchive ${whole_archive}"
      .done
   fi

   # Add frameworks (Darwin)
   if [ ! -z "${MULLE_TEST_FRAMEWORKS}" ]
   then
      local framework

      .foreachline framework in ${MULLE_TEST_FRAMEWORKS}
      .do
         cmdline="${cmdline} -framework ${framework}"
      .done
   fi

   # Handle sanitizer flags
   if [ ! -z "${MULLE_TEST_SANITIZER}" ]
   then
      # Check if we should skip sanitizer (bootstrap on darwin)
      local skip_sanitizer='NO'
      
      if [ "${MULLE_TEST_ENVIRONMENT}" = "bootstrap" -a "${MULLE_UNAME}" = "darwin" ]
      then
         log_verbose "Sanitizer disabled in bootstrap environment on darwin"
         skip_sanitizer='YES'
      fi

      if [ "${skip_sanitizer}" != 'YES' ]
      then
         r_concat "${extra_flags}" "-fsanitize=${MULLE_TEST_SANITIZER}"
         extra_flags="${RVAL}"
      fi
   fi

   # Handle exported symbols (Darwin)
   if [ "${MULLE_UNAME}" = "darwin" -a "${MULLE_TEST_SYMBOLS}" != 'DEFAULT' -a ! -z "${MULLE_TEST_SYMBOLS}" ]
   then
      r_concat "${extra_flags}" "-Wl,-exported_symbols_list,'${MULLE_TEST_SYMBOLS}'"
      extra_flags="${RVAL}"
   fi

   # Add user-specified c_flags
   if [ ! -z "${c_flags}" ]
   then
      r_concat "${extra_flags}" "${c_flags}"
      extra_flags="${RVAL}"
   fi

   # Add any additional arguments passed to this function
   if [ $# -gt 0 ]
   then
      r_concat "${extra_flags}" "$@"
      extra_flags="${RVAL}"
   fi

   # Add source and output
   cmdline="${cmdline} '${srcfile}' -o '${a_out}'"

   # Add extra flags at the end (after --)
   if [ ! -z "${extra_flags}" ]
   then
      cmdline="${cmdline} -- ${extra_flags}"
   fi

   RVAL="${cmdline}"
}
