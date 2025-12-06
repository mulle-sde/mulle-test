# mulle-platform Enhancement Proposal

## Overview

To simplify mulle-test and enable better reusability across mulle-* tools, we propose adding compiler and flag management commands to mulle-platform. This centralizes platform-specific knowledge in one place.

## Current State

Currently, mulle-platform provides:
- `mulle-platform environment` - Platform detection and environment variables
- Platform-specific libraries (e.g., `platform::environment`, `platform::flags`)
- Some SDK path helpers

But each tool (mulle-test, mulle-make, mulle-craft) reimplements:
- Compiler selection logic
- Flag generation for different configurations
- Platform-specific quirks handling

## Proposed New Commands

### 1. `mulle-platform compiler`

**Purpose**: Select and configure the appropriate compiler for a platform/language combination.

**Usage:**
```bash
mulle-platform compiler [options]

Options:
  --platform <name>        Platform (linux, darwin, mingw, windows, etc.)
  --language <name>        Language (c, objc, cpp, swift, etc.)
  --dialect <name>         Dialect (c, objc, mulle-objc, gnu, etc.)
  --compiler-type <type>   Force compiler type (gcc, clang, mulle-clang, cl)
  --print-env              Output as environment variables (default)
  --print-json             Output as JSON
```

**Example Output:**
```bash
$ mulle-platform compiler --language c --platform linux
CC='gcc'
CXX='g++'
COMPILER_TYPE='gcc'
COMPILER_VERSION='11.3.0'

$ mulle-platform compiler --language objc --dialect mulle-objc --platform darwin
CC='mulle-clang'
CXX='mulle-clang++'
COMPILER_TYPE='mulle-clang'
OBJC_DIALECT='mulle-objc'

$ mulle-platform compiler --language c --platform mingw
CC='cl'
CXX='cl'
COMPILER_TYPE='msvc'
LINK_MODE='exe'
```

**Implementation Considerations:**
- Check if preferred compiler exists (e.g., `mulle-clang` vs `clang` vs `cc`)
- Handle Windows/MinGW special cases (cl.exe vs gcc)
- Support environment variable overrides (CC, CXX)
- Detect compiler version for capability checks

---

### 2. `mulle-platform flags`

**Purpose**: Generate platform and configuration-appropriate compiler/linker flags.

**Usage:**
```bash
mulle-platform flags [options]

Options:
  --platform <name>        Platform
  --language <name>        Language
  --dialect <name>         Dialect
  --configuration <name>   Debug, Release, Test, RelWithDebInfo (default: Debug)
  --compiler-type <type>   Compiler type (affects flag syntax)
  --type <type>            Flag type: compile, link, or both (default: both)
  --print-env              Output as environment variables (default)
  --print-list             Output as space-separated list
```

**Example Output:**
```bash
$ mulle-platform flags --configuration Debug --language c
CFLAGS='-O0 -g'
CPPFLAGS=''
LDFLAGS=''

$ mulle-platform flags --configuration Release --language c
CFLAGS='-O3 -g -DNDEBUG -DNS_BLOCK_ASSERTIONS'
LDFLAGS='-Wl,-dead_strip'  # darwin-specific

$ mulle-platform flags --configuration Debug --compiler-type msvc
CFLAGS='/Od /Zi /DEBUG /MDd /wd4068'
LDFLAGS='/link /DEBUG'

$ mulle-platform flags --dialect mulle-objc --configuration Test
CFLAGS='-O0 -g -fobjc-tao'
OTHER_CFLAGS='-fobjc-tao'
```

**Flag Categories:**
- Optimization: `-O0`, `-O3`, `/Od`, `/O2`
- Debug symbols: `-g`, `/Zi`
- Preprocessor: `-DNDEBUG`, `/DNDEBUG`
- Warning suppression: `-wd4068` (MSVC)
- Language-specific: `-fobjc-tao` (mulle-objc)
- Linker: `-Wl,--as-needed`, `/link`

---

### 3. `mulle-platform quirks`

**Purpose**: Check for platform-specific behaviors that need special handling.

**Usage:**
```bash
mulle-platform quirks --check <quirk-name>

Quirk Names:
  mingw-needs-link-flag       MinGW needs -link before linker args
  needs-exported-symbols  Darwin needs -Wl,-exported_symbol for dylibs
  windows-needs-dll-path      Windows needs DLL in PATH
  msvc-needs-md-flag          MSVC needs /MD or /MDd
  needs-pic-for-shared        Platform needs -fPIC for shared libs
  supports-rpath              Platform supports -rpath
  
Returns:
  0 if quirk applies to current platform
  1 if quirk does not apply
```

