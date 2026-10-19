# Testing FreeBSD in a VM

Cross-compile test executables on Linux and run them inside a FreeBSD VM,
the same way Windows builds run under Wine.

```
Linux host                          FreeBSD VM
-----------                         ----------
clang --target=x86_64-unknown-freebsd
--sysroot=<FreeBSD base.txz>   -->   execute test executable
fuse-ld=lld                          (shared libs synced over ssh)
```

Three pieces are needed:

1. a **development root** on the host: FreeBSD headers/libs + clang wrappers
2. a **FreeBSD VM** reachable over ssh
3. **mulle-sde** configuration telling the test project how to build and run

The helper scripts are shipped with `mulle-test` and installed onto your
`PATH` (`mulle-test/freebsd/` in a source checkout):

| script               | purpose                                          |
| -------------------- | ------------------------------------------------ |
| `freebsd-devroot.sh` | fetch FreeBSD `base.txz`, create cross wrappers  |
| `freebsd-vm.sh`      | create/manage the FreeBSD VM under libvirt       |
| `freebsd-run`        | `MULLE_EMULATOR__FREEBSD` wrapper (runs remotely)|

---

## 0. Prerequisites

Host is assumed to be Linux (Debian/Ubuntu package names):

```bash
sudo apt install \
   clang lld llvm \
   qemu-system-x86 qemu-utils \
   libvirt-daemon-system libvirt-clients \
   genisoimage xz-utils curl tar rsync sudo
```

Requirements beyond installing packages:

- The libvirt `default` network is active: `virsh net-list --all`
- Your user may manage `qemu:///system` (be in the `libvirt` group, or use sudo)
- `sudo` is available (used for `/etc/hosts` and the toolchain marker)
- A `mulle-platform` with cross-compiler support and a `mulle-test` that
  delegates to it (see *Triplet / compiler selection* below)
- `flock` (util-linux) on the host, so parallel test runs serialize their
  access to the VM (otherwise set `MULLE_TEST_PARALLEL=NO`)
- Dependencies that build on FreeBSD 15 — in particular they must not include
  the removed `<stdthreads.h>` (use `<threads.h>`)

Installing `mulle-test` puts `freebsd-devroot.sh`, `freebsd-vm.sh` and
`freebsd-run` on your `PATH`. When running from a source checkout instead,
put the scripts on `PATH` manually (and make sure they are executable):

```bash
chmod +x /path/to/mulle-test/freebsd/freebsd-*.sh /path/to/mulle-test/freebsd/freebsd-run
export PATH="/path/to/mulle-test/freebsd:${PATH}"
```

---

## 1. FreeBSD development root

Fetch the latest release (or pin one). This downloads `base.txz`, verifies it
against FreeBSD's `MANIFEST`, extracts a sysroot, generates `clang`/`lld`
wrappers and creates the toolchain marker `/opt/mulle-clang-project-freebsd`:

```bash
freebsd-devroot.sh fetch
# or a specific release:
freebsd-devroot.sh --version 15.1-RELEASE fetch
```

Verify the cross toolchain actually produces a FreeBSD binary:

```bash
freebsd-devroot.sh check
# -> ELF 64-bit ... (FreeBSD), interpreter /libexec/ld-elf.so.1, NEEDED libc.so.7
```

Resulting layout (default root `~/.mulle/freebsd/<version>`):

```
~/.mulle/freebsd/15.1-RELEASE/
  VERSION
  sysroot/                              # FreeBSD base.txz
  bin/freebsd-clang                     # plain C
  bin/freebsd-mulle-clang               # Objective-C / mulle-objc
  bin/x86_64-unknown-freebsd-clang      # used by mulle-make
  bin/x86_64-unknown-freebsd-{ar,ranlib,nm,strip,...}
  env.sh                                # source for manual use
```

Show the layout, or get shell exports for manual compilation:

```bash
freebsd-devroot.sh show
freebsd-devroot.sh env > /tmp/freebsd.env && . /tmp/freebsd.env
```

---

## 2. FreeBSD VM

Create everything in one shot — generate the ssh key, download the official
cloud-init qcow2, verify it, generate a NoCloud seed, reserve a stable DHCP
address, add `/etc/hosts`, define and start the domain:

```bash
freebsd-vm.sh create
freebsd-vm.sh wait          # wait until ssh answers
```

Then:

```bash
freebsd-vm.sh ssh                      # interactive shell
freebsd-vm.sh ssh uname -a             # FreeBSD freebsd 15.1-RELEASE ...
freebsd-vm.sh status
freebsd-vm.sh stop
freebsd-vm.sh start
freebsd-vm.sh destroy
```

