# mulle-test crun

## Overview

The `crun` command combines building and running a single test file. It ensures the test project is built (crafting if necessary) and then executes the specified test. This is the most common command for iterative development and debugging of individual tests.

## Quick Start

### Basic Usage
```bash
# Build and run a specific test
mulle-test crun test/my_test.c

# Run with debugging
mulle-test crun --gdb test/debug_test.c

# Run with sanitizers
mulle-test crun --sanitize-address test/memory_test.c
```

### Development Workflow
```bash
# Quick iteration on a single test
mulle-test crun test/array_test.c

# Test with different configurations
mulle-test crun --coverage test/coverage_test.c

# Debug a failing test
mulle-test crun --gdb test/failing_test.c
```

## Detailed Usage

### Command Syntax
```bash
mulle-test crun [options] <test-file>
```

### Options

| Option | Description |
|--------|-------------|
| `--debug` | Build in debug mode |
| `--release` | Build in release mode |
| `--coverage` | Enable coverage analysis |
| `--gdb` | Run test under GDB debugger |
| `--sanitize-address` | Use address sanitizer |
| `--sanitize-thread` | Use thread sanitizer |
| `--sanitize-undefined` | Use undefined behavior sanitizer |
| `--valgrind` | Run under valgrind |
| `--valgrind-no-leaks` | Valgrind without leak checking |
| `--no-run` | Build only, don't execute |
| `--keep-exe` | Keep test executable after successful run |
| `--reuse-exe` | Reuse existing executable if available |
| `--serial` | Run tests serially |
| `--parallel` | Run tests in parallel (default) |
| `--lenient` | Continue on test failures |
| `-V` | Verbose build output |

## How It Works

### Build and Execute Process
The `crun` command performs the following steps:

1. **Project Verification**: Ensures test environment is properly initialized
2. **Dependency Check**: Verifies all dependencies are built and up-to-date
3. **Target Build**: Compiles the specific test file and its dependencies
4. **Test Execution**: Runs the compiled test with specified options
5. **Result Analysis**: Compares output with expected results
6. **Cleanup**: Removes temporary files (unless `--keep-exe` is used)

### Automatic Building
Unlike `run`, `crun` automatically handles the build process:
- Builds the test project if needed
- Rebuilds dependencies when source files change
- Ensures proper linking of test executables
- Handles incremental builds for faster iteration

### Single Test Focus
`crun` is optimized for single-test development:
- Faster than full test suite runs
- Immediate feedback on test changes
- Simplified debugging workflow
- Reduced build overhead

## Examples

### Basic Test Development
```bash
# Edit and test a single file
vim test/my_feature_test.c
mulle-test crun test/my_feature_test.c

# Test with different build configurations
mulle-test crun --debug test/my_test.c
mulle-test crun --release test/my_test.c

# Test with coverage
mulle-test crun --coverage test/coverage_test.c
```

### Debug and Analysis
```bash
# Debug with GDB
mulle-test crun --gdb test/debug_test.c

# Memory checking with sanitizers
mulle-test crun --sanitize-address test/memory_test.c
mulle-test crun --sanitize-thread test/thread_test.c

# Valgrind analysis
mulle-test crun --valgrind test/valgrind_test.c
```

### Iterative Development
```bash
# Quick test cycles
mulle-test crun test/unit_test.c
# Make changes...
mulle-test crun test/unit_test.c

# Test with verbose output
mulle-test crun -V test/verbose_test.c

# Keep executable for multiple runs
mulle-test crun --keep-exe test/repeat_test.c
./test/repeat_test.c.exe  # Run directly
```

### Batch Operations
```bash
# Test multiple files
for test in test/*_test.c; do
    mulle-test crun "$test" || break
done

# Test with error tolerance
mulle-test crun --lenient test/may_fail_test.c

# Parallel testing (if multiple tests)
mulle-test crun --parallel test/suite_test.c
```

## Test File Requirements

### Supported File Types
`crun` works with all supported test file types:
- **`.c`**: C language tests
- **`.m`**: Objective-C tests
- **`.cpp`**: C++ tests
- **`.sh`**: Shell script tests
- **`.run`**: Custom runner scripts

