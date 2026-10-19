#!/usr/bin/env bash
#
# freebsd-devroot.sh - set up a local FreeBSD cross-development root on Linux.
#
# It fetches the FreeBSD base.txz for a release, extracts a sysroot and
# generates clang/lld wrapper scripts so that
#
#     freebsd-clang -o hello hello.c
#
# produces a FreeBSD ELF executable with the FreeBSD dynamic linker.
#
# The runtime side (executing the binary) is handled by freebsd-vm.sh.
#
# Environment:
#   FREEBSD_DEV_ROOT   root directory            (default: ~/.mulle/freebsd)
#   FREEBSD_VERSION    release, e.g. 15.1-RELEASE or "15.1"
#   FREEBSD_CLANG      C compiler                (default: clang)
#   FREEBSD_CLANGXX    C++ compiler              (default: clang++)
#   FREEBSD_LLVM_BIN   directory with llvm-* tools (default: derived from clang)
#
set -euo pipefail

here="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
. "${here}/freebsd-common.sh"

DEFAULT_DEV_ROOT="${HOME}/.mulle/freebsd"

usage()
{
   cat <<EOF
Usage:
   $(basename "$0") [options] fetch [version]   fetch base.txz and create the root
   $(basename "$0") [options] env                print shell exports for the root
   $(basename "$0") [options] check              compile/link/inspect a hello world
   $(basename "$0") [options] show               show the resolved layout

Options:
   --root <dir>       development root (default: \${FREEBSD_DEV_ROOT:-${DEFAULT_DEV_ROOT}})
   --version <ver>    FreeBSD release, e.g. 15.1-RELEASE (default: latest)
   -h, --help         this help

Environment overrides: FREEBSD_DEV_ROOT, FREEBSD_VERSION, FREEBSD_CLANG,
FREEBSD_CLANGXX, FREEBSD_LLVM_BIN
EOF
}

main()
{
   local dev_root="${FREEBSD_DEV_ROOT:-${DEFAULT_DEV_ROOT}}"
   local version_arg=""
   local command=""

   while [ $# -gt 0 ]
   do
      case "$1" in
         --root)
            [ $# -ge 2 ] || freebsd_fail "--root requires an argument"
            dev_root="$2"
            shift 2
            ;;
         --version)
            [ $# -ge 2 ] || freebsd_fail "--version requires an argument"
            version_arg="$2"
            shift 2
            ;;
         -h|--help)
            usage
            exit 0
            ;;
         -*)
            freebsd_fail "unknown option \"$1\" (try --help)"
            ;;
         *)
            command="$1"
            shift
            break
            ;;
      esac
   done

   [ -n "${command}" ] || { usage; exit 1; }

   local version
   version="$(freebsd_resolve_version "${version_arg}")"
   local root="${dev_root}/${version}"

   case "${command}" in
      fetch) devroot_fetch "${dev_root}" "${root}" "${version}" ;;
      env)   devroot_env "${root}" "${version}" ;;
      check) devroot_check "${root}" "${version}" ;;
      show)  devroot_show "${root}" "${version}" ;;
      *)
         freebsd_fail "unknown command \"${command}\" (try --help)"
         ;;
   esac
}

devroot_fetch()
{
   local dev_root="$1"
   local root="$2"
   local version="$3"
   local downloads="${root}/downloads"
   local sysroot="${root}/sysroot"
   local base_txz="${downloads}/base.txz"
   local manifest="${downloads}/MANIFEST"
   local url="${FREEBSD_RELEASE_INDEX}/${version}"

   freebsd_require curl tar xz sha256sum

   mkdir -p "${downloads}" "${sysroot}" "${root}/bin"

   if [ ! -f "${base_txz}" ]
   then
      freebsd_info "fetching ${url}/base.txz"
      curl -fL --progress-bar -o "${base_txz}.part" "${url}/base.txz"
      mv "${base_txz}.part" "${base_txz}"
   else
      freebsd_info "reusing ${base_txz}"
   fi

   freebsd_info "fetching MANIFEST"
   curl -fsSL -o "${manifest}.part" "${url}/MANIFEST"
   mv "${manifest}.part" "${manifest}"

   freebsd_verify_sha256 "${base_txz}" "${manifest}" "base.txz"

   if [ ! -f "${sysroot}/.stamp" ] || [ "${base_txz}" -nt "${sysroot}/.stamp" ]
   then
      freebsd_info "extracting base.txz into ${sysroot}"
      tar -xpf "${base_txz}" -C "${sysroot}"
      : > "${sysroot}/.stamp"
   fi

   printf '%s\n' "${version}" > "${root}/VERSION"

   devroot_write_wrappers "${root}"
   devroot_write_env "${root}" "${version}"
   devroot_install_marker "${root}" "${version}"

   freebsd_info "development root ready: ${root}"
   devroot_show "${root}" "${version}"
}

