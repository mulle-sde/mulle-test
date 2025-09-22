# mulle-test retest

## Overview

The `retest` command performs a complete clean rebuild and test execution cycle. It cleans all build artifacts, rebuilds the entire test project from scratch, and then runs all tests. This is useful when you need to ensure a completely clean test environment or when dealing with persistent build issues.

## Quick Start

### Basic Usage
```bash
# Clean rebuild and test everything
mulle-test retest

# Clean rebuild with specific configuration
mulle-test retest --debug

# Clean rebuild with sanitizers
mulle-test retest --sanitize-address
```

### Development Workflow
```bash
# After major code changes
mulle-test retest

# When build issues persist
mulle-test retest --clean-all

# Full test suite validation
mulle-test retest --coverage
```

## Detailed Usage

### Command Syntax
```bash
mulle-test retest [options]
```

### Options

| Option | Description |
|--------|-------------|
| `--debug` | Build in debug mode |
| `--release` | Build in release mode |
| `--coverage` | Enable coverage analysis |
| `--gdb` | Run tests under GDB debugger |
| `--sanitize-address` | Use address sanitizer |
| `--sanitize-thread` | Use thread sanitizer |
| `--sanitize-undefined` | Use undefined behavior sanitizer |
| `--valgrind` | Run under valgrind |
| `--valgrind-no-leaks` | Valgrind without leak checking |
| `--serial` | Run tests serially |
| `--parallel` | Run tests in parallel (default) |
| `--lenient` | Continue on test failures |
| `-V` | Verbose build output |
| `--clean-all` | Clean all artifacts (default) |
| `--clean-tidy` | Clean temporary files only |
| `--no-clean` | Skip cleaning (not recommended) |

## How It Works

### Clean-Rebuild-Test Cycle
The `retest` command performs the following steps:

1. **Clean Phase**: Removes all build artifacts and temporary files
2. **Dependency Resolution**: Ensures all dependencies are properly cleaned
3. **Rebuild Phase**: Compiles entire test project from scratch
4. **Test Execution**: Runs all tests with specified options
5. **Result Analysis**: Reports test results and any failures

### Cleaning Levels
- **Default Clean**: Removes build artifacts, dependency caches, kitchen files
- **Deep Clean**: Includes dependency rebuilds and cache clearing
- **Full Clean**: Complete environment reset (use with caution)

### Build Process
- **Fresh Compilation**: All source files recompiled
- **Dependency Updates**: All dependencies rebuilt if needed
- **Clean State**: No cached build artifacts used
- **Complete Verification**: Ensures clean build environment

## Examples

### Standard Clean Testing
```bash
# Basic clean rebuild and test
mulle-test retest

# Clean rebuild with debug symbols
mulle-test retest --debug

# Clean rebuild with release optimization
mulle-test retest --release
```

### Advanced Testing
```bash
# Clean rebuild with full sanitization
mulle-test retest --sanitize-address --sanitize-undefined

# Clean rebuild with coverage analysis
mulle-test retest --coverage

# Clean rebuild with valgrind
mulle-test retest --valgrind
```

### Development Scenarios
```bash
# After dependency changes
mulle-test retest

# When build cache is corrupted
mulle-test retest --clean-all

# Before release validation
mulle-test retest --release

# CI/CD full validation
mulle-test retest --coverage --sanitize-address
```

### Troubleshooting Builds
```bash
# Clean rebuild when incremental fails
mulle-test retest

# Force complete rebuild
mulle-test retest --clean-all

# Rebuild with verbose output
mulle-test retest -V
```

## Cleaning Behavior

### What Gets Cleaned
- **Build Artifacts**: Object files, executables, libraries
- **Dependency Cache**: Cached dependency builds
- **Kitchen Files**: Intermediate build files
- **Test Executables**: Generated test programs
- **Coverage Data**: Previous coverage information
- **Log Files**: Build and test logs

### What Is Preserved
- **Source Files**: Test source code remains intact
- **Configuration**: Test project settings preserved
- **Expected Outputs**: `.stdout` files maintained
- **Documentation**: Generated docs preserved

## Build Configuration

