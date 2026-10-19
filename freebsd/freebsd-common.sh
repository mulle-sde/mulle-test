#!/usr/bin/env bash
#
# Shared helpers for the FreeBSD test-platform facilities.
#
# Sourced by freebsd-devroot.sh and freebsd-vm.sh. Not meant to be executed.
#

FREEBSD_RELEASE_INDEX="https://download.freebsd.org/releases/amd64/amd64"
FREEBSD_VMIMAGE_INDEX="https://download.freebsd.org/releases/VM-IMAGES"

freebsd_log()
{
   printf '%s\n' "$*" >&2
}

freebsd_info()
{
   printf '==> %s\n' "$*" >&2
}

freebsd_fail()
{
   freebsd_log "error: $*"
   exit 1
}

freebsd_require()
{
   local tool

   for tool in "$@"
   do
      command -v "${tool}" > /dev/null 2>&1 || \
         freebsd_fail "\"${tool}\" is required but not found in PATH"
   done
}

#
# Normalize "15.1" or "15.1-RELEASE" into "15.1-RELEASE".
#
freebsd_normalize_version()
{
   case "$1" in
      *-RELEASE) printf '%s\n' "$1" ;;
      *)         printf '%s-RELEASE\n' "$1" ;;
   esac
}

#
# Resolve the requested version. Order of precedence:
#   1. explicit argument
#   2. FREEBSD_VERSION environment variable
#   3. newest N.N-RELEASE published on download.freebsd.org
#
freebsd_resolve_version()
{
   local version

   if [ -n "${1:-}" ]
   then
      freebsd_normalize_version "$1"
      return 0
   fi

   if [ -n "${FREEBSD_VERSION:-}" ]
   then
      freebsd_normalize_version "${FREEBSD_VERSION}"
      return 0
   fi

   freebsd_require curl
   version="$(curl -fsSL "${FREEBSD_RELEASE_INDEX}/" \
      | sed -n 's/.*href="\([0-9][0-9]*\.[0-9][0-9]*-RELEASE\)\/".*/\1/p' \
      | sort -V \
      | tail -1)"

   [ -n "${version}" ] || freebsd_fail "could not resolve the latest FreeBSD release"
   printf '%s\n' "${version}"
}

freebsd_version_number()
{
   printf '%s\n' "${1%-RELEASE}"
}

freebsd_version_major()
{
   local number

   number="${1%-RELEASE}"
   printf '%s\n' "${number%%.*}"
}

freebsd_triple()
{
   printf 'x86_64-unknown-freebsd%s\n' "$(freebsd_version_number "$1")"
}

#
# Verify the sha256 of a file against FreeBSD's MANIFEST (base.txz) or
# CHECKSUM.SHA256 (VM images). Usage:
#   freebsd_verify_sha256 <file> <manifest> <filename-in-manifest>
#
freebsd_verify_sha256()
{
   local file="$1"
   local manifest="$2"
   local name="$3"
   local line
   local expected
   local actual

   line="$(grep -F "${name}" "${manifest}" | head -1)"
   [ -n "${line}" ] || freebsd_fail "no checksum for ${name} in ${manifest}"

   case "${line}" in
      *" = "*) expected="${line##* = }" ;;
      *)       expected="$(printf '%s\n' "${line}" | awk '{ print $2 }')" ;;
   esac
   [ -n "${expected}" ] || freebsd_fail "could not parse checksum for ${name}"

   actual="$(sha256sum "${file}" | awk '{ print $1 }')"
   [ "${expected}" = "${actual}" ] || \
      freebsd_fail "checksum mismatch for ${file}: expected ${expected}, got ${actual}"

   freebsd_log "checksum ok: ${name}"
}