**Example Usage:**
```bash
if mulle-platform quirks --check needs-exported-symbols; then
    LDFLAGS="${LDFLAGS} -Wl,-exported_symbol,_main"
fi
```

---

### 4. `mulle-platform sdk`

**Purpose**: Get SDK paths and information (extends existing functionality).

**Usage:**
```bash
mulle-platform sdk [options]

Options:
  --platform <name>    Platform
  --show-path          Show SDK path (default)
  --show-version       Show SDK version
  --show-frameworks    Show frameworks directory
```

**Example Output:**
```bash
$ mulle-platform sdk --platform darwin --show-path
/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk

$ mulle-platform sdk --platform darwin --show-frameworks
/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/System/Library/Frameworks
```

---

## Implementation Strategy

### Directory Structure

Add to mulle-platform:
```
mulle-platform/
├── src/
│   ├── mulle-platform-compiler.sh    # NEW: Compiler selection
│   ├── mulle-platform-flags.sh       # NEW: Flag generation
│   ├── mulle-platform-quirks.sh      # NEW: Platform quirks
│   └── mulle-platform-sdk.sh         # Enhanced SDK handling
│
└── share/
    └── compiler-db/                   # NEW: Compiler configuration database
        ├── gcc.sh                     # GCC flag mappings
        ├── clang.sh                   # Clang flag mappings
        ├── msvc.sh                    # MSVC flag mappings
        └── mulle-clang.sh             # mulle-clang specifics
```

### Configuration Database

Store compiler-specific knowledge in loadable configs:

```bash
# share/compiler-db/gcc.sh

COMPILER_GCC_DEBUG_FLAGS="-O0 -g"
COMPILER_GCC_RELEASE_FLAGS="-O3 -g -DNDEBUG"
COMPILER_GCC_WARNING_FLAGS="-Wall -Wextra"
COMPILER_GCC_SUPPORTS_SANITIZERS="YES"
COMPILER_GCC_SANITIZER_ADDRESS="-fsanitize=address"
COMPILER_GCC_SANITIZER_THREAD="-fsanitize=thread"

# share/compiler-db/msvc.sh

COMPILER_MSVC_DEBUG_FLAGS="/Od /Zi /DEBUG /MDd"
COMPILER_MSVC_RELEASE_FLAGS="/O2 /MD /DNDEBUG"
COMPILER_MSVC_WARNING_SUPPRESS="/wd4068"  # Unknown pragma
COMPILER_MSVC_SUPPORTS_SANITIZERS="LIMITED"
COMPILER_MSVC_SANITIZER_ADDRESS="/fsanitize=address"  # VS 2019+
```

### Platform-Specific Overrides

```bash
# share/platforms/darwin.sh

PLATFORM_DARWIN_PREFERRED_COMPILER="clang"
PLATFORM_DARWIN_SDK_PATH="$(xcrun --show-sdk-path 2>/dev/null)"
PLATFORM_DARWIN_NEEDS_EXPORTED_SYMBOLS="YES"
PLATFORM_DARWIN_FRAMEWORK_FLAG="-framework"
```

---

## Benefits for mulle-test

### Before (mulle-test-environment.sh ~550 lines)

```bash
test::environment::setup_compiler() {
    case "${language}" in
        c)
            RELEASE_GCC_CFLAGS="-O3 -g -DNDEBUG"
            DEBUG_GCC_CFLAGS="-O0 -g"
            
            case "${platform}" in
                mingw)
                    RELEASE_CL_CFLAGS="-O3 -MD -wd4068 -DNDEBUG"
                    DEBUG_CL_CFLAGS="-Zi -DEBUG -MDd -Od -wd4068"
                ;;
                windows)
                    RELEASE_CL_CFLAGS="/O2 /MD /wd4068 /DNDEBUG"
                    DEBUG_CL_CFLAGS="/Zi /DEBUG /MDd /Od /wd4068"
                ;;
            esac
            # ... 200+ more lines
        ;;
        objc)
            case "${objc_dialect}" in
                mulle-objc)
                    case "${platform}" in
                        mingw)
                            CC="mulle-clang-cl"
                            # ... 50+ more lines
                        ;;
                        darwin)
                            CC="mulle-clang"
                            # ... 30+ more lines
                        ;;
                    esac
                ;;
            esac
            # ... 200+ more lines
        ;;
    esac
}
```

### After (builder plugin ~50 lines)

