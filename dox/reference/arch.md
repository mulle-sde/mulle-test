# mulle-test arch

## Overview

The `arch` command displays the current architecture that mulle-test is running on. This is useful for determining the target platform and ensuring compatibility with the build environment.

## Quick Start

```bash
# Display current architecture
mulle-test arch
```

## Description

The `arch` command prints the architecture identifier that mulle-test has detected for the current system. This information is derived from the compiler's target specification or system architecture detection.

## Examples

### Basic Usage
```bash
# Get current architecture
mulle-test arch
x86_64
```

### Integration with Scripts
```bash
# Check architecture in build scripts
ARCH=$(mulle-test arch)
echo "Building for architecture: $ARCH"

# Conditional compilation based on architecture
case "$(mulle-test arch)" in
   x86_64)
      echo "64-bit Intel architecture"
      ;;
   i386)
      echo "32-bit Intel architecture"
      ;;
   arm64)
      echo "ARM 64-bit architecture"
      ;;
   *)
      echo "Unknown architecture: $(mulle-test arch)"
      ;;
esac
```

### Cross-Platform Development
```bash
# Verify architecture matches expected target
EXPECTED_ARCH="x86_64"
CURRENT_ARCH=$(mulle-test arch)

if [ "$CURRENT_ARCH" != "$EXPECTED_ARCH" ]; then
   echo "Warning: Architecture mismatch!"
   echo "Expected: $EXPECTED_ARCH"
   echo "Current:  $CURRENT_ARCH"
fi
```

## Output

The command outputs a single line containing the architecture identifier:

- `x86_64` - 64-bit Intel/AMD architecture
- `i386` - 32-bit Intel architecture
- `arm64` - 64-bit ARM architecture
- `aarch64` - Alternative name for 64-bit ARM
- Other architecture names as detected by the system

## Troubleshooting

### Common Issues

**No output or empty result**
```bash
# Check if mulle-test is properly installed
which mulle-test

# Verify environment
mulle-test --help
```

**Unexpected architecture**
```bash
# Check system architecture directly
uname -m

# Compare with mulle-test output
echo "System: $(uname -m)"
echo "mulle-test: $(mulle-test arch)"
```

### Architecture Detection Problems

**Compiler not found**
- Ensure GCC or Clang is installed and in PATH
- Check `gcc -v` output manually

**Cross-compilation environment**
- Verify `MULLE_ARCH` environment variable is set correctly
- Check if cross-compiler is properly configured

## Technical Details

### Implementation
The architecture is determined by:
1. Checking the `MULLE_ARCH` environment variable if set
2. Parsing compiler target from `gcc -v` output
3. Falling back to `arch` or `uname -m` command

### Environment Variables
- `MULLE_ARCH` - Override detected architecture
- `CC` - Compiler to use for architecture detection

### Related Commands
- [`uname`](uname.md) - System information
- [`version`](version.md) - mulle-test version
- [`env`](env.md) - Environment variables

## See Also

- [mulle-sde documentation](../mulle-sde.md) - Build system architecture handling
- [Cross-compilation guide](../cross-compilation.md) - Working with different architectures