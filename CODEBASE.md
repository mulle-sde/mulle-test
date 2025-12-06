# mulle-test Codebase Documentation

## Overview

**mulle-test** is a sophisticated test framework for C and Objective-C projects that operates on a compile-execute-diff workflow. It's designed to be platform-independent (Linux, macOS, Windows/MinGW, BSD, SunOS) and integrates deeply with the mulle-sde (Software Development Environment) ecosystem.

### Core Philosophy

- **Self-contained test projects**: Tests are independent mulle-sde projects
- **Output-based verification**: Tests verify correctness by comparing stdout/stderr against expected files
- **Zero-assertion testing**: Uses `mulle_printf` output comparison instead of traditional assertions
- **Sanitizer integration**: Built-in support for address, thread, undefined behavior sanitizers, valgrind, and custom allocators

## Architecture

### High-Level Structure

```
mulle-test/
├── mulle-test              # Main entry point (Bash script)
├── mulle-timeout           # Timeout wrapper for long-running tests
├── src/                    # Core implementation modules
│   ├── mulle-test-*.sh     # Feature-specific modules
│   └── mulle-sde/          # mulle-sde extensions and runtimes
├── dox/                    # Documentation
└── bin/                    # Installer scripts
```

### Key Components

1. **Main Entry Point** (`mulle-test`)
   - Command dispatcher
   - Flag parsing and sanitizer configuration
   - Environment setup orchestration

2. **Core Modules** (src/)
   - `mulle-test-run.sh`: Test discovery, execution, and orchestration
   - `mulle-test-execute.sh`: Low-level test execution and output verification
   - `mulle-test-compiler.sh`: C/Objective-C compilation with sanitizer support
   - `mulle-test-environment.sh`: Platform-specific environment setup
   - `mulle-test-craft.sh`: Build system integration (via mulle-sde)
   - `mulle-test-init.sh`: Test project initialization

3. **Extension System** (src/mulle-sde/)
   - Test runtime configurations
   - Language-specific templates
   - Demo projects

## Core Workflow

### Test Execution Flow

```
┌─────────────────┐
│  mulle-test run │
└────────┬────────┘
         │
         ├──> 1. Locate test directory
         │
         ├──> 2. Setup environment (platform, compiler, sanitizers)
         │
         ├──> 3. Build dependencies if needed (mulle-sde craft)
         │
         ├──> 4. Discover test files (*.c, *.m, *.sh, etc.)
         │
         ├──> 5. For each test:
         │    ├──> Compile test file (if needed)
         │    ├──> Execute with stdin redirection
         │    ├──> Capture stdout/stderr
         │    └──> Compare with expected files
         │
         └──> 6. Report results
```

### Test File Anatomy

```
test/
├── example.c              # Test source code
├── example.stdout         # Expected standard output
├── example.stderr         # Expected standard error (optional)
├── example.stdin          # Input to feed test (optional)
├── example.args           # Command-line arguments (optional)
├── example.environment    # Environment variables (optional)
├── example.errors         # Expected error patterns (optional)
├── example.ccdiag         # Expected compiler diagnostics (optional)
├── example.cat            # Custom output processor (optional)
└── example.diff           # Custom diff command (optional)
```

## Key Modules Deep Dive

### 1. mulle-test-run.sh

**Purpose**: Test orchestration and execution management

**Key Functions**:
- `test::run::main()`: Entry point, parses options
- `test::run::all_tests()`: Scans directories and runs all tests
- `test::run::scan_directory()`: Recursive test discovery
- `test::run::_run()`: Individual test execution wrapper
- `test::run::c()`, `test::run::m()`, `test::run::cmake()`: Language-specific runners

**Features**:
- Parallel test execution (default) or serial mode
- Test file pattern matching by extension
- Sanitizer configuration per test
- Environment file loading
- Success tracking for reruns

### 2. mulle-test-execute.sh

**Purpose**: Low-level test execution and output verification

**Key Functions**:
- `test::execute::run()`: Main execution wrapper
- `test::execute::a_out()`: Execute compiled binary with environment setup
- `test::execute::check_output()`: Compare actual vs expected output
- `mulle_diff()`: Platform-independent diff wrapper