#
# mulle-sde gates cross-compilation on /opt/mulle-clang-project-<platform>
# existing (like the Windows toolchain). Point it at this development root.
#
devroot_install_marker()
{
   local root="$1"
   local version="$2"
   local project_dir="/opt/mulle-clang-project-freebsd"
   local marker="${project_dir}/${version}"

   if [ -L "${marker}" ] && \
      [ "$(readlink -f "${marker}")" = "$(readlink -f "${root}")" ]
   then
      return 0
   fi

   local sudo=""
   [ -w "${project_dir:-/opt}" ] || sudo="sudo"

   if ! ${sudo} true 2>/dev/null
   then
      freebsd_log "warning: cannot create ${marker} (need sudo); mulle-sde test may refuse the platform"
      return 0
   fi

   freebsd_info "installing toolchain marker ${marker} -> ${root}"
   ${sudo} mkdir -p "${project_dir}"
   ${sudo} ln -sfn "${root}" "${marker}"
}

devroot_llvm_bin()
{
   if [ -n "${FREEBSD_LLVM_BIN:-}" ]
   then
      printf '%s\n' "${FREEBSD_LLVM_BIN}"
      return 0
   fi

   local cc
   cc="$(command -v "${FREEBSD_CLANG:-clang}" || true)"
   if [ -n "${cc}" ]
   then
      dirname "$(readlink -f "${cc}")"
      return 0
   fi

   printf '\n'
}

devroot_write_wrappers()
{
   local root="$1"
   local bin="${root}/bin"
   local llvm_bin
   local tool
   local triplet="x86_64-unknown-freebsd"

   llvm_bin="$(devroot_llvm_bin)"

   devroot_write_cc_wrapper "${bin}/freebsd-clang"  "FREEBSD_CLANG" "${FREEBSD_CLANG:-clang}"
   devroot_write_cc_wrapper "${bin}/freebsd-clang++" "FREEBSD_CLANGXX" "${FREEBSD_CLANGXX:-clang++}"

   # mulle-clang wrappers for Objective-C / mulle-objc (they carry the
   # mulle-objc runtime, unlike stock clang).
   devroot_write_cc_wrapper "${bin}/freebsd-mulle-clang"   "FREEBSD_MULLE_CLANG"   "${FREEBSD_MULLE_CLANG:-mulle-clang}"
   devroot_write_cc_wrapper "${bin}/freebsd-mulle-clang++" "FREEBSD_MULLE_CLANGXX" "${FREEBSD_MULLE_CLANGXX:-mulle-clang++}"

   # mulle-make looks for <triplet>-<tool> in the cross-compiler root, so
   # provide the same wrappers under the triple used in the toolchain name.
   devroot_write_cc_wrapper "${bin}/${triplet}-clang"   "FREEBSD_CLANG" "${FREEBSD_CLANG:-clang}"
   devroot_write_cc_wrapper "${bin}/${triplet}-clang++" "FREEBSD_CLANGXX" "${FREEBSD_CLANGXX:-clang++}"
   devroot_write_cc_wrapper "${bin}/${triplet}-mulle-clang"   "FREEBSD_MULLE_CLANG"   "${FREEBSD_MULLE_CLANG:-mulle-clang}"
   devroot_write_cc_wrapper "${bin}/${triplet}-mulle-clang++" "FREEBSD_MULLE_CLANGXX" "${FREEBSD_MULLE_CLANGXX:-mulle-clang++}"

   for tool in ar ranlib nm strip objdump readelf size
   do
      if [ -n "${llvm_bin}" ] && [ -x "${llvm_bin}/llvm-${tool}" ]
      then
         devroot_write_tool_wrapper "${bin}/freebsd-${tool}" "${llvm_bin}/llvm-${tool}"
         devroot_write_tool_wrapper "${bin}/${triplet}-${tool}" "${llvm_bin}/llvm-${tool}"
      fi
   done

   freebsd_info "wrappers written to ${bin}"
}

devroot_write_cc_wrapper()
{
   local path="$1"
   local envname="$2"
   local compiler="$3"

   cat > "${path}" <<EOF
#!/bin/sh
# generated by freebsd-devroot.sh - do not edit
set -e
self="\$(CDPATH= cd -- "\$(dirname -- "\$0")" && pwd)"
root="\$(dirname -- "\${self}")"
version="\$(cat "\${root}/VERSION")"
number="\${version%-RELEASE}"
compiler="\${${envname}:-${compiler}}"

# -fuse-ld=lld is only meaningful when linking
link_flag="-fuse-ld=lld"
for arg in "\$@"
do
   case "\${arg}" in
      -c|-S|-E|-M|-MM|-fsyntax-only|-dumpmachine|-dumpversion|--version)
         link_flag=""
         break
      ;;
   esac