Defaults:

| setting      | value                                    |
| ------------ | ---------------------------------------- |
| name         | `freebsd`                                |
| address      | `192.168.122.20` (reserved by MAC)       |
| user         | `vm`                                     |
| ssh key      | `~/.ssh/id_rsa_vm`                       |
| VM images    | `/home/vm/images`, `/home/vm/isos`       |

Every setting can be overridden with an environment variable (see the
reference below), for example:

```bash
FREEBSD_VM_IP=192.168.122.30 FREEBSD_VM_MAC=52:54:00:fb:5d:30 freebsd-vm.sh create
```

If a key must be created first:

```bash
FREEBSD_VM_SSH_KEY=~/.ssh/freebsd_vm freebsd-vm.sh keygen
```

---

## 3. Configure the test project

The `test/` directory is its own mulle-sde project. Run these there.

Create the toolchain file
`test/cmake/toolchain--linux-freebsd--x86_64-unknown-freebsd--mulle-clang.cmake`
**before** adding the platform — `mulle-sde platform` discovers it and fails
if it is missing. The name encodes host, platform, triplet and compiler, and
it may live in `cmake/` (as here) or `cmake/share/`:

```cmake
# Toolchain file for cross-compiling to FreeBSD with clang/lld or mulle-clang.
#
# Requires a development root (created by freebsd-devroot.sh) with
#   <root>/sysroot, <root>/bin/freebsd-clang and <root>/bin/freebsd-mulle-clang
set(CMAKE_SYSTEM_NAME FreeBSD)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

if(NOT DEFINED FREEBSD_ROOT)
    if(DEFINED ENV{MULLE_CROSS_COMPILER_ROOT})
        set(FREEBSD_ROOT "$ENV{MULLE_CROSS_COMPILER_ROOT}")
    elseif(DEFINED ENV{FREEBSD_DEV_ROOT})
        set(FREEBSD_ROOT "$ENV{FREEBSD_DEV_ROOT}")
    else()
        set(FREEBSD_ROOT "$ENV{HOME}/.mulle/freebsd/15.1-RELEASE")
    endif()
endif()

if(EXISTS "${FREEBSD_ROOT}/VERSION")
    file(READ "${FREEBSD_ROOT}/VERSION" FREEBSD_VERSION)
    string(STRIP "${FREEBSD_VERSION}" FREEBSD_VERSION)
else()
    set(FREEBSD_VERSION "15.1-RELEASE")
endif()

string(REGEX REPLACE "-RELEASE$" "" FREEBSD_VERSION_NUMBER "${FREEBSD_VERSION}")
set(FREEBSD_TRIPLE "x86_64-unknown-freebsd${FREEBSD_VERSION_NUMBER}")
set(FREEBSD_SYSROOT "${FREEBSD_ROOT}/sysroot")

if(NOT EXISTS "${FREEBSD_SYSROOT}")
    message(FATAL_ERROR "No FreeBSD sysroot at \"${FREEBSD_SYSROOT}\".")
endif()

# Objective-C (mulle-objc) must use mulle-clang, plain C uses stock clang.
if("$ENV{PROJECT_DIALECT}" STREQUAL "objc" OR "$ENV{PROJECT_DIALECT}" STREQUAL "objcpp")
    set(FREEBSD_COMPILER_SUFFIX "mulle-clang")
    set(FREEBSD_MULLE_OBJC ON)
else()
    set(FREEBSD_COMPILER_SUFFIX "clang")
    set(FREEBSD_MULLE_OBJC OFF)
endif()

set(CMAKE_C_COMPILER   "${FREEBSD_ROOT}/bin/freebsd-${FREEBSD_COMPILER_SUFFIX}"   CACHE FILEPATH "C compiler" FORCE)
set(CMAKE_CXX_COMPILER "${FREEBSD_ROOT}/bin/freebsd-${FREEBSD_COMPILER_SUFFIX}++" CACHE FILEPATH "CXX compiler" FORCE)
set(CMAKE_C_COMPILER_TARGET   "${FREEBSD_TRIPLE}")
set(CMAKE_CXX_COMPILER_TARGET "${FREEBSD_TRIPLE}")

# mulle-cmake reads MULLE_C_COMPILER_ID; a wrapper name hides that it is
# mulle-clang, so state it explicitly (same as the Windows toolchain).
if(FREEBSD_MULLE_OBJC)
    set(MULLE_C_COMPILER_ID   "MULLECLANG")
    set(MULLE_CXX_COMPILER_ID "MULLECLANG")
endif()

# -fuse-ld=lld belongs on the link line only
set(CMAKE_C_FLAGS_INIT   "--sysroot=${FREEBSD_SYSROOT}")
set(CMAKE_CXX_FLAGS_INIT "--sysroot=${FREEBSD_SYSROOT}")
set(CMAKE_EXE_LINKER_FLAGS_INIT    "--sysroot=${FREEBSD_SYSROOT} -fuse-ld=lld")
set(CMAKE_SHARED_LINKER_FLAGS_INIT "--sysroot=${FREEBSD_SYSROOT} -fuse-ld=lld")
set(CMAKE_MODULE_LINKER_FLAGS_INIT "--sysroot=${FREEBSD_SYSROOT} -fuse-ld=lld")
set(CMAKE_AR     "${FREEBSD_ROOT}/bin/freebsd-ar"     CACHE FILEPATH "archiver" FORCE)
set(CMAKE_RANLIB "${FREEBSD_ROOT}/bin/freebsd-ranlib" CACHE FILEPATH "ranlib" FORCE)
set(CMAKE_SYSROOT "${FREEBSD_SYSROOT}")

set(CMAKE_FIND_ROOT_PATH "${FREEBSD_SYSROOT}")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM BOTH)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY BOTH)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE BOTH)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE BOTH)

set(CMAKE_STATIC_LIBRARY_SUFFIX ".a" CACHE STRING "static library suffix")
```