**Features**:
- Dynamic library path setup (DYLD_LIBRARY_PATH, LD_LIBRARY_PATH, PATH)
- Sanitizer environment variable injection
- Timeout support via mulle-timeout
- Binary vs text output handling
- Whitespace difference detection

### 3. mulle-test-compiler.sh

**Purpose**: C/Objective-C compilation with sanitizer integration

**Key Functions**:
- `test::compiler::run()`: Main compilation entry point
- `test::compiler::r_c_commandline()`: Build compiler command line
- `test::compiler::r_c_sanitizer_flags()`: Generate sanitizer flags
- `test::compiler::check_output()`: Verify compilation diagnostics
- `test::compiler::suggest_debugger_commandline()`: Generate GDB command for debugging

**Sanitizer Support**:
- Address sanitizer (`-fsanitize=address`)
- Thread sanitizer (`-fsanitize=thread`)
- Undefined behavior sanitizer (`-fsanitize=undefined`)
- Coverage (`--coverage`)
- Valgrind integration
- Custom test allocator (mulle-testallocator)

### 4. mulle-test-environment.sh

**Purpose**: Platform and compiler environment configuration

**Key Functions**:
- `test::environment::setup_compiler()`: Configure CC, CXX, flags per platform
- `test::environment::setup_execution_platform()`: Set platform-specific execution settings
- `test::environment::r_get_environmentfile()`: Find platform-specific config files
- `test::environment::setup_development_environment()`: Complete environment setup

**Platform Support**:
- **Linux**: Full support with glibc memory checking
- **macOS**: Full support with gmalloc, special handling for mulle-clang
- **Windows/MinGW**: MSVC (cl.exe) and MinGW GCC support
- **BSD/SunOS**: Basic support

### 5. mulle-test-craft.sh

**Purpose**: Build system integration and header generation

**Key Functions**:
- `test::craft::main()`: Orchestrate building via mulle-sde
- `test::craft::emit_include_h()`: Generate `include.h` with all dependency headers
- `test::craft::emit_import_h()`: Generate `import.h` for Objective-C
- `test::craft::postprocess()`: Post-build header generation

**Features**:
- Automatic dependency header aggregation
- Language/dialect-specific includes
- Configuration-aware (Debug/Release)
- Sanitizer flag forwarding to build system

### 6. mulle-test-init.sh

**Purpose**: Initialize test directory structure

**Key Functions**:
- `test::init::main()`: Create test project
- `test::init::execute_script()`: Run initialization hooks

**Features**:
- Inherits language/dialect from parent project
- Creates mulle-sde project structure
- Configures test-specific extensions
- Sets up sourcetree dependencies

## mulle-timeout Utility

**Purpose**: Reliable timeout wrapper that handles environment variables

**Why needed**: System `timeout` command fails with `LD_PRELOAD=... command` syntax due to library resolution issues before command execution.

**Implementation**:
- Spawns command in background
- Monitors command PID
- Sends signal after timeout period
- Handles cleanup on early termination

## Extension System (mulle-sde Integration)

### Test Runtimes

Located in `src/mulle-sde/`, these define test project templates:

1. **base-test-runtime**: Core test functionality
   - Minimal mulle-test environment
   - No language-specific dependencies

2. **c-test-runtime**: C language testing
   - Inherits from base-test-runtime
   - Adds C-specific dependencies (mulle-core, mulle-concurrent, etc.)
   - Sourcetree configuration for C libraries

3. **objc-test-runtime**: Objective-C testing
   - Inherits from c-test-runtime
   - Adds MulleObjC framework dependencies
   - Special leak and crash checking support

### Project Types

- **c-test-library**: Testing C libraries
- **c-test-executable**: Testing C executables
- **objc-test-library**: Testing Objective-C libraries
- **objc-test-executable**: Testing Objective-C executables

## Test File Discovery

### Extension Matching

Tests are discovered by file extension:
- **C**: `.c`
- **Objective-C**: `.m`, `.aam` (mulle-objc TAO files)
- **C++**: `.cpp`, `.cxx`
- **CMake**: `CMakeLists.txt` (in test directories)
- **Shell**: `.sh`
- **Executable**: `.args` (runs pre-built binary)
- **Custom**: `.run` (custom runner script)

### Directory Scanning

