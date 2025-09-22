# mulle-test craft

## Overview

The `craft` command forces a rebuild of the test project and its dependencies. It ensures that all test code is compiled with the latest changes and dependencies are properly linked before running tests. This command is essential when you've made changes to your main project that need to be reflected in the test builds.

## Quick Start

### Basic Usage
```bash
# Build test project and dependencies
mulle-test craft

# Build with debug configuration
mulle-test craft --debug

# Build with release configuration
mulle-test craft --release
```

### Advanced Building
```bash
# Build with coverage instrumentation
mulle-test craft --coverage

# Build with address sanitizer
mulle-test craft --sanitize-address

# Build with thread sanitizer
mulle-test craft --sanitize-thread

# Build with valgrind support
mulle-test craft --valgrind
```

## Detailed Usage

### Command Syntax
```bash
mulle-test craft [options] [-- [cmake-options]]
```

### Options

| Option | Description |
|--------|-------------|
| `--debug` | Build in debug configuration |
| `--release` | Build in release configuration |
| `--coverage` | Enable code coverage instrumentation |
| `--sanitize-address` | Enable address sanitizer |
| `--sanitize-thread` | Enable thread sanitizer |
| `--sanitize-undefined` | Enable undefined behavior sanitizer |
| `--valgrind` | Configure for valgrind memory checking |
| `--valgrind-no-leaks` | Configure valgrind without leak checking |
| `--testallocator` | Use mulle-testallocator (default) |
| `--zombie` | Enable zombie objects for debugging |
| `--add-sanitizer <name>` | Add custom sanitizer or memory checker |
| `--no-sanitizer` | Disable all sanitizers |
| `--standalone` | Build as standalone library |
| `--postprocess` | Force header file generation |
| `--no-postprocess` | Skip header file generation |
| `--serial` | Build dependencies serially |
| `--parallel` | Build dependencies in parallel (default) |

## How It Works

### Build Process
The `craft` command performs the following steps:

1. **Dependency Resolution**: Ensures all project dependencies are available
2. **Clean Build**: Forces rebuild of all components (unless `--no-clean` is used)
3. **Compilation**: Compiles test code with specified configuration
4. **Linking**: Links test executables with dependencies
5. **Post-processing**: Generates header files (`include.h`/`import.h`)
6. **Sanitizer Setup**: Configures memory checking tools if requested

### Build Configurations
- **Debug**: Includes debug symbols, no optimizations
- **Release**: Optimized build, minimal debug information
- **Coverage**: Instrumented for code coverage analysis

### Sanitizer Integration
The craft command integrates with various memory checking tools:

- **Address Sanitizer**: Detects memory corruption bugs
- **Thread Sanitizer**: Finds data races and thread safety issues
- **Undefined Behavior Sanitizer**: Catches undefined C/C++ behavior
- **Valgrind**: Comprehensive memory checking and profiling

## Examples

### Standard Build Workflow
```bash
# Initial build after project changes
mulle-test craft

# Quick rebuild without cleaning
mulle-test craft --no-clean

# Full clean rebuild
mulle-test clean all
mulle-test craft
```

### Debug Builds
```bash
# Debug build for development
mulle-test craft --debug

# Debug with address sanitizer
mulle-test craft --debug --sanitize-address

# Debug with all sanitizers
mulle-test craft --debug --sanitize-address --sanitize-undefined
```

### Release Builds
```bash
# Optimized release build
mulle-test craft --release

# Release with thread sanitizer
mulle-test craft --release --sanitize-thread
```

### Coverage Analysis
```bash
# Build for coverage testing
mulle-test craft --coverage

# Run tests and generate coverage
mulle-test run

# View coverage results (in build directory)
```

### Memory Checking
```bash
# Address sanitizer for memory corruption detection
mulle-test craft --sanitize-address
mulle-test run

# Thread sanitizer for race condition detection
mulle-test craft --sanitize-thread
mulle-test run

# Valgrind for detailed memory analysis
mulle-test craft --valgrind
mulle-test run
```

### Custom Build Options
```bash
# Pass custom CMake options
mulle-test craft -- -DCMAKE_BUILD_TYPE=RelWithDebInfo

# Build with custom compiler flags
mulle-test craft -- -DOTHER_CFLAGS="-O3 -march=native"

# Build with parallel jobs
mulle-test craft --parallel -- -j8
```

## Generated Files

### Build Artifacts
- **Test Executables**: Compiled test programs (`.exe` extension on Windows)
- **Object Files**: Intermediate compilation results
- **Libraries**: Built dependency libraries
- **Coverage Data**: GCOV/LCOV files (when `--coverage` is used)

