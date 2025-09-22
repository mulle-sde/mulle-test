# mulle-test recraft

## Overview

The `recraft` command combines cleaning and rebuilding operations. It cleans build artifacts and then rebuilds the test project from scratch. This is useful when you need to ensure a fresh build environment without running tests, or when preparing for a clean test execution.

## Quick Start

### Basic Usage
```bash
# Clean and rebuild
mulle-test recraft

# Clean and rebuild with debug symbols
mulle-test recraft --debug

# Clean and rebuild with sanitizers
mulle-test recraft --sanitize-address
```

### Development Workflow
```bash
# Clean rebuild before testing
mulle-test recraft
mulle-test run

# Clean rebuild for debugging
mulle-test recraft --debug
mulle-test crun --gdb test/debug_test.c

# Clean rebuild for release
mulle-test recraft --release
```

## Detailed Usage

### Command Syntax
```bash
mulle-test recraft [options]
```

### Options

| Option | Description |
|--------|-------------|
| `--debug` | Build in debug mode |
| `--release` | Build in release mode |
| `--coverage` | Enable coverage analysis |
| `--sanitize-address` | Use address sanitizer |
| `--sanitize-thread` | Use thread sanitizer |
| `--sanitize-undefined` | Use undefined behavior sanitizer |
| `--valgrind` | Prepare for valgrind usage |
| `--no-clean` | Skip cleaning (not recommended) |
| `-V` | Verbose build output |

## How It Works

### Clean-Rebuild Process
The `recraft` command performs the following steps:

1. **Clean Phase**: Removes build artifacts and temporary files
2. **Dependency Check**: Verifies all dependencies are available
3. **Rebuild Phase**: Compiles entire test project from scratch
4. **Verification**: Ensures build completed successfully
5. **State Update**: Updates build state and cache information

### Cleaning Scope
- **Build Artifacts**: Removes object files, executables, libraries
- **Cache Files**: Clears build caches and intermediate files
- **Generated Files**: Removes auto-generated headers and sources
- **Dependency State**: Resets dependency build information

### Build Process
- **Fresh Compilation**: All source files recompiled
- **Clean Dependencies**: Dependencies rebuilt if necessary
- **Complete Linking**: All libraries relinked properly
- **State Preservation**: Maintains source file integrity

## Examples

### Standard Recrafting
```bash
# Basic clean rebuild
mulle-test recraft

# Clean rebuild with verbose output
mulle-test recraft -V

# Clean rebuild for debugging
mulle-test recraft --debug
```

### Advanced Building
```bash
# Clean rebuild with sanitizers
mulle-test recraft --sanitize-address --sanitize-undefined

# Clean rebuild with coverage
mulle-test recraft --coverage

# Clean rebuild for release
mulle-test recraft --release
```

### Workflow Integration
```bash
# Clean rebuild and test cycle
mulle-test recraft
mulle-test run

# Clean rebuild for specific testing
mulle-test recraft --debug
mulle-test crun test/specific_test.c

# Clean rebuild before CI
mulle-test recraft --release
mulle-test run --serial
```

### Troubleshooting Builds
```bash
# Clean rebuild when incremental fails
mulle-test recraft

# Force clean rebuild
mulle-test recraft --no-clean  # Wait, this doesn't make sense
# Actually, recraft always cleans, use craft for incremental

# Clean rebuild with different configuration
mulle-test recraft --debug
```

## Build Configuration

### Compiler Settings
- **Fresh Compilation**: All compiler flags reapplied
- **Sanitizer Integration**: Sanitizers properly configured
- **Optimization Levels**: Debug/Release settings applied
- **Warning Configuration**: Compiler warnings reset

### Dependency Management
- **Clean Dependencies**: Dependencies rebuilt from scratch
- **Cache Invalidation**: All dependency caches cleared
- **Link Updates**: Fresh linking of all components
- **Version Verification**: Dependency versions rechecked

## Troubleshooting

### Common Issues

#### Build Failures
```bash
# Check for missing dependencies
mulle-sde dependency list

# Verify build environment
mulle-sde status

# Check build logs
tail -f test/.mulle/var/log/craft.log
```

#### Performance Issues
```bash
# Use parallel builds
mulle-test recraft  # Uses default parallel jobs

# Limit job count
export MAKEFLAGS="-j2"
mulle-test recraft

# Use release for speed
mulle-test recraft --release
```

#### Disk Space Issues
```bash
# Clean before recraft if needed
mulle-test clean all
mulle-test recraft

# Check disk usage
df -h
du -sh test/
```

#### Dependency Issues
```bash
# Update dependencies
mulle-sde dependency update

# Clean dependency caches
mulle-sde clean all

# Reinitialize if needed
mulle-test init
```

### Recovery Procedures
```bash
# Complete rebuild
rm -rf test/
mulle-test init
mulle-test recraft

# Selective rebuild
mulle-test clean dependencies
mulle-test recraft

# Debug build process
mulle-test recraft -V 2>&1 | tee build.log
```

## Advanced Usage

### Custom Build Options
```bash
# Pass CMake options
mulle-test recraft -- -DCMAKE_BUILD_TYPE=RelWithDebInfo

# Custom compiler flags
mulle-test recraft -- -DOTHER_CFLAGS="-O3 -march=native"

# Build with specific toolchain
mulle-test recraft -- -DCMAKE_TOOLCHAIN_FILE=toolchain.cmake
```

### Integration with Scripts
```bash
# Automated rebuild script
#!/bin/bash
echo "Starting clean rebuild..."
mulle-test recraft
if [ $? -eq 0 ]; then
    echo "✓ Rebuild successful"
else
    echo "✗ Rebuild failed"
    exit 1
fi
```

### CI/CD Integration
```bash
# Full CI rebuild
mulle-test recraft --sanitize-address --coverage

# Fast CI rebuild
mulle-test recraft --release

# Debug CI rebuild
mulle-test recraft --debug -V
```

## Performance Considerations

### Build Time Optimization
- **Parallel Compilation**: Utilizes multiple CPU cores
- **Incremental Options**: Use `craft` for incremental builds when possible
- **Dependency Caching**: Avoid unnecessary dependency rebuilds
- **Resource Balancing**: Balance CPU and memory usage

### Resource Management
- **Memory Usage**: Monitor for large builds
- **Disk I/O**: Optimize for build speed vs space
- **Network Usage**: Consider dependency download times
- **Cache Strategy**: Balance clean builds vs cached builds

## Related Commands

- **[`craft`](craft.md)**: Build without cleaning
- **[`clean`](clean.md)**: Clean without rebuilding
- **[`run`](run.md)**: Run tests
- **[`retest`](retest.md)**: Clean, rebuild and test

## Technical Details

### Clean Implementation
- **File System Operations**: Safe removal of build artifacts
- **Cache Management**: Proper invalidation of build caches
- **State Reset**: Complete reset of build state
- **Error Recovery**: Graceful handling of clean failures

### Build Process Integration
- **CMake Integration**: Full CMake rebuild cycle
- **Dependency Resolution**: Complete dependency graph rebuild
- **Header Generation**: Fresh header file creation
- **Linker Updates**: Complete relinking of all components

### State Management
- **Build State Reset**: All incremental build information cleared
- **Cache Invalidation**: All caches marked invalid
- **Configuration Refresh**: All build configurations reloaded
- **Dependency Tracking**: Fresh dependency state

### Error Handling
- **Build Failure Detection**: Clear identification of build errors
- **Dependency Resolution**: Handling of missing dependencies
- **Configuration Validation**: Verification of build settings
- **Recovery Options**: Multiple recovery strategies