```bash
test/
├── 00-basic/           # Numeric prefix for ordering
│   ├── hello.c
│   └── hello.stdout
├── 10-memory/
│   ├── leak_test.m
│   └── leak_test.stdout
└── 20-integration/
    ├── full_test.c
    └── full_test.stdout
```

- Ignores: `_*`, `addiction`, `bin`, `build`, `kitchen`, `dependency`, etc.
- Processes in alphabetical order
- Numeric prefixes for explicit ordering

## Auxiliary Files

### File Resolution Hierarchy

For a test named `example.c`, files are searched in this order:

1. `example.<ext>.${MULLE_UNAME}.${MULLE_ARCH}` (e.g., `example.stdout.linux.x86_64`)
2. `example.<ext>.${MULLE_UNAME}` (e.g., `example.stdout.linux`)
3. `example.<ext>.${MULLE_ARCH}` (e.g., `example.stdout.x86_64`)
4. `example.<ext>` (e.g., `example.stdout`)
5. `default.<ext>.${MULLE_UNAME}.${MULLE_ARCH}`
6. `default.<ext>.${MULLE_UNAME}`
7. `default.<ext>.${MULLE_ARCH}`
8. `default.<ext>`

### Special Files

- **`.no-sanitizers`**: Disables all sanitizers for this test
- **`.no-<sanitizer>`**: Disables specific sanitizer (e.g., `.no-valgrind`)
- **`no-mulle-test`**: Skip this directory entirely
- **`CMakeLists.txt.ignore`**: Ignore CMake build in favor of other method
- **`runner`**: Custom executable to run instead of compiled test

## Sanitizer System

### Supported Sanitizers

Sanitizers are colon-separated values in `SANITIZER` variable:

```bash
SANITIZER="address:coverage"           # Multiple sanitizers
SANITIZER="valgrind:testallocator"     # Combination
SANITIZER="gmalloc:testallocator"      # macOS specific
```

### Platform-Specific Defaults

**macOS (mulle-objc)**:
```bash
SANITIZER="gmalloc:testallocator"
```

**Linux (mulle-objc)**:
```bash
SANITIZER="glibc:testallocator"
```

**Generic**:
```bash
SANITIZER="testallocator"
```

### Sanitizer Implementation

1. **Compile-time flags** (`test::compiler::r_c_sanitizer_flags()`)
   - Address: `-fsanitize=address`
   - Thread: `-fsanitize=thread`
   - Undefined: `-fsanitize=undefined`
   - Coverage: `--coverage -fno-inline`

2. **Link-time flags** (`test::compiler::r_ld_sanitizer_flags()`)
   - Coverage: `-lgcov`

3. **Runtime environment** (`test::compiler::r_env_sanitizer_flags()`)
   - ObjC Coverage: `MULLE_OBJC_COVERAGE=YES`
   - Valgrind: `MULLE_OBJC_PEDANTIC_EXIT=YES`

4. **Execution wrappers**:
   - GDB: Interactive debugging
   - Valgrind: `valgrind -q --error-exitcode=77 --leak-check=full ...`
   - Test allocator: `LD_PRELOAD` or `DYLD_INSERT_LIBRARIES`

## Output Verification

### Comparison Process

1. **Execute test** → capture stdout/stderr to temp files
2. **Process output** through optional `.cat` script (for normalization)
3. **Compare** using diff (or custom `.diff` script)
4. **Whitespace handling**:
   - Default: Warning on whitespace-only differences
   - `MULLE_TEST_WHITESPACE_DIFFERENCES=ignore`: Silent
   - `MULLE_TEST_WHITESPACE_DIFFERENCES=warn`: Warning (default)
   - `MULLE_TEST_WHITESPACE_DIFFERENCES=error`: Failure

### Return Codes

```bash
RVAL_INTERNAL_ERROR=1        # Internal mulle-test bug
RVAL_FAILURE=2               # Test failed
RVAL_OUTPUT_DIFFERENCES=3    # Output mismatch
RVAL_EXPECTED_FAILURE=4      # Expected failure (from .errors file)
RVAL_IGNORED_FAILURE=5       # Ignored failure
```

### Error File Behavior

