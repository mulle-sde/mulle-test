# mulle-test fetch

## Overview

The `fetch` command retrieves and updates project dependencies from their source repositories. It ensures all required external libraries and components are available locally, downloading them as needed. This command is essential for setting up the development environment and keeping dependencies current.

## Quick Start

### Basic Usage
```bash
# Fetch all project dependencies
mulle-test fetch

# Fetch specific dependency
mulle-test fetch <dependency-name>

# Update all dependencies to latest versions
mulle-test fetch --update
```

### Development Setup
```bash
# Initial dependency setup
mulle-test init
mulle-test fetch

# Update dependencies after changes
mulle-test fetch --update

# Fetch with verbose output
mulle-test fetch -v
```

## Detailed Usage

### Command Syntax
```bash
mulle-test fetch [options] [dependency...]
```

### Options

| Option | Description |
|--------|-------------|
| `--update` | Update dependencies to latest versions |
| `--recurse` | Fetch dependencies of dependencies |
| `--shallow` | Perform shallow clones (faster) |
| `--depth <n>` | Clone with limited history depth |
| `--branch <branch>` | Fetch specific branch |
| `--tag <tag>` | Fetch specific tag |
| `--no-recurse-submodules` | Skip git submodules |
| `-v` | Verbose output |
| `--dry-run` | Show what would be fetched |

## How It Works

### Fetch Process
The `fetch` command performs the following steps:

1. **Dependency Analysis**: Reads project dependency configuration
2. **Source Resolution**: Determines source URLs and versions
3. **Download Phase**: Clones or updates repositories
4. **Verification**: Ensures all dependencies are properly fetched
5. **Integration**: Updates local build environment

### Dependency Sources
- **Git Repositories**: Most common source type
- **Tar Archives**: Pre-packaged releases
- **Local Paths**: Symlinked local projects
- **Subversion**: Legacy version control systems

### Fetch Strategies
- **Full Clone**: Complete repository with history
- **Shallow Clone**: Limited history for faster downloads
- **Branch/Tag**: Specific version fetching
- **Recursive**: Include sub-dependencies

## Examples

### Basic Fetching
```bash
# Fetch all dependencies
mulle-test fetch

# Fetch specific dependency
mulle-test fetch mulle-foundation

# Update to latest versions
mulle-test fetch --update
```

### Advanced Fetching
```bash
# Shallow clone for faster setup
mulle-test fetch --shallow

# Fetch specific branch
mulle-test fetch --branch develop

# Fetch with limited history
mulle-test fetch --depth 10

# Verbose fetch process
mulle-test fetch -v
```

### Selective Fetching
```bash
# Fetch only build dependencies
mulle-test fetch --build-only

# Skip test dependencies
mulle-test fetch --no-test-deps

# Fetch recursive dependencies
mulle-test fetch --recurse
```

### CI/CD Integration
```bash
# Clean fetch for CI
mulle-test fetch --shallow --no-recurse-submodules

# Update dependencies in CI
mulle-test fetch --update --depth 1

# Verify fetch completion
mulle-test fetch --dry-run
```

## Dependency Management

### Dependency Types
- **Required Dependencies**: Must be present for building
- **Optional Dependencies**: Enhance functionality when available
- **Test Dependencies**: Only needed for testing
- **Development Dependencies**: Tools for development

### Version Control
- **Pinned Versions**: Specific commits/tags for stability
- **Branch Tracking**: Follow development branches
- **Latest Updates**: Get newest compatible versions
- **Version Ranges**: Flexible version specifications

### Cache Management
- **Local Cache**: Store downloaded repositories
- **Shared Cache**: Reuse across projects
- **Cleanup**: Remove unused cached dependencies
- **Update Tracking**: Monitor dependency changes

## Troubleshooting

### Common Issues

#### Network Problems
```bash
# Retry with different timeout
mulle-test fetch --timeout 300

# Use different protocol
export GIT_PROTOCOL=https
mulle-test fetch

# Check network connectivity
ping github.com
```

#### Authentication Issues
```bash
# Configure credentials
git config --global credential.helper store

# Use SSH instead of HTTPS
mulle-test fetch --ssh

# Check repository access
ssh -T git@github.com
```

#### Disk Space Issues
```bash
# Use shallow clones
mulle-test fetch --shallow --depth 1

# Clean old caches
mulle-sde clean caches

# Check available space
df -h
```

#### Repository Issues
```bash
# Check repository status
mulle-sde dependency status

# Reinitialize repository
rm -rf .mulle
mulle-test init

# Update repository URLs
mulle-sde dependency update-urls
```

### Recovery Procedures
```bash
# Complete reset
rm -rf dependencies/
mulle-test fetch

# Selective refetch
mulle-test fetch --update <problematic-dependency>

# Clean and refetch
mulle-sde clean all
mulle-test fetch
```

## Advanced Usage

### Custom Fetch Configuration
```bash
# Configure fetch options
export MULLE_FETCH_DEPTH=5
export MULLE_FETCH_BRANCH=main

# Custom fetch script
#!/bin/bash
for dep in $(mulle-sde dependency list); do
    mulle-test fetch "$dep" || echo "Failed: $dep"
done
```

### Integration with Scripts
```bash
# Automated setup script
#!/bin/bash
echo "Setting up project..."
mulle-test init
mulle-test fetch --shallow
mulle-test craft
echo "Setup complete!"
```

### Dependency Analysis
```bash
# List all dependencies
mulle-sde dependency list

# Check dependency status
mulle-sde dependency status

# Show dependency tree
mulle-sde dependency tree
```

### Performance Optimization
```bash
# Parallel fetching
mulle-test fetch --parallel 4

# Use local mirrors
export MULLE_FETCH_MIRROR_URL=https://mirror.example.com

# Cache optimization
mulle-sde clean caches --older-than 7d
```

## Related Commands

- **[`init`](init.md)**: Initialize test environment
- **[`craft`](craft.md)**: Build project
- **[`clean`](clean.md)**: Clean build artifacts
- **[`craftorder`](craftorder.md)**: Show build order

## Technical Details

### Fetch Implementation
- **Repository Cloning**: Git clone operations
- **Archive Extraction**: Tar/zip file handling
- **Symlink Creation**: Local dependency linking
- **Version Resolution**: Tag/branch/commit handling

### Network Protocols
- **HTTPS**: Secure repository access
- **SSH**: Key-based authentication
- **Git Protocol**: Fast git-specific protocol
- **Local File**: Direct file system access

### Storage Management
- **Repository Storage**: Local git repositories
- **Cache Storage**: Downloaded archives and metadata
- **Symlink Management**: Dependency path resolution
- **Version Tracking**: Commit/tag/branch information

### Error Handling
- **Network Timeouts**: Automatic retry mechanisms
- **Repository Errors**: Clear error reporting
- **Permission Issues**: Access right validation
- **Disk Space**: Available space checking