done

exec "\${compiler}" \\
   --target="x86_64-unknown-freebsd\${number}" \\
   --sysroot="\${root}/sysroot" \\
   \${link_flag} \\
   "\$@"
EOF
   chmod +x "${path}"
}

devroot_write_tool_wrapper()
{
   local path="$1"
   local tool="$2"

   cat > "${path}" <<EOF
#!/bin/sh
# generated by freebsd-devroot.sh - do not edit
exec "${tool}" "\$@"
EOF
   chmod +x "${path}"
}

devroot_write_env()
{
   local root="$1"
   local version="$2"

   cat > "${root}/env.sh" <<EOF
# generated by freebsd-devroot.sh - source, do not execute
FREEBSD_VERSION="${version}"
FREEBSD_DEV_ROOT="${root}"
FREEBSD_SYSROOT="${root}/sysroot"
FREEBSD_TRIPLE="$(freebsd_triple "${version}")"
FREEBSD_CC="${root}/bin/freebsd-clang"
FREEBSD_CXX="${root}/bin/freebsd-clang++"
FREEBSD_AR="${root}/bin/freebsd-ar"
FREEBSD_RANLIB="${root}/bin/freebsd-ranlib"
FREEBSD_MULLE_CC="${root}/bin/freebsd-mulle-clang"
FREEBSD_MULLE_CXX="${root}/bin/freebsd-mulle-clang++"
export FREEBSD_VERSION FREEBSD_DEV_ROOT FREEBSD_SYSROOT FREEBSD_TRIPLE
export FREEBSD_CC FREEBSD_CXX FREEBSD_AR FREEBSD_RANLIB
export FREEBSD_MULLE_CC FREEBSD_MULLE_CXX
case ":\${PATH}:" in
   *:"${root}/bin":*) ;;
   *) PATH="${root}/bin:\${PATH}" ;;
esac
export PATH
EOF
}

devroot_env()
{
   local root="$1"
   local version="$2"

   [ -f "${root}/env.sh" ] || freebsd_fail "no development root at ${root} (run: fetch)"
   cat "${root}/env.sh"
}

devroot_show()
{
   local root="$1"
   local version="$2"
   local sysroot="${root}/sysroot"

   [ -d "${sysroot}" ] || { freebsd_fail "no sysroot at ${sysroot} (run: fetch)"; }

   freebsd_log "version:  ${version}"
   freebsd_log "root:     ${root}"
   freebsd_log "sysroot:  ${sysroot}"
   freebsd_log "triple:   $(freebsd_triple "${version}")"
   freebsd_log "compiler: ${root}/bin/freebsd-clang"
   freebsd_log "dynamic linker: $(ls "${sysroot}/libexec/"ld-elf.so.* 2>/dev/null | head -1 || echo '(missing!)')"
}

devroot_check()
{
   local root="$1"
   local version="$2"
   local sysroot="${root}/sysroot"
   local cc="${root}/bin/freebsd-clang"
   local llvm_bin
   local tmp

   [ -x "${cc}" ] || freebsd_fail "no wrapper at ${cc} (run: fetch)"
   [ -d "${sysroot}" ] || freebsd_fail "no sysroot at ${sysroot} (run: fetch)"

   freebsd_require file

   llvm_bin="$(devroot_llvm_bin)"
   if ! command -v ld.lld > /dev/null 2>&1 && [ ! -x "${llvm_bin}/ld.lld" ]
   then
      freebsd_log "warning: ld.lld not found; install it with: sudo apt install lld"
   fi

   tmp="$(mktemp -d)"
   trap 'rm -rf "${tmp:-}"' EXIT

   cat > "${tmp}/hello.c" <<'EOF'
#include <stdio.h>

int
main(void)
{
   puts("hello from FreeBSD");
   return 0;
}
EOF

   freebsd_info "compiling with ${cc}"
   if ! "${cc}" -o "${tmp}/hello" "${tmp}/hello.c"
   then
      freebsd_fail "cross compile/link failed (is lld installed?)"
   fi

   freebsd_info "result:"
   file "${tmp}/hello" >&2

   local readelf="${llvm_bin}/llvm-readelf"
   if [ -x "${readelf}" ]
   then
      "${readelf}" -l "${tmp}/hello" | grep -i interpreter >&2 || true
      "${readelf}" -d "${tmp}/hello" | grep -i needed >&2 || true
   fi

   freebsd_info "ok"
}

main "$@"
