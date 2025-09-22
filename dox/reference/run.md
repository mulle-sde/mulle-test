# mulle-test run

## Overview

The `run` command executes tests in the initialized test environment. It automatically builds the test project if needed and runs all tests or a specific test file. The command supports various execution modes, debugging options, and integrates with memory checkers and coverage tools.

## Quick Start

### Basic Test Execution
```bash
# Run all tests
mulle-test run

# Run specific test file
mulle-test run test/my_test.c

# Run with automatic building
mulle-test run  # builds if needed
```

### Debug and Development
```bash
# Run with debugging
mulle-test run --gdb

# Run single test with rebuild
mulle-test crun test/specific_test.c

# Run failing tests again
mulle-test rerun
```

### Advanced Execution
```bash
# Run with coverage
mulle-test run --coverage

# Run with address sanitizer
mulle-test run --sanitize-address

# Run in serial mode
mulle-test run --serial

# Run with verbose output
mulle-test run -V
```

## Detailed Usage

### Command Syntax
```bash
mulle-test run [options] [test-file]
```

### Options

| Option | Description |
|--------|-------------|
| `-l` | Lenient mode - continue on test failures |
| `-V` | Verbose build output |
| `-j <n>` | Number of parallel jobs |
| `--serial` | Run tests serially |
| `--parallel` | Run tests in parallel (default) |
| `--lenient` | Continue execution on test failures |
| `--rerun` | Rerun previously failed tests |
| `--debug` | Build in debug mode |
| `--release` | Build in release mode |
| `--coverage` | Enable coverage analysis |
| `--gdb` | Run tests under GDB debugger |
| `--sanitize-address` | Use address sanitizer |
| `--sanitize-thread` | Use thread sanitizer |
| `--sanitize-undefined` | Use undefined behavior sanitizer |
| `--valgrind` | Run under valgrind |
| `--valgrind-no-leaks` | Valgrind without leak checking |
| `--no-run` | Build only, don't execute tests |
| `--keep-exe` | Keep test executables after successful run |
| `--reuse-exe` | Reuse existing executables if available |
| `--golden-stdout` | Generate expected output files |
| `--assembler` | Produce assembler output |
| `--ir` | Produce LLVM IR output |
| `--disable-coredumps` | Disable core dump generation |
| `--extensions <list>` | Specify test file extensions |

## How It Works

### Test Discovery and Execution
The `run` command performs the following steps:

1. **Test Discovery**: Scans test directory for test files
2. **Dependency Check**: Verifies test project is built and up-to-date
3. **Build Verification**: Crafts project if needed
4. **Test Execution**: Runs tests according to specified options
5. **Result Analysis**: Compares output with expected results
6. **Reporting**: Displays test results and failures

### Test File Types
mulle-test supports various test file formats:

- **`.c`**: C language tests
- **`.m`**: Objective-C tests
- **`.cpp`**: C++ tests
- **`.cmake`**: CMake-based tests
- **`.sh`**: Shell script tests
- **`.run`**: Custom runner scripts
- **`.exe`**: Pre-compiled executables

### Auxiliary Files
Tests can include auxiliary files for configuration:

- **`<name>.args`**: Command-line arguments for test
- **`<name>.stdout`**: Expected standard output
- **`<name>.stderr`**: Expected standard error
- **`<name>.stdin`**: Input data for test
- **`<name>.environment`**: Environment variables
- **`<name>.errors`**: Expected error patterns
- **`<name>.ccdiag`**: Expected compiler diagnostics

## Examples

### Basic Test Running
```bash
# Run all tests in test directory
mulle-test run

# Run specific test
mulle-test run test/array_test.c

# Run tests in subdirectory
mulle-test run test/memory/

# Run with custom extensions
mulle-test run --extensions "c:m:cpp"
```

### Debug Mode Execution
```bash
# Run under GDB
mulle-test run --gdb test/debug_test.c

# Run with address sanitizer
mulle-test run --sanitize-address

# Run with thread sanitizer
mulle-test run --sanitize-thread

# Run under valgrind
mulle-test run --valgrind
```

### Development Workflow
```bash
# Quick iteration (no rebuild)
mulle-test run --reuse-exe test/my_test.c

# Build and run single test
mulle-test crun test/new_feature.c

# Run failing tests only
mulle-test rerun

# Generate expected output
mulle-test run --golden-stdout test/new_test.c
```

### Coverage and Analysis
```bash
# Run with coverage
mulle-test run --coverage

# Run with assembler output
mulle-test run --assembler test/asm_test.c

# Run with LLVM IR output
mulle-test run --ir test/ir_test.c
```

### Batch and Automation
```bash
# Run in serial mode
mulle-test run --serial

# Continue on failures
mulle-test run --lenient

# Run with parallel jobs
mulle-test run -j 4

# Verbose output
mulle-test run -V
```

## Test File Structure

