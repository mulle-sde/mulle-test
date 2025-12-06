# mulle-test Refactoring Plan: Plugin-Based Architecture

## Problem Statement

The current mulle-test codebase has grown complex with tightly coupled responsibilities:
- Test execution logic mixed with compilation
- Sanitizer configuration scattered across multiple modules
- Platform-specific code intertwined with core logic
- Difficult to add new build systems or sanitizers

## Vision

Refactor mulle-test into a clean, plugin-based architecture with three primary components:

1. **Core Runner** - The essence of testing: execute, capture, compare
2. **Builder Plugins** - Compile source to executable (cmake, gcc, meson, etc.)
3. **Sanitizer Plugins** - Add memory/behavior checking layers

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                     mulle-test                          │
│                  (Main Entry Point)                     │
└───────────────────────┬─────────────────────────────────┘
                        │
        ┌───────────────┼───────────────┐
        │               │               │
        ▼               ▼               ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│ Core Runner  │ │   Builder    │ │  Sanitizer   │
│              │ │   Plugins    │ │   Plugins    │
└──────────────┘ └──────────────┘ └──────────────┘
                        │               │
           ┌────────────┼────────┐      │
           │            │        │      │
           ▼            ▼        ▼      ▼
      ┌────────┐  ┌────────┐ ┌────┐ ┌─────┐
      │  GCC   │  │ CMake  │ │Meson│ │ASan │
      │ Plugin │  │ Plugin │ │ ... │ │ ... │
      └────────┘  └────────┘ └────┘ └─────┘
```

## Core Components

### 1. Core Runner (`mulle-test-runner.sh`)

**Responsibilities:**
- Execute test binary
- Feed stdin from file
- Capture stdout/stderr
- Check return code
- Compare outputs with expected files
- Report results

**Interface:**
```bash
test::runner::execute(
    executable,      # Path to binary
    stdin_file,      # Input file (or "-" for none)
    stdout_file,     # Expected stdout (or "-" for none)
    stderr_file,     # Expected stderr (or "-" for none)
    errors_file,     # Expected error patterns (or "-" for none)
    timeout,         # Timeout in seconds
    env_vars         # Array of environment variables
)
```

**Does NOT:**
- Know about compilation
- Know about sanitizers
- Know about build systems

### 2. Builder Plugin Interface

**Location:** `src/plugins/builders/`

**Plugin Structure:**
```bash
# src/plugins/builders/gcc.sh

# Plugin metadata
BUILDER_NAME="gcc"
BUILDER_VERSION="1.0.0"
BUILDER_EXTENSIONS="c:m:cpp:cxx"  # File extensions this builder handles

# Can this builder handle the given file?
builder::gcc::can_build() {
    local srcfile="$1"
    # Return 0 if can build, 1 otherwise
}

# Build the source file into an executable
builder::gcc::build() {
    local srcfile="$1"       # Source file to compile
    local output="$2"        # Output executable path
    local flags="$3"         # Additional compiler flags
    local diagnostics="$4"   # File to write compiler output
    # Return 0 on success, non-zero on failure
}

# Check compiler diagnostics
builder::gcc::check_diagnostics() {
    local diagnostics="$1"   # Compiler output file
    local expected="$2"      # Expected diagnostics file (or "-")
    local srcfile="$3"       # Source file name (for error messages)
    # Return 0 if diagnostics match expectations
}
```

**Plugin Examples:**
- `gcc.sh` - Direct GCC compilation
- `cmake.sh` - CMake-based builds
- `meson.sh` - Meson builds
- `make.sh` - Makefile-based builds
- `clang.sh` - Clang-specific compilation

### 3. Sanitizer Plugin Interface

**Location:** `src/plugins/sanitizers/`

**Plugin Structure:**
```bash
# src/plugins/sanitizers/asan.sh

# Plugin metadata
SANITIZER_NAME="address"
SANITIZER_PLATFORMS="linux:darwin"  # Supported platforms

