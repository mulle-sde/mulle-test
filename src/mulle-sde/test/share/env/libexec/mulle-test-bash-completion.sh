# shellcheck shell=bash

if [ "`type -t "_mulle_test_complete"`" != "function" ]
then
   if [ ! -z "`command -v mulle-test`" ]
   then
      . "$(mulle-test libexec-dir)/mulle-test-bash-completion.sh"
   fi
fi
