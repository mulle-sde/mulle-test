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
DEPENDENCIES='mulle-kybernetik/mulle-sde
mulle-kybernetik/mulle-platform
'

DEBIAN_DEPENDENCIES="mulle-sde, mulle-platform, build-essential"