### Auxiliary Files
Tests can include auxiliary files for configuration:
- **`<name>.args`**: Command-line arguments
- **`<name>.stdout`**: Expected standard output
- **`<name>.stderr`**: Expected standard error
- **`<name>.stdin`**: Input data for test
- **`<name>.environment`**: Environment variables

## Troubleshooting

### Common Issues

#### Build Failures
```bash
# Check for missing dependencies
mulle-sde dependency list

# Force clean rebuild
mulle-test recraft
mulle-test crun test/my_test.c

# Check build logs
tail -f test/.mulle/var/log/craft.log
```

#### Test Execution Problems
```bash
# Run with verbose output
mulle-test crun -V test/problem_test.c

# Debug execution
mulle-test crun --gdb test/failing_test.c

# Check test output manually
mulle-test crun --no-run test/my_test.c
./test/my_test.c.exe
```

#### File Not Found
```bash
# Verify test file exists
ls -la test/my_test.c

# Check test directory
mulle-test test-dir

# Ensure proper test environment
mulle-test init
```

#### Output Mismatches
```bash
# Update expected output
mulle-test crun --golden-stdout test/my_test.c

# Compare outputs
diff test/my_test.c.stdout expected.txt

# Check for non-deterministic output
mulle-test crun test/my_test.c | grep -E "(0x[0-9a-f]+|time|pid)"
```

### Performance Issues
```bash
# Use reuse-exe for faster iterations
mulle-test crun --reuse-exe test/fast_test.c

# Build in release mode
mulle-test crun --release test/perf_test.c

# Keep executables for multiple runs
mulle-test crun --keep-exe test/repeat_test.c
```

### Memory and Resource Issues
```bash
# Disable core dumps if needed
ulimit -c 0
mulle-test crun test/large_test.c

# Use release build for lower memory usage
mulle-test crun --release test/memory_test.c

# Run serially if parallel fails
mulle-test crun --serial test/parallel_test.c
```

## Advanced Usage

### Custom Build Options
```bash
# Pass custom CMake options
mulle-test crun -- -DCMAKE_BUILD_TYPE=RelWithDebInfo test/my_test.c

# Custom compiler flags
mulle-test crun -- -DOTHER_CFLAGS="-O3" test/opt_test.c
```

### Integration with Scripts
```bash
# Automated testing script
#!/bin/bash
TEST_FILE="$1"
if [ -z "$TEST_FILE" ]; then
    echo "Usage: $0 <test-file>"
    exit 1
fi

mulle-test crun "$TEST_FILE"
if [ $? -eq 0 ]; then
    echo "✓ Test passed: $TEST_FILE"
else
    echo "✗ Test failed: $TEST_FILE"
    exit 1
fi
```

### CI/CD Integration
```bash
# CI test with full analysis
mulle-test crun --sanitize-address --coverage test/ci_test.c

# Fast CI test
mulle-test crun --release --reuse-exe test/fast_ci_test.c

# Debug CI failures
mulle-test crun --gdb --no-run test/failing_ci_test.c
```

## Related Commands

- **[`run`](run.md)**: Run all tests or multiple tests
- **[`rerun`](rerun.md)**: Rerun previously failed tests
- **[`craft`](craft.md)**: Build test project without running
- **[`init`](init.md)**: Initialize test environment

## Technical Details

### Build Integration
- Uses `mulle-sde craft` for dependency building
- Supports incremental builds for faster iteration
- Handles cross-platform compilation differences
- Integrates with mulle-sde dependency management

### Execution Environment
- Inherits environment from test project
- Supports platform-specific test configurations
- Handles different executable formats (`.exe` on Windows)
- Manages temporary file cleanup

### Performance Optimizations
- **Incremental Builds**: Only rebuilds changed components
- **Dependency Caching**: Reuses unchanged dependency builds
- **Executable Reuse**: Avoids recompilation when possible
- **Parallel Processing**: Utilizes multiple CPU cores

### Error Handling
- **Build Error Detection**: Stops on compilation failures
- **Test Failure Handling**: Configurable error tolerance
- **Resource Management**: Proper cleanup of temporary files
- **Signal Handling**: Graceful handling of interrupts