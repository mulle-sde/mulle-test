## 7.5.0

feature: add FreeBSD VM test platform with cross-compilation and remote execution

* new `freebsd-run` emulator runs cross-compiled FreeBSD test executables inside a libvirt/KVM VM over ssh, syncing shared libraries and test fixtures
* new `freebsd-devroot.sh` sets up a FreeBSD cross-development root (base.txz sysroot plus clang/lld/llvm wrappers) on Linux
* new `freebsd-vm.sh` creates and manages an unattended FreeBSD cloud-init VM (keygen, fetch, seed, reserve, create, ssh, status, purge)
* test harness honors ``MULLE_EMULATOR__FREEBSD`,` so `mulle-sde test --platform freebsd run` works like the Wine/Windows path
* Windows/mingw runs invoke `dos2unix -q` so empty output files are no longer reported as "binary symbol" noise
* suppress Wine Gecko/Mono installer popups and `err:` spam when resolving the wine path



* `mulle-test clean` now also clears the tool environment (var) of nested mulle-sde projects found in test cases
* prevents stale tool symlinks, such as a ninja pointing to a non-executable location, from surviving a clean and breaking the next run


feature: harden sanitizer runs and add per-test CFLAGS control

* sanitizer diagnostics are now fatal: undefined, address and thread runs set `halt_on_error` (and `abort/print_stacktrace),` so a sanitizer run no longer silently passes
* san/thread/ASan options are overridable via `MULLE_TEST_UBSAN_OPTIONS,` `MULLE_TEST_ASAN_OPTIONS` and `MULLE_TEST_TSAN_OPTIONS`
* new `.no-mulle-test.`<platform>`` sentinel (and dotfile-prefixed `.no-mulle-test`/`.no-mulle-test.`<platform>``) skips a directory, with the legacy `no-mulle-test.`<platform>`` form still honoured
* new ```<name>`.OTHER_CFLAGS`` augments the default CFLAGS instead of clobbering them
* cross-compilation now derives CC/CXX from `mulle-platform compiler env` rather than an internal triplet table
* option parsing now returns a non-zero status and exits 1 on `--help`/parse failure


## 7.4.0


* `mulle-test clean` now also clears the tool environment (var) of nested mulle-sde projects found in test cases
* prevents stale tool symlinks, such as a ninja pointing to a non-executable location, from surviving a clean and breaking the next run


feature: harden sanitizer runs and add per-test CFLAGS control

* sanitizer diagnostics are now fatal: undefined, address and thread runs set `halt_on_error` (and `abort/print_stacktrace),` so a sanitizer run no longer silently passes
* san/thread/ASan options are overridable via `MULLE_TEST_UBSAN_OPTIONS,` `MULLE_TEST_ASAN_OPTIONS` and `MULLE_TEST_TSAN_OPTIONS`
* new `.no-mulle-test.`<platform>`` sentinel (and dotfile-prefixed `.no-mulle-test`/`.no-mulle-test.`<platform>``) skips a directory, with the legacy `no-mulle-test.`<platform>`` form still honoured
* new ```<name>`.OTHER_CFLAGS`` augments the default CFLAGS instead of clobbering them
* cross-compilation now derives CC/CXX from `mulle-platform compiler env` rather than an internal triplet table
* option parsing now returns a non-zero status and exits 1 on `--help`/parse failure


## 7.3.0

Various small improvements


### 7.2.1

Various small improvements