# Get compiler flags needed for this sanitizer
sanitizer::asan::get_compile_flags() {
    echo "-fsanitize=address"
}

# Get linker flags needed for this sanitizer
sanitizer::asan::get_link_flags() {
    echo "-fsanitize=address"
}

# Get environment variables for runtime
sanitizer::asan::get_env_vars() {
    # Return array of VAR=value pairs
    echo "ASAN_OPTIONS=halt_on_error=1"
}

# Wrap the test command with sanitizer runner if needed
sanitizer::asan::wrap_command() {
    local executable="$1"
    # Return command to run (could prepend valgrind, gdb, etc.)
    echo "${executable}"
}

# Check if this sanitizer is compatible with platform
sanitizer::asan::is_supported() {
    # Return 0 if supported on current platform
}
```

**Plugin Examples:**
- `asan.sh` - Address Sanitizer
- `tsan.sh` - Thread Sanitizer
- `ubsan.sh` - Undefined Behavior Sanitizer
- `valgrind.sh` - Valgrind wrapper
- `testallocator.sh` - mulle-testallocator
- `gmalloc.sh` - macOS gmalloc
- `glibc.sh` - Linux glibc checks
- `coverage.sh` - Code coverage
- `gdb.sh` - GDB debugger wrapper

### 4. Plugin Manager (`mulle-test-plugin.sh`)

**Responsibilities:**
- Discover available plugins
- Load plugins on demand
- Validate plugin interfaces
- Select appropriate builder for source file
- Combine multiple sanitizers

**Interface:**
```bash
# Load all plugins from a directory
test::plugin::load_all_from_dir() {
    local dir="$1"
    local type="$2"  # "builder" or "sanitizer"
}

# Find builder for a source file
test::plugin::find_builder() {
    local srcfile="$1"
    # Returns builder name or empty
}

# Get combined sanitizer flags
test::plugin::get_sanitizer_compile_flags() {
    local sanitizers="$1"  # Colon-separated list
}

test::plugin::get_sanitizer_env_vars() {
    local sanitizers="$1"
}