If `example.errors` exists:
- Test **must** return non-zero exit code
- Each line in `.errors` is a grep pattern
- Test passes if all patterns match stderr

## Platform-Specific Behavior

### Library Loading

**macOS**:
```bash
DYLD_LIBRARY_PATH="${dependency}/lib"
DYLD_FRAMEWORK_PATH="${dependency}/Frameworks"
DYLD_INSERT_LIBRARIES="${testallocator}"
```

**Linux**:
```bash
LD_LIBRARY_PATH="${dependency}/lib"
LD_PRELOAD="${testallocator}"
```

**Windows/MinGW**:
```bash
PATH="${dependency}/bin:${dependency}/lib:${PATH}"
```

### Compiler Detection

- **MSVC (cl.exe)**: Special flag handling (`/D`, `/MD`, `/link`)
- **GCC/Clang**: Standard flags (`-D`, `-O`, `-fsanitize`)
- **mulle-clang**: Objective-C TAO support (`-fobjc-tao`)

## Build System Integration

### Header Generation

mulle-test auto-generates convenience headers:

**include.h** (C):
```c
#ifndef PROJECT_NAME_TEST_INCLUDE_H__
#define PROJECT_NAME_TEST_INCLUDE_H__

// Auto-generated by mulle-test craft
#include <dependency/dependency.h>
#include <another-lib/another-lib.h>
// ... all dependency headers

#endif
```

**import.h** (Objective-C):
```objc
// Auto-generated by mulle-test craft
#include "include.h"

#import <MulleObjC/MulleObjC.h>
#import <Foundation/Foundation.h>
// ... all ObjC framework headers
```

### Dependency Management

Tests link against libraries built by mulle-sde:
- **Dynamic linking** (default): Shared libraries in `dependency/lib/`
- **Standalone mode** (`--standalone`): Static libraries, minimal runtime
- **Library order**: Computed via `test::linkorder::r_get_link_command()`

## Common Patterns

### Basic Test

```c
// test/basic.c
#include "include.h"

int main(void)
{
   mulle_printf("Hello World\n");
   return 0;
}
```

```bash
# test/basic.stdout
Hello World
```

### Test with Arguments

```bash
# test/args_test.args
--verbose --count 5
```

### Test with Input

```bash
# test/stdin_test.stdin
line 1
line 2
line 3
```

### Expected Failure Test

```bash
# test/error_test.errors
^Error: Invalid argument
failed assertion
```

### Platform-Specific Test

```bash
# test/platform.stdout.linux
Linux output

# test/platform.stdout.darwin
macOS output
```

### Custom Output Processing

```bash
#!/bin/bash
# test/sorted.cat
# Sort output to handle non-deterministic ordering
sort
```

## Development Workflow

### Quick Test Iteration

```bash
# Run single test without rebuild
mulle-test run --reuse-exe test/my_test.c

# Build and run (crun = craft + run)
mulle-test crun test/my_test.c

# Clean build and run
mulle-test --no-clean crun test/my_test.c
```

### Debugging Failed Tests

```bash
# Run with GDB
mulle-test run --gdb test/failing.c

# Run with address sanitizer
mulle-test run --sanitize-address test/failing.c

# Keep executable for manual debugging
mulle-test run --keep-exe test/failing.c
# Then: ./test/failing.exe < test/failing.stdin
```

### Creating Expected Output

```bash
# Generate .stdout from test output (USE CAREFULLY!)
mulle-test run --golden-stdout test/new_test.c
```

### Coverage Analysis

```bash
# Run with coverage
mulle-test run --coverage

# Generate coverage report
mulle-test coverage show
```

## Code Organization Principles

### Module Naming Convention

```bash
<tool>::<module>::<function>

Examples:
test::run::main
test::execute::run
test::compiler::r_c_commandline
```

### Return Value Convention

- Functions starting with `r_` return values in `RVAL` global variable
- Non-zero exit codes indicate errors
- Use `_internal_fail` for assertion-like checks

### Logging Levels

```bash
log_entry      # Function entry (trace level)
log_debug      # Debug information
log_fluff      # Verbose details
log_verbose    # Normal verbose output
log_info       # Important information
log_warning    # Warnings
log_error      # Errors
fail           # Fatal error with exit
```

## Environment Variables

