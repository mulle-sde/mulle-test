# mulle-test Command Reference

## Overview

**mulle-test** is a command-line tool for running and managing tests in the Mulle ecosystem. It provides a structured way to build, execute, and manage test suites for projects using the mulle-sde build system. mulle-test supports various sanitizers, coverage analysis, and integrates seamlessly with the Mulle toolchain.

## Command Categories

### Core Testing Operations
- **[`run`](run.md)** - Run tests, crafts beforehand if needed
- **[`craft`](craft.md)** - Rebuild of project for running test
- **[`init`](init.md)** - Setup a test project for the current project

### Test Execution
- **[`crun`](crun.md)** - Craft library if needed, then run a single test
- **[`rerun`](rerun.md)** - Run failing tests again
- **[`retest`](retest.md)** - Clean gravetidy, then craft and run

### Test Management
- **[`clean`](clean.md)** - Remove dependency, kitchens and exe files
- **[`recraft`](recraft.md)** - Clean all, then craft
- **[`test-dir`](test-dir.md)** - Locate test folder

### System & Info
- **[`arch`](arch.md)** - Name of current architecture
- **[`libexec-dir`](libexec-dir.md)** - Print path to mulle-test libexec
- **[`uname`](uname.md)** - mulle-test's simplified uname(1)
- **[`version`](version.md)** - Show version information
- **[`env`](env.md)** - Show environment variables

### Additional Commands
- **[`coverage`](coverage.md)** - Generate coverage information
- **[`craftorder`](craftorder.md)** - Show craft order
- **[`fetch`](fetch.md)** - Fetch dependencies
- **[`linkorder`](linkorder.md)** - Show link order
- **[`log`](log.md)** - Show logs

## Quick Start Examples

### Basic Test Workflow
```bash
# Initialize test environment
mulle-test init

# Build and run all tests
mulle-test run

# Run a specific test file
mulle-test crun test/example.c

# Clean and rebuild everything
mulle-test recraft
```

### Development Iteration
```bash
# Quick iteration without cleaning
mulle-test --no-clean crun test/my_test.c

# Run with debugging
mulle-test --gdb run

# Run with coverage
mulle-test --coverage run
```

### Advanced Testing
```bash
# Run with address sanitizer
mulle-test --sanitize-address run

# Run with valgrind
mulle-test --valgrind run

# Generate test coverage
mulle-test coverage
```

## Command Reference Table

| Command | Category | Description |
|---------|----------|-------------|
| `run` | Core | Run tests, crafts beforehand if needed |
| `craft` | Core | Force rebuild of project, then run tests |
| `init` | Core | Setup a test project for the current project |
| `crun` | Execution | Craft library if needed, then run a single test |
| `rerun` | Execution | Run failing tests again |
| `retest` | Execution | Clean gravetidy, then craft and run |
| `clean` | Management | Remove dependency, kitchens and exe files |
| `recraft` | Management | Clean all, then craft |
| `test-dir` | Management | Locate test folder |
| `arch` | System | Name of current architecture |
| `libexec-dir` | System | Print path to mulle-test libexec |
| `uname` | System | mulle-test's simplified uname(1) |
| `version` | System | Show version information |
| `env` | System | Show environment variables |
| `coverage` | Additional | Generate coverage information |
| `craftorder` | Additional | Show craft order |
| `fetch` | Additional | Fetch dependencies |
| `linkorder` | Additional | Show link order |
| `log` | Additional | Show logs |

## Getting Help

### Command Help
```bash
# Get help for a specific command
mulle-test <command> --help

# List all available commands
mulle-test --help

# Get detailed command information
mulle-test <command> --help --verbose
```

### Documentation
- Each command has a dedicated documentation file in this reference
- Use `--help` for quick command usage
- Check environment variables with `mulle-test env`

## Common Workflows

### Setting Up Tests
1. **Initialize** test environment: `mulle-test init`
2. **Configure** test directory: Set `MULLE_TEST_DIR` if needed
3. **Build** dependencies: `mulle-test craft`
4. **Run** tests: `mulle-test run`

### Development Cycle
1. **Write** test code in `test/` directory
2. **Build** changes: `mulle-test craft`
3. **Run** specific test: `mulle-test crun test/file.c`
4. **Debug** failures: `mulle-test --gdb crun test/file.c`
5. **Check** coverage: `mulle-test --coverage run`

### CI/CD Integration
1. **Clean** environment: `mulle-test clean`
2. **Fetch** dependencies: `mulle-test fetch`
3. **Build** with sanitizers: `mulle-test --sanitize-address craft`
4. **Run** comprehensive tests: `mulle-test run`
5. **Generate** coverage: `mulle-test coverage`

## Troubleshooting

### Common Issues
```bash
# Check test directory location
mulle-test test-dir

# Verify environment setup
mulle-test env

# Check build status
mulle-sde status

# Clean and retry
mulle-test recraft
```

### Build Problems
```bash
# Force clean rebuild
mulle-test clean all
mulle-test craft

# Check for missing dependencies
mulle-sde dependency list

# Verify test directory structure
ls -la test/
```

### Test Execution Issues
```bash
# Run with verbose output
mulle-test --verbose run

# Debug specific test
mulle-test --gdb crun test/failing_test.c

# Check test output
mulle-test run 2>&1 | tee test_output.log
```

## Advanced Usage

### Sanitizers and Memory Checking
```bash
# Address sanitizer
mulle-test --sanitize-address run

# Thread sanitizer
mulle-test --sanitize-thread run

# Undefined behavior sanitizer
mulle-test --sanitize-undefined run

# Valgrind memory checker
mulle-test --valgrind run

# Custom sanitizer combination
mulle-test --add-sanitizer custom run
```

### Coverage Analysis
```bash
# Generate clang coverage
mulle-test --coverage run

# Generate Objective-C coverage
mulle-test --objc-coverage run

# View coverage results
# (Coverage files generated in build directory)
```

### Environment Configuration
```bash
# Set test directory
export MULLE_TEST_DIR="custom_test_dir"

# Configure test language
export PROJECT_LANGUAGE="objc"

# Set test file extensions
export PROJECT_EXTENSIONS="*.m:*.c"

# Configure sanitizer defaults
export MULLE_TEST_SANITIZER="address"
```

### Integration with Scripts
```bash
# Batch test execution
for test in test/*.c; do
    echo "Running: $test"
    mulle-test crun "$test" || exit 1
done

# Conditional testing
if [ "$RUN_TESTS" = "YES" ]; then
    mulle-test run
fi

# Export test results
mulle-test run > test_results.txt 2>&1
```

## Related Documentation

- **[TODO.md](TODO.md)** - Current development status and process guide
- **[README.md](../../README.md)** - Project overview and installation
- **[mulle-sde.md](../mulle-sde.md)** - Build system guidelines
- **[mulle-craft.md](../mulle-craft.md)** - Build tool documentation