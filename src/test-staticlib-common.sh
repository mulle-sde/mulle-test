#! /usr/bin/env bash

[ -z "${STATICLIB_EXTENSION}" -a -z "${STATICLIB_PREFIX}" ] && echo "STATICLIB variables undefined" 2>&1 && exit 1

LIB_PREFIX="${STATICLIB_PREFIX}"
LIB_EXTENSION="${STATICLIB_EXTENSION}"
LIB_SUFFIX="${LIB_SUFFIX}"
