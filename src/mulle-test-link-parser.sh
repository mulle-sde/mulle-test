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
MULLE_TEST_LINK_PARSER_SH='included'


# Parse platform-specific linker flags and convert to abstract mulle-platform flags
# This parses the output from mulle-sde linkorder (which is in platform-specific format)
# and converts it to abstract flags that mulle-platform can understand
test::link_parser::parse_linker_flags()
{
   log_entry "test::link_parser::parse_linker_flags" "$@"

   local link_command="$1"
   local ldflags="$2"
   local rpath_flags="$3"

   # Combine all flags into one string for parsing
   local all_flags="${link_command} ${ldflags} ${rpath_flags}"

   # Build abstract flags while preserving original order
   local abstract_flags
   abstract_flags=""

   # State tracking
   local in_whole_archive='NO'
   local current_lib

   # Parse the flags and convert to abstract format while maintaining order
   local flag
   local libdir
   local rpath
   for flag in ${all_flags}
   do
      case "${flag}" in
         # Library directory - convert to abstract -L format
         -L*)
            libdir="${flag#-L}"
            libdir="${libdir#\'}"
            libdir="${libdir%\'}"
            r_concat "${abstract_flags}" "-L'${libdir}'"
            abstract_flags="${RVAL}"
         ;;

         # Whole archive start - track state but don't emit yet
         -Wl,--whole-archive|--whole-archive)
            in_whole_archive='YES'
         ;;

         # Whole archive end - track state but don't emit yet
         -Wl,--no-whole-archive|--no-whole-archive)
            in_whole_archive='NO'
         ;;

         # Library flag - convert based on whole-archive state
         -l*)
            current_lib="${flag#-l}"
            if [ "${in_whole_archive}" = 'YES' ]
            then
               r_concat "${abstract_flags}" "--wholearchive ${current_lib}"
               abstract_flags="${RVAL}"
            else
               r_concat "${abstract_flags}" "-l${current_lib}"
               abstract_flags="${RVAL}"
            fi
         ;;

         # Rpath flag - convert to abstract format
         -Wl,-rpath,*|-Wl,-rpath=*)
            rpath="${flag#-Wl,-rpath,}"
            rpath="${rpath#-Wl,-rpath=}"
            rpath="${rpath#\'}"
            rpath="${rpath%\'}"
            r_concat "${abstract_flags}" "--rpath '${rpath}'"
            abstract_flags="${RVAL}"
         ;;

         # Skip platform-specific flags that mulle-platform handles automatically
         -Wl,--as-needed|-Wl,--no-as-needed|--as-needed|--no-as-needed)
            # Skip - handled automatically by wholearchive formatting
         ;;

         -Wl,--export-dynamic|--export-dynamic)
            # Preserve as an abstract flag; mulle-platform re-emits it in the
            # correct per-linker spelling (-export_dynamic on Mach-O,
            # --export-dynamic on ELF, nothing on Windows).
            r_concat "${abstract_flags}" "--export-dynamic"
            abstract_flags="${RVAL}"
         ;;

         -Wl,-dead_strip|-Wl,--gc-sections)
            # Skip - optimization flags handled by mulle-platform based on configuration
         ;;

         # Any other -Wl, flag - log warning but skip
         -Wl,*)
            log_warning "Skipping platform-specific linker flag: ${flag}"
         ;;

         # Static library files (.a)
         *.a)
            # Check if this is a whole-archive library
            if [ "${in_whole_archive}" = 'YES' ]
            then
               r_extensionless_basename "${flag}"
               current_lib="${RVAL#lib}"
               r_concat "${abstract_flags}" "--wholearchive ${current_lib}"
               abstract_flags="${RVAL}"
            else
               # For static libs outside whole-archive, we should link them directly
               # This is handled by mulle-platform's existing logic
               log_fluff "Static library found: ${flag}"
            fi
         ;;

         # Skip other flags
         *)
            log_fluff "Skipping unknown flag: ${flag}"
         ;;
      esac
   done

   RVAL="${abstract_flags}"
}