### Compiler Settings
- **Fresh Flags**: All compiler flags reapplied
- **Sanitizer Integration**: Sanitizers properly configured
- **Optimization Levels**: Debug/Release settings applied
- **Warning Levels**: Compiler warnings re-enabled

### Dependency Management
- **Clean Dependencies**: All dependencies rebuilt
- **Cache Invalidation**: Dependency caches cleared
- **Link Updates**: All libraries relinked
- **Header Updates**: Generated headers refreshed

## Troubleshooting

### Common Issues

#### Build Failures After Clean
```bash
# Check for missing dependencies
mulle-sde dependency list

# Reinitialize if needed
mulle-test init

# Check build environment
mulle-sde status
```

#### Performance Issues
```bash
# Use parallel builds
mulle-test retest --parallel

# Limit job count for memory
mulle-test retest -j 2

# Use release for speed
mulle-test retest --release
```

#### Disk Space Issues
```bash
# Clean before rebuild
mulle-test clean all
mulle-test retest

# Use minimal configuration
mulle-test retest --release --no-sanitizer
```

#### Time Issues
```bash
# Skip unnecessary cleaning
mulle-test retest --clean-tidy

# Use incremental if possible
mulle-test run  # instead of retest

# Build only what changed
mulle-test craft
mulle-test run
```

### Recovery Procedures
```bash
# Complete environment reset
rm -rf test/
mulle-test init
mulle-test retest

# Selective rebuild
mulle-test clean dependencies
mulle-test retest

# Debug build issues
mulle-test retest -V 2>&1 | tee build.log
```

## Advanced Usage

### Custom Build Options
```bash
# Pass CMake options
mulle-test retest -- -DCMAKE_BUILD_TYPE=RelWithDebInfo

# Custom compiler flags
mulle-test retest -- -DOTHER_CFLAGS="-O3 -march=native"

# Build with specific toolchain
mulle-test retest -- -DCMAKE_TOOLCHAIN_FILE=toolchain.cmake
```

### Selective Cleaning
```bash
# Clean only build artifacts
mulle-test retest --clean-tidy

# Clean dependencies only
mulle-test clean dependencies
mulle-test retest

# Preserve some caches
mulle-test retest --no-clean-deps
```

### Integration with Scripts
```bash
# Automated clean test cycle
#!/bin/bash
echo "Starting clean rebuild..."
mulle-test retest
if [ $? -eq 0 ]; then
    echo "✓ All tests passed"
else
    echo "✗ Some tests failed"
    exit 1
fi
```

### CI/CD Integration
```bash
# Full CI validation
mulle-test retest --coverage --sanitize-address --valgrind

# Quick CI check
mulle-test retest --release

# Debug CI failures
mulle-test retest --debug -V
```

## Performance Considerations

### Build Time Optimization
- **Parallel Builds**: Utilize multiple CPU cores
- **Incremental Options**: Use when full clean not needed
- **Dependency Caching**: Preserve working dependency builds
- **Selective Cleaning**: Clean only what's necessary

### Resource Management
- **Memory Usage**: Monitor for large builds
- **Disk Space**: Clean unnecessary artifacts
- **CPU Utilization**: Balance parallel jobs with system load
- **Network Usage**: Consider dependency download times

## Related Commands

- **[`run`](run.md)**: Run tests without cleaning
- **[`craft`](craft.md)**: Build without running tests
- **[`clean`](clean.md)**: Clean without rebuilding
- **[`recraft`](recraft.md)**: Clean and rebuild without testing

## Technical Details

### Clean Levels
- **TIDY**: Remove temporary files and caches
- **GRAVETIDY**: Deep clean including dependency caches
- **ALL**: Complete environment reset

### Build Process Integration
- **CMake Integration**: Full CMake rebuild cycle
- **Dependency Resolution**: Complete dependency graph rebuild
- **Header Generation**: Fresh header file creation
- **Linker Updates**: Complete relinking of all components

### State Management
- **Build State Reset**: All build state cleared
- **Cache Invalidation**: All caches marked invalid
- **Configuration Refresh**: All configurations reloaded
- **Environment Reset**: Clean environment state

### Error Handling
- **Build Failure Recovery**: Clear error state on retry
- **Dependency Resolution**: Handle missing dependencies
- **Configuration Validation**: Verify build settings
- **Resource Management**: Handle resource exhaustion