### Basic Test Format
```c
// test/example_test.c
#include "include.h"

int main(void)
{
    // Test code here
    mulle_printf("Test result: %d\n", 42);
    return 0;
}
```

### Expected Output File
```bash
# test/example_test.stdout
Test result: 42
```

### Test with Arguments
```bash
# test/args_test.args
--verbose --input test.dat
```

### Environment Variables
```bash
# test/env_test.environment
export TEST_MODE=development
export LOG_LEVEL=debug
```

## Execution Modes

### Normal Execution
- Builds project if needed
- Runs all discovered tests
- Reports results immediately
- Stops on first failure (unless `--lenient`)

### Debug Execution
- Uses GDB for interactive debugging
- Provides breakpoints and inspection
- Shows detailed execution flow

### Sanitizer Execution
- **Address Sanitizer**: Detects memory corruption
- **Thread Sanitizer**: Finds race conditions
- **Undefined Behavior**: Catches undefined operations

### Coverage Execution
- Instruments code for coverage analysis
- Generates coverage reports
- Tracks execution paths

## Troubleshooting

### Common Issues

#### Test Discovery Problems
```bash
# Check test directory structure
ls -la test/

# Verify test files exist
find test/ -name "*.c" -o -name "*.m"

# Check file permissions
ls -l test/my_test.c
```

#### Build Failures
```bash
# Force rebuild
mulle-test craft

# Clean and rebuild
mulle-test recraft

# Check build logs
tail -f test/.mulle/var/log/craft.log
```

#### Execution Failures
```bash
# Run with verbose output
mulle-test run -V

# Debug specific test
mulle-test run --gdb test/failing_test.c

# Check test output
mulle-test run test/failing_test.c 2>&1 | tee debug.log
```

#### Output Mismatches
```bash
# Update expected output
mulle-test run --golden-stdout test/my_test.c

# Compare outputs manually
diff test/my_test.stdout expected_output.txt

# Check for non-deterministic output
mulle-test run test/my_test.c | grep -E "(address|time|pid)"
```

### Performance Issues
```bash
# Run serially if parallel fails
mulle-test run --serial

# Limit parallel jobs
mulle-test run -j 2

# Reuse executables
mulle-test run --reuse-exe
```

### Memory and Resource Issues
```bash
# Disable core dumps if disk space is issue
mulle-test run --disable-coredumps

# Use release build for better performance
mulle-test run --release

# Keep executables for faster reruns
mulle-test run --keep-exe
```

## Advanced Usage

### Custom Test Runners
```bash
# Shell script test
#!/bin/bash
# test/custom_test.sh
echo "Custom test output"
exit 0
```

### CMake-based Tests
```cmake
# test/cmake_test.cmake
project(TestProject)
add_executable(test_app main.c)
target_link_libraries(test_app mylib)
```

### Environment Configuration
```bash
# Platform-specific environment
echo "export SPECIAL_VAR=linux_value" > test/default.environment.linux
echo "export SPECIAL_VAR=darwin_value" > test/default.environment.darwin
```

### Test Filtering
```bash
# Run tests matching pattern
mulle-test run "test/*memory*"

# Run tests in specific directory
mulle-test run test/unit/

# Exclude certain tests
mulle-test run --exclude "test/integration/*"
```

### Integration with CI/CD
```bash
# CI build with full checks
mulle-test run --sanitize-address --coverage --valgrind

# Fast CI build
mulle-test run --release --reuse-exe

# Debug CI failures
mulle-test run --gdb --no-run test/failing_test.c
```

## Related Commands

- **[`craft`](craft.md)**: Build test project
- **[`crun`](crun.md)**: Build and run single test
- **[`rerun`](rerun.md)**: Rerun failed tests
- **[`init`](init.md)**: Initialize test environment
- **[`clean`](clean.md)**: Clean test artifacts

## Technical Details

### Test Execution Process
1. **File Discovery**: Scans for test files with supported extensions
2. **Dependency Resolution**: Ensures all required libraries are built
3. **Environment Setup**: Configures test environment variables
4. **Compilation**: Builds test executables if needed
5. **Execution**: Runs tests with specified options
6. **Output Verification**: Compares actual vs expected output
7. **Result Reporting**: Displays pass/fail status

### Supported Platforms
- **Linux**: Full support with all sanitizers
- **macOS**: Full support with address/thread sanitizers
- **Windows**: Support via MinGW/MSYS
- **Cross-platform**: Consistent behavior across platforms

### Memory Management
- **Test Allocator**: Custom allocator for leak detection
- **Sanitizer Integration**: Automatic memory checking
- **Resource Cleanup**: Proper cleanup of test resources

### Output Handling
- **Deterministic Output**: No random values in test output
- **Platform Independence**: Consistent output across platforms
- **Error Reporting**: Clear failure diagnostics
- **Log Integration**: Integration with mulle logging system