### Header Files
- **`include.h`**: Auto-generated C header with all dependency includes
- **`import.h`**: Auto-generated Objective-C header with all dependency imports

### Build Directories
```
test/
├── build-*/           # Build artifacts per configuration
├── dependency/         # Dependency build artifacts
├── kitchen/            # Intermediate build files
└── .mulle/var/         # Build state and logs
```

## Environment Variables

### Build Configuration
- **`MULLE_TEST_DEFINE`**: Controls test-specific build flags
- **`SANITIZER`**: Active sanitizer configuration
- **`OPTION_CONFIGURATION`**: Build type (Debug/Release)

### Dependency Management
- **`DEPENDENCY_DIR`**: Location of built dependencies
- **`KITCHEN_DIR`**: Location of intermediate build files

## Integration with Main Project

### Dependency Synchronization
The craft command ensures test builds stay synchronized with main project changes:

- **Automatic Rebuild**: Detects when main project has changed
- **Dependency Updates**: Rebuilds dependencies as needed
- **Header Regeneration**: Updates generated headers when dependencies change

### Build Isolation
- **Separate Build Tree**: Test builds don't interfere with main project
- **Independent Configuration**: Test-specific build settings
- **Clean Separation**: Test build failures don't affect main project

## Troubleshooting

### Common Build Issues

#### Compilation Errors
```bash
# Check build logs
tail -f test/.mulle/var/log/craft.log

# Rebuild with verbose output
mulle-test craft -v

# Clean and rebuild
mulle-test clean all
mulle-test craft
```

#### Dependency Problems
```bash
# Update dependencies
mulle-sde dependency update

# Rebuild all dependencies
mulle-sde craft -g

# Check dependency status
mulle-sde dependency list
```

#### Header Generation Issues
```bash
# Force header regeneration
mulle-test craft --postprocess

# Check generated headers
cat test/include.h

# Manual header update
mulle-test craft --only-postprocess
```

### Sanitizer Issues
```bash
# Disable sanitizers if causing problems
mulle-test craft --no-sanitizer

# Use specific sanitizer combination
mulle-test craft --sanitize-address --no-sanitizer-undefined

# Check sanitizer compatibility
mulle-test craft --add-sanitizer "address:undefined"
```

### Performance Issues
```bash
# Build serially if parallel builds fail
mulle-test craft --serial

# Limit parallel jobs
mulle-test craft -- -j2

# Use release build for better performance
mulle-test craft --release
```

## Advanced Usage

### Custom Build Scripts
The craft command supports integration with custom build systems:

- **`craft-test`**: Custom crafting script in test directory
- **`build-test`**: Alternative build script
- **CMake Integration**: Passes options through to CMake

### Build Profiling
```bash
# Time the build process
time mulle-test craft

# Build with verbose logging
MULLE_FLAG_LOG_EXEKUTOR=YES mulle-test craft

# Check build dependencies
mulle-sde craftorder
```

### Cross-Platform Building
```bash
# Build for specific architecture
mulle-test craft -- -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64"

# Cross-compilation
mulle-test craft -- -DCMAKE_TOOLCHAIN_FILE=toolchain.cmake

# Windows-specific build
mulle-test craft -- -G "Visual Studio 16 2019"
```

### CI/CD Integration
```bash
# Fast incremental build
mulle-test craft --no-clean

# Full CI build with all checks
mulle-test craft --sanitize-address --coverage

# Minimal CI build
mulle-test craft --release --no-sanitizer
```

## Related Commands

- **[`run`](run.md)**: Run tests after building
- **[`clean`](clean.md)**: Clean build artifacts
- **[`init`](init.md)**: Initialize test environment
- **[`recraft`](recraft.md)**: Clean and rebuild

## Technical Details

### Build System Integration
- Uses `mulle-sde craft` as the underlying build system
- Supports CMake-based project configuration
- Integrates with mulle-sde dependency management
- Maintains build state in `.mulle/var/`

### Sanitizer Implementation
- **Address Sanitizer**: Uses `-fsanitize=address` compiler flags
- **Thread Sanitizer**: Uses `-fsanitize=thread` compiler flags
- **Undefined Sanitizer**: Uses `-fsanitize=undefined` compiler flags
- **Valgrind**: Configures build for valgrind compatibility

### Header Generation Process
1. **Dependency Scanning**: Analyzes all project dependencies
2. **Include Resolution**: Determines correct include paths
3. **Header Creation**: Generates `include.h`/`import.h` files
4. **Guard Management**: Adds proper header guards and includes

### Performance Considerations
- **Parallel Building**: Uses multiple cores by default
- **Incremental Builds**: Only rebuilds changed components
- **Dependency Caching**: Reuses unchanged dependency builds
- **Memory Optimization**: Configurable build parallelism