# mulle-test rerun

## Overview

The `rerun` command re-executes tests that previously failed. It skips the build process and directly runs only the tests that failed in the last test execution. This is useful for iterative debugging and fixing test failures without rebuilding the entire test suite.

## Quick Start

### Basic Usage
```bash
# Rerun previously failed tests
mulle-test rerun

# Rerun with debugging
mulle-test rerun --gdb

# Rerun with sanitizers
mulle-test rerun --sanitize-address
```

### Debug Workflow
```bash
# Run tests initially
mulle-test run

# Fix failing tests
vim test/failing_test.c

# Rerun only the failed ones
mulle-test rerun

# Debug specific failures
mulle-test rerun --gdb
```

## Detailed Usage

### Command Syntax
```bash
mulle-test rerun [options]
```

### Options

| Option | Description |
|--------|-------------|
| `--debug` | Build in debug mode (if rebuild needed) |
| `--release` | Build in release mode (if rebuild needed) |
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
| `-V` | Verbose output |

## How It Works

### Failure Detection
The `rerun` command identifies failed tests by:

1. **State Tracking**: Maintains information about previously failed tests
2. **Selective Execution**: Only runs tests that failed in the last execution
3. **Skip Successful**: Ignores tests that passed previously
4. **Build Avoidance**: Doesn't rebuild unless source files have changed

### Execution Process
1. **Check Build Status**: Verifies if rebuild is needed
2. **Load Failure List**: Retrieves list of previously failed tests
3. **Execute Failed Tests**: Runs only the failed test cases
4. **Update Results**: Records new pass/fail status
5. **Report Changes**: Shows which tests are now passing

### State Management
- **Failure Persistence**: Remembers failed tests across command invocations
- **State Reset**: Clears failure list when running full test suite
- **Incremental Updates**: Updates failure status as tests are fixed

## Examples

### Basic Rerun Workflow
```bash
# Run full test suite
mulle-test run

# Some tests fail, fix them
vim test/failing_test.c

# Rerun only failed tests
mulle-test rerun

# Continue fixing and rerunning
mulle-test rerun
```

### Debug Failed Tests
```bash
# Run tests to identify failures
mulle-test run

# Debug failed tests with GDB
mulle-test rerun --gdb

# Run with memory checking
mulle-test rerun --sanitize-address

# Use valgrind for detailed analysis
mulle-test rerun --valgrind
```

### Iterative Development
```bash
# Initial test run
mulle-test run

# Fix first set of failures
# ... edit code ...
mulle-test rerun

# Fix next set of failures
# ... edit code ...
mulle-test rerun

# Continue until all pass
mulle-test rerun
```

### CI/CD Integration
```bash
# Run tests in CI
mulle-test run || true  # Don't fail build yet

# Rerun failed tests with more detail
mulle-test rerun -V

# Final verification
mulle-test rerun
```

## Failure Tracking

### How Failures Are Tracked
- **Test Status**: Records pass/fail status for each test
- **Failure Reasons**: Captures error messages and exit codes
- **Execution Context**: Remembers test environment and options
- **Timestamp**: Tracks when failures occurred

### Failure List Management
```bash
# View current failure status
mulle-test rerun --list-failures  # (if supported)

# Clear failure history
mulle-test run  # Resets failure tracking

# Force rerun of all tests
mulle-test run --force-rerun
```

## Troubleshooting

### Common Issues

#### No Tests to Rerun
```bash
# Check if there are failed tests
mulle-test rerun  # Will show "No failed tests to rerun"

# Run full test suite first
mulle-test run

# Then rerun failed ones
mulle-test rerun
```

#### Build Changes Required
```bash
# If source files changed, may need rebuild
mulle-test craft
mulle-test rerun

# Or use crun for single test rebuild
mulle-test crun test/changed_test.c
```

#### State Corruption
```bash
# Clear test state if corrupted
rm -rf test/.mulle/var/test/
mulle-test run

# Reset failure tracking
mulle-test run --reset-failures
```

### Performance Considerations
```bash
# Run failed tests in parallel
mulle-test rerun --parallel

# Use serial execution for debugging
mulle-test rerun --serial

# Limit concurrent jobs
mulle-test rerun -j 2
```

### Memory and Resource Issues
```bash
# Use release build for failed tests
mulle-test rerun --release

# Disable heavy sanitizers for speed
mulle-test rerun --no-sanitizer

# Keep executables for faster reruns
mulle-test rerun --keep-exe
```

## Advanced Usage

### Selective Rerun
```bash
# Rerun specific failed test
mulle-test rerun test/specific_test.c

# Rerun tests matching pattern
mulle-test rerun "test/*memory*"

# Rerun tests in specific directory
mulle-test rerun test/unit/
```

### Custom Execution Options
```bash
# Pass custom environment
TEST_MODE=debug mulle-test rerun

# Use different test configuration
mulle-test rerun --config debug

# Override test timeout
mulle-test rerun --timeout 60
```

### Integration with Scripts
```bash
# Automated fix and test cycle
#!/bin/bash
while mulle-test rerun 2>&1 | grep -q "failed"; do
    echo "Fixing failed tests..."
    # Add your fix logic here
    sleep 1
done
echo "All tests now passing!"
```

### CI/CD Patterns
```bash
# Rerun with different configurations
mulle-test rerun --sanitize-address
mulle-test rerun --sanitize-thread
mulle-test rerun --valgrind

# Generate detailed failure reports
mulle-test rerun -V > rerun_report.txt

# Archive failure information
mulle-test rerun --export-failures failures.json
```

## Related Commands

- **[`run`](run.md)**: Run all tests (resets failure tracking)
- **[`crun`](crun.md)**: Build and run single test
- **[`retest`](retest.md)**: Clean and rerun all tests
- **[`craft`](craft.md)**: Build test project

## Technical Details

### Failure State Storage
- **Location**: `test/.mulle/var/test/failures/`
- **Format**: JSON or plain text failure records
- **Persistence**: Survives across terminal sessions
- **Cleanup**: Automatically cleaned on full test runs

### Execution Optimization
- **Dependency Checking**: Only rebuilds if source files changed
- **Incremental Execution**: Skips successful tests
- **Resource Reuse**: Reuses existing test executables
- **Parallel Execution**: Utilizes multiple CPU cores

### State Management
- **Atomic Updates**: Failure state updated atomically
- **Consistency Checks**: Validates failure records integrity
- **Recovery**: Handles corrupted state gracefully
- **Migration**: Supports state format updates

### Integration Points
- **Build System**: Coordinates with mulle-sde build process
- **Test Framework**: Integrates with test execution engine
- **Debugger Integration**: Supports GDB and other debuggers
- **Sanitizer Support**: Works with all supported sanitizers