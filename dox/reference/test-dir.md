# mulle-test test-dir

## Overview

The `test-dir` command displays the path to the test directory. It helps users identify where their test files are located and ensures they are working in the correct test environment. This is particularly useful in complex project setups or when troubleshooting test discovery issues.

## Quick Start

### Basic Usage
```bash
# Show test directory path
mulle-test test-dir

# Use in scripts
TEST_DIR=$(mulle-test test-dir)
echo "Tests are in: $TEST_DIR"
```

### Verification
```bash
# Check if test directory exists
if [ -d "$(mulle-test test-dir)" ]; then
    echo "Test directory exists"
else
    echo "Test directory not found"
fi
```

## Detailed Usage

### Command Syntax
```bash
mulle-test test-dir [options]
```

### Options

| Option | Description |
|--------|-------------|
| `--absolute` | Show absolute path (default) |
| `--relative` | Show path relative to current directory |
| `--exists` | Exit with success if directory exists, failure otherwise |
| `--create` | Create test directory if it doesn't exist |
| `-v` | Verbose output |

## How It Works

### Directory Resolution
The `test-dir` command performs the following steps:

1. **Environment Check**: Verifies mulle-test environment is initialized
2. **Path Resolution**: Determines test directory location
3. **Validation**: Confirms directory exists and is properly configured
4. **Output**: Displays the resolved path

### Path Determination
- **Default Location**: Uses `test/` subdirectory
- **Custom Location**: Respects `MULLE_TEST_DIR` environment variable
- **Absolute Path**: Converts relative paths to absolute
- **Validation**: Ensures directory contains proper mulle-sde structure

## Examples

### Basic Path Display
```bash
# Show current test directory
mulle-test test-dir

# Show relative path
mulle-test test-dir --relative

# Check if directory exists
mulle-test test-dir --exists && echo "OK" || echo "Missing"
```

### Script Integration
```bash
# Store test directory in variable
TEST_PATH=$(mulle-test test-dir)

# Navigate to test directory
cd "$(mulle-test test-dir)"

# List test files
ls "$(mulle-test test-dir)"

# Count test files
find "$(mulle-test test-dir)" -name "*.c" | wc -l
```

### Environment Setup
```bash
# Set custom test directory
export MULLE_TEST_DIR="custom_tests"
mulle-test test-dir

# Verify test directory structure
TEST_DIR=$(mulle-test test-dir)
ls -la "$TEST_DIR"
```

### Troubleshooting
```bash
# Check test directory status
mulle-test test-dir --exists

# Create test directory if missing
mulle-test test-dir --create

# Debug path resolution
mulle-test test-dir -v
```

## Directory Structure

### Expected Layout
```
test/
├── .mulle/           # mulle-sde configuration
│   └── share/
│       └── sde/      # Build system files
├── include.h         # Generated header
├── import.h          # Generated imports
├── test1.c           # Test source files
├── test1.stdout      # Expected output
└── build-*/          # Build artifacts
```

### Configuration Files
- **`.mulle/share/sde`**: Indicates mulle-sde project
- **`include.h`**: Auto-generated header includes
- **`import.h`**: Auto-generated import statements
- **`<test>.stdout`**: Expected test output files

## Troubleshooting

### Common Issues

#### Directory Not Found
```bash
# Check if initialized
mulle-test init

# Verify environment
echo $MULLE_TEST_DIR

# Check current directory
pwd
ls -la
```

#### Wrong Path
```bash
# Reset environment variable
unset MULLE_TEST_DIR

# Check default location
ls -la test/

# Reinitialize if needed
mulle-test init
```

#### Permission Issues
```bash
# Check permissions
ls -ld "$(mulle-test test-dir)"

# Fix permissions
chmod 755 "$(mulle-test test-dir)"

# Check ownership
ls -ln "$(mulle-test test-dir)"
```

#### Configuration Problems
```bash
# Verify mulle-sde setup
mulle-sde status

# Check test directory structure
find "$(mulle-test test-dir)" -name ".mulle" -type d

# Reinitialize test environment
rm -rf test/
mulle-test init
```

### Recovery Procedures
```bash
# Complete reset
rm -rf test/
mulle-test init

# Selective fix
mulle-test test-dir --create

# Environment fix
unset MULLE_TEST_DIR
export MULLE_TEST_DIR="test"
```

## Advanced Usage

### Custom Directory Locations
```bash
# Use different directory name
export MULLE_TEST_DIR="tests"
mulle-test test-dir

# Use absolute path
export MULLE_TEST_DIR="/full/path/to/tests"
mulle-test test-dir

# Use relative path
export MULLE_TEST_DIR="../project-tests"
mulle-test test-dir
```

### Script Automation
```bash
# Automated test directory setup
#!/bin/bash
TEST_DIR=$(mulle-test test-dir)

if [ ! -d "$TEST_DIR" ]; then
    echo "Creating test directory..."
    mulle-test init
fi

echo "Test directory: $TEST_DIR"
```

### Integration with Build Systems
```bash
# Makefile integration
TEST_DIR := $(shell mulle-test test-dir)

.PHONY: test
test:
    @echo "Running tests in $(TEST_DIR)"
    cd $(TEST_DIR) && mulle-sde test run

# CMake integration
execute_process(
    COMMAND mulle-test test-dir
    OUTPUT_VARIABLE TEST_DIR
    OUTPUT_STRIP_TRAILING_WHITESPACE
)
```

### CI/CD Integration
```bash
# CI test directory verification
#!/bin/bash
if ! mulle-test test-dir --exists; then
    echo "Test directory missing"
    mulle-test init
fi

# Archive test directory
TEST_DIR=$(mulle-test test-dir)
tar czf test-dir.tar.gz "$TEST_DIR"
```

## Environment Variables

### MULLE_TEST_DIR
- **Purpose**: Specifies custom test directory location
- **Default**: `"test"`
- **Format**: Relative or absolute path
- **Scope**: Current shell session

### Related Variables
- **MULLE_USER_PWD**: Current working directory
- **MULLE_VIRTUAL_ROOT**: Virtual environment root
- **PWD**: Current directory (shell built-in)

## Related Commands

- **[`init`](init.md)**: Initialize test environment
- **[`run`](run.md)**: Run tests in test directory
- **[`craft`](craft.md)**: Build test project
- **[`clean`](clean.md)**: Clean test directory

## Technical Details

### Path Resolution Algorithm
1. **Check Environment**: Read `MULLE_TEST_DIR` variable
2. **Default Fallback**: Use `"test"` if not set
3. **Absolute Conversion**: Convert to absolute path
4. **Validation**: Verify directory exists and is valid
5. **Output**: Display resolved path

### Directory Validation
- **Existence Check**: Directory must exist
- **Structure Check**: Must contain `.mulle/share/sde`
- **Permission Check**: Must be readable and writable
- **Type Check**: Must be a directory, not a file

### Error Handling
- **Missing Directory**: Reports clear error message
- **Invalid Path**: Validates path format and accessibility
- **Permission Denied**: Checks read/write permissions
- **Configuration Error**: Verifies mulle-sde setup

### Performance Considerations
- **Caching**: Path resolution results may be cached
- **Validation**: Minimal validation for speed
- **Output Format**: Consistent formatting for scripting
- **Error Codes**: Standard exit codes for automation