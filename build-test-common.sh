#! /usr/bin/env bash

DEPENDENCY_DIR="`mulle-bootstrap paths dependencies`"

#
# only let it bootstrap if dependencies are required and not present
#
if [ -z "${DEPENDENCY_DIR}" -o -d "${DEPENDENCY_DIR}" ]
then
   MULLE_INSTALL_FLAGS="--no-bootstrap"
fi

#
# need mulle-build 3.8 for this to work
#
mulle-build -install --build-dir build --prefix "`pwd`" ${MULLE_INSTALL_FLAGS} "$@"