```bash
# src/plugins/builders/gcc.sh

builder::gcc::build() {
    local srcfile="$1"
    local output="$2"
    local user_flags="$3"
    local diagnostics="$4"
    
    # Get compiler (5 lines instead of 100)
    eval $(mulle-platform compiler \
              --language "${PROJECT_LANGUAGE}" \
              --dialect "${PROJECT_DIALECT}")
    
    # Get flags (5 lines instead of 50)
    eval $(mulle-platform flags \
              --configuration "${OPTION_CONFIGURATION}" \
              --language "${PROJECT_LANGUAGE}")
    
    # Check quirks if needed (2 lines instead of 50)
    if mulle-platform quirks --check needs-pic-for-shared; then
        CFLAGS="${CFLAGS} -fPIC"
    fi
    
    # Just compile (10 lines)
    exekutor ${CC} ${CFLAGS} ${user_flags} \
        -o "${output}" "${srcfile}" 2>&1 | tee "${diagnostics}"
    
    return ${PIPESTATUS[0]}
}
```

**Line Count Reduction:**
- mulle-test-environment.sh: 550 → ~100 lines (80% reduction)
- Builder plugin: Clean, focused, ~50 lines each
- Total: Much simpler and more maintainable

---

## Benefits for Other Tools

### mulle-make

Currently duplicates platform detection. Could use:
```bash
eval $(mulle-platform compiler --language "${LANGUAGE}")
eval $(mulle-platform flags --configuration "${CONFIGURATION}")
```

### mulle-craft

Could use for CMake flag generation:
```bash
CMAKE_C_COMPILER=$(mulle-platform compiler --language c --print-list | \
                   awk '/^CC=/{gsub(/^CC=/,""); print}')
```

### Custom Tools

Any tool needing platform-specific compilation can leverage mulle-platform.

---

## Migration Path

### Phase 1: Implement in mulle-platform (2-3 weeks)
1. Add `compiler` command
2. Add `flags` command  
3. Add `quirks` command
4. Create compiler database configs
5. Test on all platforms

### Phase 2: Update mulle-test (1-2 weeks)
1. Update builder plugins to use mulle-platform
2. Keep fallback to old code for compatibility
3. Test thoroughly

### Phase 3: Deprecate old code (1 week)
1. Mark old functions as deprecated
2. Update documentation
3. Add warnings for direct usage

### Phase 4: Remove old code (next major version)
1. Delete deprecated functions
2. Simplify codebase
3. Update CODEBASE.md

---

## Testing Strategy

### Unit Tests
```bash
# Test compiler selection on all platforms
for platform in linux darwin mingw windows; do
    result=$(mulle-platform compiler --platform "${platform}" --language c)
    # Verify CC is set appropriately
done

# Test flag generation
for config in Debug Release; do
    result=$(mulle-platform flags --configuration "${config}")
    # Verify flags are correct
done
```

### Integration Tests
```bash
# Use mulle-test itself to test
mulle-platform compiler --language c > /tmp/compiler.env
source /tmp/compiler.env
${CC} -o test test.c  # Should work
```

---

## API Stability

Once implemented:
- Commands should remain stable
- Output format should be versioned
- New quirks can be added without breaking existing code
- New compilers can be added to database without code changes

---

## Questions to Resolve

1. **Versioning**: Should mulle-platform version its output format?
   - Proposal: Add `--api-version 1.0` flag

2. **Caching**: Should compiler detection be cached?
   - Proposal: Cache in `~/.mulle/cache/platform/` for performance

3. **User Overrides**: How to allow user customization?
   - Proposal: Check `~/.mulle/etc/platform/compiler-overrides.sh`

4. **Fallback Behavior**: What if mulle-platform isn't available?
   - Proposal: Tools should have minimal fallback (e.g., `CC=${CC:-cc}`)

---

## Success Criteria

- [ ] mulle-test uses mulle-platform for all compiler selection
- [ ] mulle-test code reduced by 50%+ lines
- [ ] All platforms (Linux, macOS, Windows) work correctly
- [ ] Performance is equal or better
- [ ] Documentation is clear and comprehensive
- [ ] Other mulle-* tools can easily adopt

---

## Recommended Implementation Order

### Step 1: Implement mulle-platform Commands (Priority)

**This should be done FIRST, before any mulle-test plugin refactoring.**

**Week 1-2: Core Implementation**
1. Create `src/mulle-platform-compiler.sh`
2. Create `src/mulle-platform-flags.sh`
3. Create `src/mulle-platform-quirks.sh`
4. Create compiler database files (gcc.sh, msvc.sh, clang.sh)
5. Add command routing in main mulle-platform script

**Week 3: Testing & Validation**
1. Test on Linux (gcc, clang)
2. Test on macOS (clang, mulle-clang)
3. Test on Windows (MSVC, MinGW)
4. Verify all output formats

**Week 4: Integration with mulle-test**
1. Update `mulle-test-environment.sh` to use mulle-platform
2. Update `mulle-test-compiler.sh` to use mulle-platform
3. Keep fallback code for backward compatibility
4. Run full mulle-test suite

