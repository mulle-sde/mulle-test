# mulle-test uname

## Overview

The `uname` command displays mulle-test's simplified version of the system uname information. This provides a standardized way to identify the operating system and platform that mulle-test is running on.

## Quick Start

```bash
# Display system uname information
mulle-test uname
```

## Description

The `uname` command prints mulle-test's simplified uname string, which identifies the operating system platform. This is useful for conditional logic in build scripts and for ensuring compatibility across different systems.

## Examples

### Basic Usage
```bash
# Get system uname
mulle-test uname
linux
```

### Platform Detection in Scripts
```bash
# Check platform in shell scripts
PLATFORM=$(mulle-test uname)
echo "Running on: $PLATFORM"

# Conditional operations based on platform
case "$(mulle-test uname)" in
   linux)
      echo "Linux-specific configuration"
      ;;
   darwin)
      echo "macOS-specific configuration"
      ;;
   mingw|msys)
      echo "Windows-specific configuration"
      ;;
   *)
      echo "Unknown platform: $(mulle-test uname)"
      ;;
esac
```

### Cross-Platform Build Scripts
```bash
# Set platform-specific variables
UNAME=$(mulle-test uname)
case "$UNAME" in
   darwin)
      CC="clang"
      LIB_EXT="dylib"
      ;;
   linux)
      CC="gcc"
      LIB_EXT="so"
      ;;
   mingw)
      CC="gcc"
      LIB_EXT="dll"
      ;;
esac

echo "Using compiler: $CC"
echo "Library extension: $LIB_EXT"
```

### Integration with Build Systems
```bash
# Export for use in Makefiles
export MULLE_UNAME=$(mulle-test uname)

# Use in configure scripts
./configure --host=$(mulle-test uname)
```

## Output

The command outputs a single line containing the simplified uname string:

- `linux` - Linux operating system
- `darwin` - macOS operating system
- `mingw` - MinGW Windows environment
- `msys` - MSYS Windows environment
- Other platform identifiers as detected

## Troubleshooting

### Common Issues

**Unexpected uname output**
```bash
# Compare with system uname
echo "mulle-test uname: $(mulle-test uname)"
echo "system uname: $(uname -s | tr '[:upper:]' '[:lower:]')"

# Check if running in different environment
echo "Current shell: $SHELL"
echo "PATH: $PATH"
```

**Empty or no output**
```bash
# Verify mulle-test installation
which mulle-test

# Check environment variables
echo "MULLE_UNAME: $MULLE_UNAME"
```

### Platform Detection Problems

**Incorrect platform identification**
- Check if running in a container or VM
- Verify cross-compilation environment
- Check for chroot or similar environments

**Missing platform support**
- Report the issue with the detected uname string
- Include system information: `uname -a`

## Technical Details

### Implementation
The uname is determined by:
1. Checking the `MULLE_UNAME` environment variable if set
2. Using system `uname -s` command output
3. Converting to lowercase for consistency
4. Applying platform-specific simplifications

### Environment Variables
- `MULLE_UNAME` - Override detected uname
- `MULLE_HOSTNAME` - Host system identifier

### Platform Mappings
- `Linux` → `linux`
- `Darwin` → `darwin`
- `MINGW32_NT-*` → `mingw`
- `MINGW64_NT-*` → `mingw`
- `MSYS_NT-*` → `msys`

### Related Commands
- [`arch`](arch.md) - Architecture information
- [`version`](version.md) - mulle-test version
- [`env`](env.md) - Environment variables

## See Also

- [System compatibility guide](../compatibility.md) - Platform-specific considerations
- [Cross-compilation guide](../cross-compilation.md) - Building for different platforms
- [Build system documentation](../mulle-sde.md) - Platform handling in mulle-sde