Then register the platform, the development root and the emulator:

```bash
cd test

# use the root printed by `freebsd-devroot.sh show`
mulle-sde platform add freebsd
mulle-sde platform set freebsd root "$HOME/.mulle/freebsd/15.1-RELEASE"
mulle-sde platform set freebsd emulator "$(command -v freebsd-run)"

mulle-sde platform            # verify: freebsd (toolchain--linux-freebsd--...)
```

---

## 4. Build and run

```bash
cd ..                                   # back to the project root (parent of test/)

mulle-sde test craft                    # cross-build dependencies + tests
mulle-sde test --platform freebsd run   # run all tests on FreeBSD only
mulle-sde test --platform all run       # linux + windows + freebsd
```

`--platform` persists in `MULLE_TEST_PLATFORMS`, so a later plain
`mulle-sde test run` keeps using it. Reset with `--platform all`. Start with a
single test before running the whole suite:

```bash
mulle-sde test --platform freebsd run test/10-fnva1/step.c
```

Run a single test, rerun failures, or use valgrind-style helpers:

```bash
mulle-sde test --platform freebsd run test/10-fnva1/step.c
mulle-sde test --platform freebsd rerun
```

Enable vibecoding to keep `*.tmp.stdout`/`*.tmp.stderr` and the built `.exe`
for inspection:

```bash
mulle-sde vibecoding on
mulle-sde test --platform freebsd run test/10-fnva1/step.c
```

---

## Reference

### `freebsd-devroot.sh`

```
freebsd-devroot.sh [--root DIR] [--version VER] fetch|env|check|show
```

| variable           | default              | meaning                          |
| ------------------ | -------------------- | -------------------------------- |
| `FREEBSD_DEV_ROOT` | `~/.mulle/freebsd`   | root directory                    |
| `FREEBSD_VERSION`  | latest release       | e.g. `15.1-RELEASE`               |
| `FREEBSD_CLANG`    | `clang`              | C compiler                        |
| `FREEBSD_CLANGXX`  | `clang++`            | C++ compiler                      |
| `FREEBSD_LLVM_BIN` | derived from clang   | dir with `llvm-ar` etc.           |

### `freebsd-vm.sh`

```
freebsd-vm.sh [--name NAME] [--version VER] \
   keygen|fetch|seed|reserve|hosts|create|start|stop|destroy|console|ip|wait|ssh|status|rm|purge
```

| variable                | default               | meaning                        |
| ----------------------- | --------------------- | ------------------------------ |
| `FREEBSD_VM_NAME`       | `freebsd`             | libvirt domain name            |
| `FREEBSD_VERSION`       | latest release        | FreeBSD release for the image  |
| `FREEBSD_VM_IP`         | `192.168.122.20`      | reserved address (keep free!)  |
| `FREEBSD_VM_MAC`        | `52:54:00:fb:5d:20`   | must be unique on the network  |
| `FREEBSD_VM_SSH_KEY`    | `~/.ssh/id_rsa_vm`    | private key                    |
| `FREEBSD_VM_USER`       | `vm`                  | guest user                     |
| `FREEBSD_VM_MEMORY`     | `2048`                | MiB                            |
| `FREEBSD_VM_VCPUS`      | `2`                   | vcpus                          |
| `FREEBSD_VM_DISK_SIZE`  | `20G`                 | disk size                      |
| `FREEBSD_VM_IMAGE_DIR`  | `/home/vm/images`     | qcow2 location                 |
| `FREEBSD_VM_ISO_DIR`    | `/home/vm/isos`       | seed ISO location              |
| `FREEBSD_VM_NETWORK`    | `default`             | libvirt network                |
| `FREEBSD_VM_WAIT`       | `300`                 | ssh wait timeout (seconds)     |

