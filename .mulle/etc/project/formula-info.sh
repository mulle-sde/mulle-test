# -- Formula Info --
# If you don't have this file, there will be no homebrew
# formula operations.
#
PROJECT="mulle-test"      # your project/repository name
DESC="☑︎ Run tests and compare their results against expectations"
LANGUAGE="bash"           # c,cpp, objc, bash ...
# NAME="${PROJECT}"       # formula filename without .rb extension


# Specify needed homebrew packages by name as you would when saying
# `brew install`.
#
# Use the ${DEPENDENCY_TAP} prefix for non-official dependencies.
# DEPENDENCIES and BUILD_DEPENDENCIES will be evaled later!
# So keep them single quoted.
#
# mulle-sde knows and depends on mulle-test now
#
DEPENDENCIES='${MULLE_SDE_TAP}mulle-platform'

DEBIAN_DEPENDENCIES="mulle-platform, build-essential"

