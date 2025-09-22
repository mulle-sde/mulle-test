# mulle-test init

## Overview

The `init` command initializes a test directory for mulle-test within an existing mulle-sde project. It creates a separate, independent mulle-sde project specifically for running tests, ensuring that test builds don't interfere with the main project development.

## Quick Start

### Basic Initialization
```bash
# Initialize test environment in current project
mulle-test init

# Initialize with custom test directory
mulle-test init -d custom-test-dir
```

### Advanced Setup
```bash
# Initialize with specific language settings
mulle-test init --project-language c --project-dialect objc

# Initialize with custom project name
mulle-test init --project-name my-custom-tests

# Initialize with specific file extensions
mulle-test init --project-extensions "c:m:h"
```

## Detailed Usage

### Command Syntax
```bash
mulle-test init [options]
```

### Options

| Option | Description |
|--------|-------------|
| `-d <directory>` | Specify test directory name (default: `test`) |
| `--project-language <name>` | Override test project language |
| `--project-dialect <name>` | Specify dialect (e.g., `objc` for Objective-C) |
| `--project-name <name>` | Set custom test project name |
| `--project-extensions <name>` | Override file extensions for test files |
| `--project-type <type>` | Set project type (`library` or `executable`) |
| `--github-name <name>` | Set GitHub username for project |
| `--standalone` | Create standalone test project |
| `--shared` | Create shared test project (default) |
| `--executable` | Create executable-style test project |

## How It Works

### Project Structure Creation
The `init` command performs the following steps:

1. **Detects Main Project**: Identifies the parent mulle-sde project
2. **Inherits Settings**: Copies language and dialect settings from main project
3. **Creates Test Project**: Initializes a new mulle-sde project in the test directory
4. **Configures Environment**: Sets up proper test environment variables
5. **Generates Headers**: Creates necessary include files for test compilation

### Default Behavior
- **Test Directory**: `test/` (can be overridden with `-d`)
- **Project Name**: `{main-project}-test`
- **Language**: Inherited from main project (defaults to `c`)
- **Dialect**: Inherited from main project (defaults to `c`)
- **Extensions**: Inherited from main project (defaults to `c`)

### Project Types
- **Library**: For testing shared libraries
- **Executable**: For testing standalone executables (default)

## Examples

### Basic Project Setup
```bash
# In your main project directory
cd my-project
mulle-test init

# This creates:
# my-project/test/
# ├── .mulle/
# ├── CMakeLists.txt
# ├── include.h (generated)
# └── ...
```

### Objective-C Project
```bash
# For Objective-C projects
mulle-test init --project-language c --project-dialect objc

# This creates:
# test/
# ├── import.h (generated for Objective-C)
# └── ...
```

### Custom Configuration
```bash
# Custom test directory and settings
mulle-test init -d test-suite \
                --project-name mylib-tests \
                --project-extensions "c:m:h" \
                --github-name myusername
```

### Standalone Test Project
```bash
# Create independent test project
mulle-test init --standalone --project-type library
```

## Generated Files

### Header Files
- **`include.h`**: Generated C header with all dependency includes
- **`import.h`**: Generated Objective-C header with all dependency imports (when dialect is `objc`)

### Project Structure
```
test/
├── .mulle/           # mulle-sde configuration
├── CMakeLists.txt    # Build configuration
├── include.h         # Generated includes
├── import.h          # Generated imports (objc)
└── mulle-sde         # Test project executable
```

## Environment Variables

The init command sets up several environment variables:

- **`TEST_PROJECT_NAME`**: Name of the main project being tested
- **`PROJECT_NAME`**: Name of the test project (usually `{main}-test`)
- **`PROJECT_LANGUAGE`**: Language for test compilation
- **`PROJECT_DIALECT`**: Language dialect (e.g., `objc`)
- **`PROJECT_EXTENSIONS`**: File extensions for test files

## Integration with Main Project

### Dependency Inheritance
The test project automatically inherits:
- **Dependencies**: All dependencies from the main project
- **Compiler Flags**: Relevant compiler settings
- **Linker Settings**: Library linking configuration
- **Build Configuration**: Debug/Release settings

### Separate Build Environment
- **Independent Builds**: Test project builds separately from main project
- **Isolated Artifacts**: Test binaries don't interfere with main project
- **Clean Separation**: Test failures don't affect main project builds

## Troubleshooting

### Common Issues

#### "Not a proper initialized test directory"
```bash
# Error message
Did not find a "test" directory (current/path)
Initialize tests with:
   mulle-test init
```

**Solution**: Run `mulle-test init` from the main project directory

#### Missing Dependencies
```bash
# If test project can't find main project dependencies
mulle-sde dependency list  # Check dependencies
mulle-sde craft           # Rebuild dependencies
```

#### Language Mismatch
```bash
# If test language doesn't match main project
mulle-test init --project-language c --project-dialect objc
```

### Verification Steps
```bash
# Check test directory structure
ls -la test/

# Verify mulle-sde setup
cd test && mulle-sde status

# Test basic functionality
mulle-test run
```

### Cleanup and Reset
```bash
# Remove test directory completely
rm -rf test/

# Reinitialize
mulle-test init
```

## Advanced Usage

### Custom Build Scripts
The init command supports integration with custom build scripts:
- **`craft-test`**: Custom crafting script
- **`build-test`**: Alternative build script
- **`run-test`**: Custom test runner

### Environment File Support
Test projects can use environment files for configuration:
- **`<testname>.environment`**: Per-test environment variables
- **`default.environment`**: Default environment for all tests

### Platform-Specific Configuration
```bash
# Platform-specific test settings
echo "MULLE_TEST_SANITIZER=address" > test/default.environment
```

## Related Commands

- **[`run`](run.md)**: Run tests in initialized test directory
- **[`craft`](craft.md)**: Build test dependencies
- **[`clean`](clean.md)**: Clean test artifacts
- **[`test-dir`](test-dir.md)**: Show test directory location

## Technical Details

### Implementation Notes
- Uses `mulle-sde init` with `mulle/wild` style for flexibility
- Generates header files automatically from dependency tree
- Supports both library and executable test project types
- Maintains clean separation between test and main project builds

### File Generation Process
1. **Dependency Analysis**: Scans main project dependencies
2. **Header Generation**: Creates `include.h`/`import.h` with all required includes
3. **Project Setup**: Initializes mulle-sde project with test-specific configuration
4. **Environment Setup**: Configures test environment variables

### Compatibility
- **mulle-sde**: Requires mulle-sde environment
- **Languages**: Supports C, C++, Objective-C
- **Platforms**: Linux, macOS, Windows (MinGW/MSYS)
- **Build Systems**: CMake-based projects