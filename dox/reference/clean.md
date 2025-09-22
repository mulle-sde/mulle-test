# mulle-test clean

## Overview

The `clean` command removes build artifacts and temporary files from the test environment. It provides various cleaning levels to remove different types of generated files while preserving source code and configuration. This command is essential for maintaining a clean build environment and resolving build cache issues.

## Quick Start

### Basic Usage
```bash
# Clean test build artifacts
mulle-test clean

# Clean everything including dependencies
mulle-test clean all

# Clean temporary files only
mulle-test clean tidy
```

### Development Workflow
```bash
# Clean before fresh build
mulle-test clean
mulle-test craft

# Clean when build issues occur
mulle-test clean all
mulle-test run

# Quick clean for iterative development
mulle-test clean tidy
```

## Detailed Usage

### Command Syntax
```bash
mulle-test clean [level] [options]
```

### Cleaning Levels

| Level | Description |
|-------|-------------|
| (none) | Clean test project artifacts (default) |
| `tidy` | Clean temporary files and caches |
| `gravetidy` | Deep clean including dependency caches |
| `all` | Clean everything including dependencies |
| `dependencies` | Clean only dependency artifacts |
| `kitchen` | Clean intermediate build files |
| `exe` | Clean test executables only |

### Options

| Option | Description |
|--------|-------------|
| `--lenient` | Continue on errors |
| `--no-lenient` | Stop on first error |
| `-v` | Verbose output |
| `--dry-run` | Show what would be cleaned without doing it |

## How It Works

### Cleaning Process
The `clean` command performs the following operations:

1. **Target Identification**: Determines what files to clean based on level
2. **Safety Checks**: Verifies cleaning won't remove important files
3. **File Removal**: Removes specified artifacts and temporary files
4. **Dependency Cleanup**: Cleans dependency caches if requested
5. **State Reset**: Clears build state and cached information

### Cleaning Scope
- **Local Artifacts**: Removes files in test directory
- **Dependency Cache**: Clears cached dependency builds
- **Build State**: Resets incremental build information
- **Temporary Files**: Removes log files and intermediate data

## Examples

### Standard Cleaning
```bash
# Clean test build artifacts
mulle-test clean

# Clean everything
mulle-test clean all

# Clean temporary files
mulle-test clean tidy

# Deep clean with dependency reset
mulle-test clean gravetidy
```

### Selective Cleaning
```bash
# Clean only executables
mulle-test clean exe

# Clean only dependencies
mulle-test clean dependencies

# Clean intermediate files
mulle-test clean kitchen
```

### Safe Cleaning
```bash
# Preview what will be cleaned
mulle-test clean --dry-run

# Clean with verbose output
mulle-test clean -v

# Clean with error tolerance
mulle-test clean --lenient
```

### Workflow Integration
```bash
# Clean build cycle
mulle-test clean
mulle-test craft
mulle-test run

# Clean before debugging
mulle-test clean all
mulle-test crun --gdb test/debug_test.c

# Clean for release build
mulle-test clean all
mulle-test craft --release
```

## What Gets Cleaned

### Default Clean (no level specified)
- Test executables (`.exe` files)
- Object files (`.o` files)
- Build artifacts in `test/build-*`
- Generated header files (`include.h`, `import.h`)
- Test logs and temporary files

### Tidy Clean
- Temporary files (`*.tmp`, `*.log`)
- Cache files (`.cache` directories)
- Build state files
- Lock files and process artifacts

### Grave Tidy Clean
- All of tidy plus:
- Dependency build caches
- Downloaded dependency archives
- Build configuration caches
- Cross-compilation artifacts

### All Clean
- All of grave tidy plus:
- Complete dependency rebuilds
- All build directories
- Configuration files
- Environment caches

## File Preservation

### Always Preserved
- Source code files (`.c`, `.m`, `.h`, etc.)
- Test configuration files
- Expected output files (`.stdout`, `.stderr`)
- Project documentation
- Version control files

