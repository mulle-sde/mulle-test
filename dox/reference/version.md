# mulle-test version

## Overview

The `version` command displays the version number of the mulle-test tool. This is useful for verifying the installed version, checking for updates, and ensuring compatibility with other tools.

## Quick Start

```bash
# Display mulle-test version
mulle-test version
```

## Description

The `version` command prints the version string of the mulle-test executable. This version information follows semantic versioning and helps identify the specific release of mulle-test being used.

## Examples

### Basic Usage
```bash
# Get version information
mulle-test version
6.6.2
```

### Version Checking in Scripts
```bash
# Store version for comparison
VERSION=$(mulle-test version)
echo "mulle-test version: $VERSION"

# Check minimum version requirement
MIN_VERSION="6.0.0"
if [ "$(printf '%s\n' "$MIN_VERSION" "$VERSION" | sort -V | head -n1)" = "$MIN_VERSION" ]; then
    echo "Version requirement met"
else
    echo "Version $VERSION is too old, need at least $MIN_VERSION"
fi
```

### Integration with Build Systems
```bash
# Include version in build information
echo "Built with mulle-test $(mulle-test version)" > build_info.txt

# Version-specific feature detection
case "$(mulle-test version)" in
   6.*)
      echo "Using mulle-test 6.x features"
      ;;
   5.*)
      echo "Using mulle-test 5.x features"
      ;;
   *)
      echo "Unknown mulle-test version"
      ;;
esac
```

### Debugging and Support
```bash
# Report version when filing issues
echo "mulle-test version: $(mulle-test version)"
echo "System: $(uname -a)"

# Check for known version-specific issues
VERSION=$(mulle-test version)
if [ "$VERSION" = "6.6.2" ]; then
    echo "This is the latest version"
fi
```

## Output

The command outputs a single line containing the version string in semantic versioning format:

```
6.6.2
```

## Troubleshooting

### Common Issues

**No output or empty result**
```bash
# Verify mulle-test installation
which mulle-test

# Check if executable is corrupted
file $(which mulle-test)

# Reinstall if necessary
# (installation command depends on package manager)
```

**Unexpected version format**
```bash
# Check for development versions
mulle-test version | grep -E '^[0-9]+\.[0-9]+\.[0-9]+'

# Verify against expected format
VERSION=$(mulle-test version)
if [[ $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Valid version format"
else
    echo "Unexpected version format: $VERSION"
fi
```

### Version Comparison Issues

**String comparison problems**
```bash
# Use numeric comparison for version numbers
VERSION=$(mulle-test version)
IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION"

if [ "$MAJOR" -gt 6 ] || { [ "$MAJOR" -eq 6 ] && [ "$MINOR" -gt 6 ]; }; then
    echo "Version is newer than 6.6.x"
fi
```

**Locale-specific sorting issues**
```bash
# Use LC_ALL=C for consistent sorting
LC_ALL=C printf '%s\n' "6.6.2" "$(mulle-test version)" | sort -V
```

## Technical Details

### Version Format
The version follows semantic versioning (SemVer) format:
- `MAJOR.MINOR.PATCH`
- `MAJOR`: Breaking changes
- `MINOR`: New features, backward compatible
- `PATCH`: Bug fixes, backward compatible

### Implementation
The version is embedded in the executable at build time and corresponds to the release tag in the source repository.

### Environment Variables
- None directly affect version output
- Version is compiled into the binary

### Related Commands
- [`uname`](uname.md) - System information
- [`arch`](arch.md) - Architecture information
- [`libexec-dir`](libexec-dir.md) - Installation path

## See Also

- [Installation guide](../installation.md) - How to install mulle-test
- [Changelog](../changelog.md) - Version history and changes
- [Compatibility](../compatibility.md) - Version compatibility information