test::plugin::wrap_with_sanitizers() {
    local executable="$1"
    local sanitizers="$2"
}
```

## File Organization

```
mulle-test/
├── mulle-test                          # Main entry point
├── mulle-timeout                       # Timeout utility
├── src/
│   ├── mulle-test-runner.sh           # NEW: Core runner (execute & compare)
│   ├── mulle-test-plugin.sh           # NEW: Plugin manager
│   ├── mulle-test-environment.sh      # Platform setup (simplified)
│   ├── mulle-test-init.sh             # Project initialization
│   ├── mulle-test-craft.sh            # mulle-sde integration
│   ├── mulle-test-locate.sh           # Test discovery
│   ├── mulle-test-logging.sh          # Logging utilities
│   └── mulle-test-regex.sh            # Pattern matching
│   │
│   ├── plugins/
│   │   ├── builders/
│   │   │   ├── gcc.sh                 # NEW: GCC builder
│   │   │   ├── cmake.sh               # NEW: CMake builder
│   │   │   ├── meson.sh               # NEW: Meson builder
│   │   │   └── clang.sh               # NEW: Clang builder
│   │   │
│   │   └── sanitizers/
│   │       ├── asan.sh                # NEW: Address sanitizer
│   │       ├── tsan.sh                # NEW: Thread sanitizer
│   │       ├── ubsan.sh               # NEW: UB sanitizer
│   │       ├── valgrind.sh            # NEW: Valgrind
│   │       ├── testallocator.sh       # NEW: Test allocator
│   │       ├── gmalloc.sh             # NEW: macOS gmalloc
│   │       ├── coverage.sh            # NEW: Coverage
│   │       └── gdb.sh                 # NEW: GDB wrapper
│   │
│   └── mulle-sde/                     # Extension system (unchanged)
│
└── dox/                                # Documentation
```

## Leveraging mulle-platform

### Problem

The `test::environment::setup_compiler()` function is 200+ lines of platform-specific code that duplicates logic that should live in `mulle-platform`. This includes:
- Compiler selection (CC, CXX)
- Platform-specific flags (CFLAGS, LDFLAGS)
- Compiler detection (GCC vs Clang vs MSVC)
- Platform quirks (MinGW, Darwin SDK paths, etc.)

### Solution: Delegate to mulle-platform

**Current approach:**
```bash
# In mulle-test-environment.sh (200+ lines)
test::environment::setup_compiler() {
    case "${platform}" in
        mingw)
            CC="${CC:-cl}"
            CFLAGS="-MD -wd4068"
            # ... 50 more lines ...
        ;;
        darwin)
            if [ mulle-objc ]; then
                CC="mulle-clang"
                # ... 30 more lines ...
            fi
        ;;
        # ... 100 more lines ...
    esac
}
```

**Proposed approach:**
```bash
# In builder plugins (e.g., gcc.sh)
builder::gcc::build() {
    local srcfile="$1"
    local output="$2"
    local flags="$3"
    
    # Get compiler from mulle-platform
    eval $(mulle-platform compiler --language c)
    # Sets: CC, CXX, CFLAGS_RELEASE, CFLAGS_DEBUG, etc.
    
    # Build with platform-appropriate compiler
    exekutor ${CC} ${CFLAGS_DEBUG} ${flags} -o "${output}" "${srcfile}"
}
```

### What Should Move to mulle-platform

1. **Compiler Discovery**
   ```bash
   mulle-platform compiler --language c --dialect objc --compiler-type clang
   # Output: CC=mulle-clang CXX=mulle-clang++
   ```

2. **Standard Flags**
   ```bash
   mulle-platform flags --configuration Debug --language c
   # Output: CFLAGS="-O0 -g" LDFLAGS="..."
   ```

3. **Platform Quirks**
   ```bash
   mulle-platform quirks --check mingw-cl-linking
   # Returns: 0 if needs special handling, 1 otherwise
   ```

4. **SDK Paths** (already partially there)
   ```bash
   mulle-platform sdk-path --platform darwin
   # Output: /Applications/Xcode.app/.../MacOSX.sdk
   ```

### Benefits

- **Single Source of Truth**: One place for platform knowledge
- **Reusability**: Other mulle-* tools can use same logic
- **Maintainability**: Update platform quirks in one place
- **Testability**: mulle-platform can be tested independently
- **Simplification**: mulle-test focuses on testing, not platform detection

### Builder Plugin Integration

Each builder plugin would use mulle-platform:

```bash
# src/plugins/builders/gcc.sh