### `freebsd-run` (emulator)

Used automatically through `MULLE_EMULATOR__FREEBSD`. It resolves the shared
libraries via

```
mulle-craft searchpath --sdk "$TEST_SDK" --platform "$TEST_PLATFORM" \
                       --configuration "$TEST_CONFIGURATION" library|binary
```

and syncs them plus the test's working directory to the VM (rsync when
present, tar otherwise). It runs from a copy of that directory with
`LD_LIBRARY_PATH` set, so checked-in fixtures (`*.bundle`, demo dirs, data
files) next to the test are available. Remote access is serialized per VM, so
the rest of the suite can still run in parallel.

| variable                  | default            | meaning                     |
| ------------------------- | ------------------ | --------------------------- |
| `FREEBSD_VM_HOST`         | `freebsd`          | ssh host (`/etc/hosts`)     |
| `FREEBSD_VM_USER`         | `vm`               | ssh user                    |
| `FREEBSD_VM_SSH_KEY`      | `~/.ssh/id_rsa_vm` | private key                 |
| `FREEBSD_VM_REMOTE_DIR`   | `/tmp/mulle-test`  | staging dir base on the VM  |

---

## Upgrading FreeBSD

```bash
freebsd-devroot.sh --version 15.2-RELEASE fetch
freebsd-vm.sh --name freebsd15 --version 15.2-RELEASE create
```

Point the test project at the new root and re-craft:

```bash
cd test
mulle-sde platform set freebsd root "$HOME/.mulle/freebsd/15.2-RELEASE"
cd ..
mulle-sde test craft
```

`--version` also accepts a bare number (`15.1`). Keep the sysroot release and
the VM release identical, since they share libc and the dynamic linker.

---

## Cleanup

```bash
freebsd-vm.sh rm        # destroy + undefine the domain (keeps disk/seed)
freebsd-vm.sh purge     # also delete disk and seed ISO
```

Remove the DHCP reservation and `/etc/hosts` entry manually:

```bash
virsh net-update default delete ip-dhcp-host \
   "<host mac='52:54:00:fb:5d:20' name='freebsd' ip='192.168.122.20'/>" \
   --live --config
sudo sed -i -E '/[[:space:]]freebsd([[:space:]]|$)/d' /etc/hosts
```

Remove the development root:

```bash
rm -rf ~/.mulle/freebsd/15.1-RELEASE
sudo rm -rf /opt/mulle-clang-project-freebsd
```

---

## Triplet / compiler selection

`mulle-sde platform setup` records the triplet found in the toolchain name
`toolchain--<host>-<platform>--<triplet>--<compiler>.cmake`:

```
MULLE_SDE_PLATFORM_TRIPLET__FREEBSD="x86_64-unknown-freebsd"
```

`mulle-platform` resolves the cross compiler from that triplet (with a generic
default when it is not set):

```
x86_64-unknown-<platform>        # BSD/unix, e.g. x86_64-unknown-freebsd
x86_64-w64-mingw32               # windows
```

and looks for the compiler/tools at

```
$MULLE_CRAFT_CROSS_COMPILER_ROOT__<PLATFORM>/bin/<triplet>-<clang|mulle-clang,ar,...>
```

The compiler is chosen by dialect: Objective-C (`mulle-objc`) uses
`<triplet>-mulle-clang`, plain C uses `<triplet>-clang`. The development root
therefore provides both `freebsd-clang` and `freebsd-mulle-clang` (plus their
`x86_64-unknown-freebsd-…` variants). `mulle-test` simply asks
`mulle-platform compiler env --platform <platform>` (passing the dialect), so
no platform knowledge lives in mulle-test. For a custom triplet (say
aarch64), override it:

```bash
mulle-sde environment --scope project set \
   MULLE_SDE_PLATFORM_TRIPLET__FREEBSD aarch64-unknown-freebsd
```

Mixing compilers is a common trap: building mulle-objc with stock `clang`
fails with `missing context for method declaration` / `expected method body`,
and selecting the wrong compiler for a dependency shows up as unrelated type
errors later. If in doubt, check the compile command in
`kitchen/.craftorder/<platform>/<config>/<dep>/compile_commands.json`.