### User-Facing

- `MULLE_TEST_DIR`: Test directory name (default: "test")
- `MULLE_TEST_OBJC_DIALECT`: Objective-C dialect ("mulle-objc" or "apple")
- `MULLE_TEST_CRAFT_BEFORE_RUN`: Auto-craft before run
- `MULLE_TEST_WHITESPACE_DIFFERENCES`: How to handle whitespace diffs
- `MULLE_TEST_RUN_TIMEOUT`: Test execution timeout in seconds (default: 360)
- `PROJECT_DIALECT`: Test dialect ("c" or "objc")
- `PROJECT_LANGUAGE`: Test language
- `PROJECT_EXTENSIONS`: Test file extensions
- `TEST_PROJECT_NAME`: Parent project being tested

### Internal

- `MULLE_TEST_ENVIRONMENT`: Marks test environment active
- `MULLE_TEST_VAR_DIR`: Variable data directory
- `MULLE_TEST_SUCCESS_FILE`: Tracks successful tests for reruns
- `MULLE_TEST_EXECUTABLE`: Pre-built executable to test
- `SANITIZER`: Active sanitizer configuration
- `LINK_COMMAND`: Library link order
- `EXE_EXTENSION`: Platform executable extension
- `SHAREDLIB_EXTENSION`: Platform shared library extension

## Testing mulle-test Itself

mulle-test is self-testing and uses its own framework. Key considerations:

1. **Bootstrapping**: Uses mulle-bashfunctions for core utilities
2. **Cross-platform CI**: GitHub Actions for Linux/macOS, manual Windows testing
3. **Version management**: CMake-based versioning

## Future Directions

### Potential Improvements

1. **Better parallel testing**: More robust job control
2. **Test discovery optimization**: Caching and incremental runs
3. **Enhanced coverage**: Integration with more coverage tools
4. **VSCode integration**: Test explorer and debugging
5. **Performance profiling**: Built-in profiling support

### Known Limitations

1. **Windows support**: Limited to MinGW/MSYS, no native MSVC tests
2. **C++ support**: Basic, not as mature as C/ObjC
3. **Test isolation**: Tests share some global state
4. **Parallel determinism**: Some edge cases with parallel execution

## Glossary

- **Craft**: Build process in mulle-sde ecosystem
- **Sanitizer**: Memory/behavior checking tool
- **TAO (Transparent AOP)**: mulle-objc's aspect-oriented programming
- **Standalone**: Single-library build mode
- **Sourcetree**: mulle-sde's dependency management
- **Extension**: mulle-sde template/configuration
- **Runtime**: Test environment configuration in mulle-sde

## Quick Reference

### Common Commands

```bash
mulle-test init                    # Initialize test directory
mulle-test craft                   # Build test project
mulle-test run                     # Run all tests
mulle-test run test/foo.c          # Run specific test
mulle-test crun test/foo.c         # Clean, craft, run single test
mulle-test rerun                   # Rerun failed tests
mulle-test clean                   # Clean build artifacts
mulle-test recraft                 # Clean all and rebuild
mulle-test coverage show           # Show coverage report
```

### Useful Flags

```bash
--no-clean                         # Skip clean before craft
--sanitize-address                 # Memory error detection
--valgrind                         # Valgrind integration  
--coverage                         # Code coverage
--gdb                              # Run in debugger
--serial                           # Serial execution
--keep-exe                         # Keep test executables
--golden-stdout                    # Generate expected output
```

## Planned Refactoring

**Note:** This codebase is being redesigned for better maintainability. See [REFACTORING.md](REFACTORING.md) for the detailed plugin-based architecture plan that will simplify mulle-test by separating:
- **Core Runner**: Execute, capture, compare (the essence)
- **Builder Plugins**: GCC, CMake, Meson, etc.
- **Sanitizer Plugins**: ASan, TSan, Valgrind, etc.

## Resources

- [README.md](README.md): User-facing documentation
- [REFACTORING.md](REFACTORING.md): **NEW** Plugin-based architecture design
- [dox/reference/](dox/reference/): Command reference
- [RELEASENOTES.md](RELEASENOTES.md): Version history
- [mulle-sde documentation](https://github.com/mulle-sde/mulle-sde): Build system