builder::gcc::build() {
    # Delegate compiler selection to mulle-platform
    local compiler_env
    compiler_env=$(mulle-platform compiler \
                      --language "${PROJECT_LANGUAGE}" \
                      --dialect "${PROJECT_DIALECT}")
    eval "${compiler_env}"
    
    # Delegate flag generation to mulle-platform  
    local flags_env
    flags_env=$(mulle-platform flags --configuration "${OPTION_CONFIGURATION}")
    eval "${flags_env}"
    
    # Now just compile
    exekutor ${CC} ${CFLAGS} "$@" -o "${output}" "${srcfile}"
}
```

### Gradual Migration

1. **Phase 1**: Add new commands to mulle-platform
   - `mulle-platform compiler`
   - `mulle-platform flags`
   - Keep existing mulle-test code working

2. **Phase 2**: Update builder plugins to use mulle-platform
   - Start with gcc.sh plugin
   - Verify all platforms work

3. **Phase 3**: Remove duplicated code from mulle-test
   - Delete platform-specific compiler setup
   - Simplify test::environment::setup_compiler

4. **Phase 4**: Extend for other mulle-* tools
   - mulle-make can use same platform logic
   - mulle-craft can use same platform logic

## Migration Strategy

### Phase 1: Create Plugin Infrastructure
1. Create `mulle-test-plugin.sh` with plugin loading
2. Create plugin directory structure
3. Define plugin interfaces

### Phase 2: Extract Core Runner
1. Create `mulle-test-runner.sh` from `mulle-test-execute.sh`
2. Strip out all compilation logic
3. Strip out all sanitizer setup
4. Focus on: execute → capture → compare

### Phase 3: Create Builder Plugins
1. Extract GCC compilation from `mulle-test-compiler.sh` → `gcc.sh`
2. Extract CMake logic from `mulle-test-cmake.sh` → `cmake.sh`
3. Create Meson plugin (new capability)
4. Each plugin handles its own diagnostics checking

### Phase 4: Create Sanitizer Plugins
1. Extract address sanitizer logic → `asan.sh`
2. Extract thread sanitizer logic → `tsan.sh`
3. Extract valgrind logic → `valgrind.sh`
4. Extract testallocator logic → `testallocator.sh`
5. Extract coverage logic → `coverage.sh`
6. Extract platform-specific sanitizers (gmalloc, glibc)

### Phase 5: Update Test Orchestration
1. Update `mulle-test-run.sh` to use plugin manager
2. Replace direct compiler calls with builder plugins
3. Replace direct sanitizer setup with sanitizer plugins
4. Maintain backward compatibility during transition

### Phase 6: Cleanup
1. Remove deprecated code from old modules
2. Update documentation
3. Add plugin development guide

## Backward Compatibility

During migration:
- Keep existing flags working (`--sanitize-address`, `--coverage`, etc.)
- Map old flags to new plugin selections
- Deprecation warnings for direct use of old modules

## Benefits

### Maintainability
- Clear separation of concerns
- Each plugin is self-contained
- Easy to understand each component
- Reduced cognitive load

### Extensibility
- Add new builders without touching core
- Add new sanitizers without touching core
- Community can contribute plugins
- Platform-specific plugins possible

### Testability
- Each plugin can be tested independently
- Mock plugins for testing
- Core runner has minimal dependencies

### Flexibility
- Mix and match sanitizers
- Custom builder configurations
- Platform-specific optimizations
- User-provided plugins

## Example Usage After Refactoring

### Simple Test Run
```bash
# Internally:
# 1. Plugin manager finds gcc.sh can build foo.c
# 2. gcc.sh compiles foo.c → foo.exe
# 3. Core runner executes foo.exe and checks output
mulle-test run test/foo.c
```

### With Sanitizers
```bash
# Internally:
# 1. gcc.sh gets compile flags from asan.sh + coverage.sh
# 2. gcc.sh compiles with combined flags
# 3. asan.sh provides environment vars
# 4. Core runner executes with sanitizer env
mulle-test run --sanitize-address --coverage test/foo.c
```

### Custom Builder
```bash
# User creates src/plugins/builders/custom.sh
# Plugin manager automatically discovers it
mulle-test run --builder custom test/foo.xyz
```

## Plugin Development Guide

### Creating a Builder Plugin

1. Create file in `src/plugins/builders/mybuilder.sh`
2. Implement required functions:
   - `builder::mybuilder::can_build()`
   - `builder::mybuilder::build()`
   - `builder::mybuilder::check_diagnostics()`
3. Set metadata variables:
   - `BUILDER_NAME`
   - `BUILDER_VERSION`
   - `BUILDER_EXTENSIONS`

### Creating a Sanitizer Plugin

1. Create file in `src/plugins/sanitizers/mysanitizer.sh`
2. Implement required functions:
   - `sanitizer::mysanitizer::get_compile_flags()`
   - `sanitizer::mysanitizer::get_link_flags()`
   - `sanitizer::mysanitizer::get_env_vars()`
   - `sanitizer::mysanitizer::wrap_command()`
   - `sanitizer::mysanitizer::is_supported()`
3. Set metadata variables:
   - `SANITIZER_NAME`
   - `SANITIZER_PLATFORMS`

## Testing the Refactoring

1. Run existing test suite with new architecture
2. Verify all sanitizer combinations work
3. Test all builder types (gcc, cmake)
4. Test platform-specific features
5. Performance benchmarks (should be similar or better)

## Success Criteria

- [ ] All existing tests pass with new architecture
- [ ] New plugin can be added in < 50 lines of code
- [ ] Core runner is < 500 lines (currently ~1000+ across modules)
- [ ] Each plugin is self-contained and < 300 lines
- [ ] Zero duplication of sanitizer logic
- [ ] Documentation clearly explains plugin development

## Future Possibilities

### Additional Builders
- Rust (cargo)
- Go (go build)
- Zig (zig build)
- Custom build systems

### Additional Sanitizers
- Memory Sanitizer (MSan)
- DataFlow Sanitizer (DFSan)
- Hardware-assisted (Intel MPX)
- Custom memory checkers

### Plugin Repository
- Community-contributed plugins
- Plugin versioning
- Plugin dependencies
- Plugin marketplace

## Recommended First Step: Move to mulle-platform

**Priority:** Start with moving platform-specific code to mulle-platform BEFORE the plugin refactoring.

**Why this order:**
- ✅ Immediate simplification of mulle-test
- ✅ Benefits all mulle-* tools immediately
- ✅ Smaller, focused changes with lower risk
- ✅ Creates cleaner foundation for later plugin refactoring
- ✅ Can be done incrementally with backward compatibility

**What to move first:**
1. Compiler selection logic → `mulle-platform compiler`
2. Flag generation → `mulle-platform flags`
3. Platform quirks → `mulle-platform quirks`
4. SDK path handling → Enhanced `mulle-platform sdk`

**See:** [MULLE-PLATFORM-PROPOSAL.md](MULLE-PLATFORM-PROPOSAL.md) for detailed implementation plan.

## Next Steps (Revised Order)

### Phase 1: mulle-platform Enhancement (FIRST - 3-4 weeks)
1. **Implement in mulle-platform:**
   - Add `mulle-platform compiler` command
   - Add `mulle-platform flags` command
   - Add `mulle-platform quirks` command
   - Create compiler database (gcc.sh, msvc.sh, etc.)

2. **Update mulle-test to use mulle-platform:**
   - Replace `test::environment::setup_compiler()` with mulle-platform calls
   - Simplify flag building with mulle-platform
   - Keep fallback code for compatibility

3. **Test thoroughly:**
   - Verify all platforms work (Linux, macOS, Windows)
   - Run existing mulle-test suite
   - Performance benchmarks

4. **Reduce mulle-test by ~400 lines** (from 550 → 150 in environment.sh)

### Phase 2: Plugin Architecture (AFTER mulle-platform - 6-8 weeks)
1. Create plugin infrastructure
2. Extract core runner
3. Create builder plugins (using mulle-platform!)
4. Create sanitizer plugins
5. Update test orchestration
6. Cleanup and document

## Timeline Estimate (Revised)

### Near Term (4-6 weeks)
- **Week 1-2:** Implement mulle-platform commands
- **Week 3-4:** Update mulle-test to use mulle-platform
- **Week 5-6:** Test, document, release mulle-platform 2.0
- **Result:** mulle-test simplified by 50%, other tools benefit

### Medium Term (8-12 weeks after Phase 1)
- **Week 1-2:** Plugin infrastructure
- **Week 3-4:** Core runner + builder plugins
- **Week 5-6:** Sanitizer plugins
- **Week 7-8:** Integration and testing
- **Week 9-10:** Documentation and release
- **Result:** mulle-test 8.0.0 with full plugin architecture

**Total: ~4-6 weeks for mulle-platform migration, then 8-12 weeks for full plugin refactoring**