**Deliverable:** mulle-platform 2.0 with compiler/flags/quirks commands

### Step 2: Simplify mulle-test (Immediate benefit)

**Week 5-6: Cleanup**
1. Remove duplicated platform code from mulle-test
2. Simplify test::environment::setup_compiler (550 → ~150 lines)
3. Update documentation
4. Release mulle-test 7.1.0 (simpler, same features)

**Deliverable:** Simplified mulle-test using mulle-platform

### Step 3: Plugin Architecture (Later, optional)

After mulle-platform migration is stable, THEN consider plugin refactoring:
1. Create plugin infrastructure
2. Extract builder plugins (they'll use mulle-platform!)
3. Extract sanitizer plugins
4. Release mulle-test 8.0.0

## Next Steps

1. ✅ **Get Feedback** on this proposal
2. **Start Implementation** in mulle-platform (see Step 1 above)
3. **Test Incrementally** at each stage
4. **Document** as you go
5. **Release mulle-platform 2.0** first
6. **Update mulle-test** to use it
7. **Consider plugin architecture** later (optional enhancement)

# mulle-platform Changes Required for Sanitizer Support

This document describes the changes needed in `mulle-platform` to support abstract sanitizer flags.

## Overview

`mulle-test` now passes sanitizer flags abstractly to `mulle-platform compile` using `--sanitizer <type>` and `--coverage` flags. The `mulle-platform` tool should translate these into appropriate compiler-specific flags.

## Required Changes to mulle-platform

### 1. Add --sanitizer Flag to compile Command

Add support for `--sanitizer <type>` flag which can be specified multiple times:

```bash
mulle-platform compile --sanitizer address --sanitizer thread ...
```

Supported sanitizer types:
- `address` - Address sanitizer
- `thread` - Thread sanitizer  
- `undefined` - Undefined behavior sanitizer
- `memory` - Memory sanitizer (future)
- `leak` - Leak sanitizer (future)

### 2. Add --coverage Flag to compile Command

Add support for `--coverage` flag for code coverage:

```bash
mulle-platform compile --coverage ...
```

### 3. Compiler-Specific Flag Generation

#### GCC/Clang

For each sanitizer type, generate appropriate flags:

- `--sanitizer address` → `-fsanitize=address`
- `--sanitizer thread` → `-fsanitize=thread`
- `--sanitizer undefined` → `-fsanitize=undefined`
- `--coverage` → `--coverage -fno-inline` (compile) + `-lgcov` (link)

#### MSVC

For MSVC, translate to equivalent flags where available:

- `--sanitizer address` → `/fsanitize=address` (VS 2019+)
- Other sanitizers → silently ignore if not supported
- `--coverage` → silently ignore (not supported by MSVC)

### 4. Implementation Notes

- **Multiple sanitizers**: Some sanitizers are mutually exclusive (e.g., address and thread). The implementation should either:
  - Warn and use only the first specified sanitizer, or
  - Generate flags for all and let the compiler error out
  
- **Compiler support detection**: The implementation should check if the compiler supports the requested sanitizer. If not:
  - **Current requirement**: Silently ignore unsupported sanitizers
  - **Future enhancement**: Could warn if a sanitizer is requested but not supported

- **Linker flags**: Coverage requires both compile and link flags. The implementation should:
  - Add compile flags (e.g., `--coverage`)
  - Add linker flags (e.g., `-lgcov`) when linking

### 5. Example Usage

```bash
# Compile with address sanitizer
mulle-platform compile --platform linux --dialect c --sanitizer address main.c -o main

# Compile with coverage
mulle-platform compile --platform linux --dialect c --coverage main.c -o main

# Compile with multiple sanitizers (if supported)
mulle-platform compile --platform linux --dialect c --sanitizer address --sanitizer undefined main.c -o main
```

### 6. Testing

Test with various compilers:
- GCC (various versions)
- Clang (various versions)
- MSVC (Visual Studio 2019+)
- mulle-clang
- mulle-clang-cl

Ensure:
- Supported sanitizers produce correct flags
- Unsupported sanitizers are silently ignored
- Compiler-specific syntax is correct (e.g., `-fsanitize` vs `/fsanitize`)

## Migration Path

Once `mulle-platform` supports these flags:

1. ✅ `mulle-test` already updated to use `--sanitizer` and `--coverage` flags
2. ⏳ Update `mulle-platform` to handle these flags
3. ⏳ Test the integration between both tools
4. ⏳ Remove fallback flag generation from `mulle-test` (currently kept for compatibility)

## Backward Compatibility

`mulle-test` currently keeps a fallback in the `--` section for coverage linker flags (`-lgcov`). This can be removed once `mulle-platform` properly handles the `--coverage` flag for both compilation and linking.