### Selectively Preserved
- Build caches (depending on clean level)
- Dependency sources (unless `all` specified)
- Configuration overrides
- Custom build scripts

## Troubleshooting

### Common Issues

#### Permission Errors
```bash
# Clean as appropriate user
sudo mulle-test clean all

# Check file ownership
ls -la test/

# Clean specific permissions
chmod -R u+w test/
mulle-test clean
```

#### Files Still Present
```bash
# Force clean stubborn files
mulle-test clean all --lenient

# Check for running processes
ps aux | grep test
killall test_executable

# Clean manually if needed
rm -rf test/build-*
```

#### Build Still Broken
```bash
# Complete environment reset
rm -rf test/
mulle-test init

# Check for external dependencies
mulle-sde dependency clean all

# Verify project structure
mulle-sde status
```

### Recovery Procedures
```bash
# Restore from backup if needed
# (Assuming backup exists)
cp -r backup/test test/

# Reinitialize test environment
mulle-test clean all
mulle-test init

# Check for corrupted files
find test/ -name "*.corrupt" -delete
```

## Advanced Usage

### Custom Clean Scripts
```bash
# Create custom clean script
cat > test/clean-custom.sh << 'EOF'
#!/bin/bash
# Custom cleaning logic
rm -rf custom_artifacts/
rm -f *.custom
EOF
chmod +x test/clean-custom.sh

# Use custom script
mulle-test clean custom
```

### Selective File Cleaning
```bash
# Clean specific file types
find test/ -name "*.o" -delete
find test/ -name "*.exe" -delete

# Clean old files
find test/ -mtime +7 -delete

# Clean large files
find test/ -size +100M -delete
```

### Integration with Build Systems
```bash
# Clean before CMake build
mulle-test clean
cmake -B build -S .
cmake --build build

# Clean for different configurations
mulle-test clean
cmake -B build-debug -S . -DCMAKE_BUILD_TYPE=Debug
cmake --build build-debug
```

### Automation Scripts
```bash
# Automated clean-build-test
#!/bin/bash
set -e

echo "Cleaning..."
mulle-test clean all

echo "Building..."
mulle-test craft

echo "Testing..."
mulle-test run

echo "Success!"
```

## Performance Considerations

### Clean Time Optimization
- **Incremental Cleaning**: Use appropriate clean levels
- **Parallel Operations**: Clean operations run in parallel when possible
- **Selective Cleaning**: Clean only what's necessary
- **Cache Preservation**: Keep useful caches when possible

### Disk Space Management
- **Large File Detection**: Identify and clean large artifacts
- **Age-based Cleaning**: Remove old temporary files
- **Compression**: Compress logs before cleaning
- **External Storage**: Move artifacts to external storage

## Related Commands

- **[`craft`](craft.md)**: Build test project
- **[`run`](run.md)**: Run tests
- **[`recraft`](recraft.md)**: Clean and rebuild
- **[`retest`](retest.md)**: Clean, rebuild and test

## Technical Details

### Clean Implementation
- **File System Traversal**: Safe recursive directory cleaning
- **Pattern Matching**: Uses glob patterns for file identification
- **Error Handling**: Continues cleaning despite individual file errors
- **Logging**: Records cleaning operations for debugging

### State Management
- **Build State Reset**: Clears incremental build information
- **Cache Invalidation**: Marks caches as invalid
- **Dependency Tracking**: Updates dependency state
- **Configuration Reset**: Restores default configurations

### Safety Mechanisms
- **Source Protection**: Never removes source files
- **Confirmation Prompts**: Warns before dangerous operations
- **Backup Preservation**: Maintains backup integrity
- **Recovery Options**: Provides undo capabilities

### Integration Points
- **Build System**: Coordinates with mulle-sde cleaning
- **Dependency Manager**: Cleans dependency artifacts
- **Cache Manager**: Invalidates various caches
- **File System**: Safe file removal operations