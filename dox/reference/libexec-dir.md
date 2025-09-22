# mulle-test libexec-dir

## Overview

The `libexec-dir` command displays the path to mulle-test's internal library execution directory. This directory contains supporting scripts and utilities that mulle-test uses for its operations.

## Quick Start

```bash
# Display libexec directory path
mulle-test libexec-dir
```

## Description

The `libexec-dir` command prints the absolute path to the directory where mulle-test stores its internal executable scripts and utilities. This is typically used for debugging, development, or when integrating with other tools that need to access mulle-test's internal components.

## Examples

### Basic Usage
```bash
# Get the libexec directory path
mulle-test libexec-dir
/usr/local/libexec/mulle-test
```

### Inspecting Internal Scripts
```bash
# List contents of libexec directory
ls -la $(mulle-test libexec-dir)

# View a specific internal script
cat $(mulle-test libexec-dir)/mulle-test-craft.sh
```

### Integration with Build Scripts
```bash
# Use in shell scripts
LIBEXEC_DIR=$(mulle-test libexec-dir)
echo "mulle-test libexec: $LIBEXEC_DIR"

# Check if libexec directory exists
if [ -d "$(mulle-test libexec-dir)" ]; then
    echo "libexec directory is accessible"
else
    echo "libexec directory not found"
fi
```

### Development and Debugging
```bash
# Examine internal test running script
less $(mulle-test libexec-dir)/mulle-test-run.sh

# Check for custom build scripts
find $(mulle-test libexec-dir) -name "*.sh" -exec ls -la {} \;
```

## Output

The command outputs a single line containing the absolute path to the libexec directory:

```
/usr/local/libexec/mulle-test
```

or

```
/opt/mulle-test/libexec/mulle-test
```

depending on the installation method.

## Troubleshooting

### Common Issues

**Empty or no output**
```bash
# Check if mulle-test is properly installed
which mulle-test

# Verify installation integrity
mulle-test --help
```

**Directory doesn't exist**
```bash
# Check the reported path
LIBEXEC_PATH=$(mulle-test libexec-dir)
echo "Path: $LIBEXEC_PATH"

# Verify directory exists
if [ ! -d "$LIBEXEC_PATH" ]; then
    echo "libexec directory missing: $LIBEXEC_PATH"
fi
```

**Permission denied**
```bash
# Check permissions on libexec directory
ls -ld $(mulle-test libexec-dir)

# Check if scripts are executable
find $(mulle-test libexec-dir) -name "*.sh" -exec ls -l {} \;
```

### Installation Issues

**Incomplete installation**
- Reinstall mulle-test using the package manager
- Check that all components were installed correctly
- Verify PATH includes mulle-test binary location

**Custom installation location**
- Check if mulle-test was installed in a non-standard location
- Verify MULLE_EXECUTABLE environment variable if set

## Technical Details

### Directory Structure
The libexec directory typically contains:
- `mulle-test-craft.sh` - Build and compilation logic
- `mulle-test-run.sh` - Test execution logic
- `mulle-test-locate.sh` - Test directory location logic
- `mulle-test-init.sh` - Test environment initialization
- Other supporting scripts and utilities

### Implementation
The libexec directory path is determined by:
1. Locating the main mulle-test executable
2. Finding the corresponding libexec directory relative to the executable
3. Using platform-specific path resolution logic

### Environment Variables
- `MULLE_TEST_LIBEXEC_DIR` - Override detected libexec directory
- `MULLE_EXECUTABLE` - Path to mulle-test executable (used for path resolution)

### Security Considerations
- libexec scripts are internal implementation details
- Direct execution of libexec scripts is not supported
- Use documented mulle-test commands instead of calling libexec scripts directly

## Related Commands

- [`version`](version.md) - Show mulle-test version
- [`uname`](uname.md) - System information
- [`arch`](arch.md) - Architecture information
- [`env`](env.md) - Environment variables

## See Also

- [mulle-sde documentation](../mulle-sde.md) - Build system integration
- [Installation guide](../installation.md) - Installation and setup
- [Development guide](../development.md) - Contributing to mulle-test