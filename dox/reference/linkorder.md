# mulle-test linkorder

## Overview

The `linkorder` command displays the order in which libraries and object files are linked during the build process. It shows the dependency relationships and linking sequence used by the linker, helping diagnose linking issues and understand the final executable structure. This command is crucial for resolving symbol resolution problems and optimizing link performance.

## Quick Start

### Basic Usage
```bash
# Show link order for current project
mulle-test linkorder

# Show detailed linking information
mulle-test linkorder -v

# Show link order with library dependencies
mulle-test linkorder --libraries
```

### Analysis Usage
```bash
# Check for undefined symbols
mulle-test linkorder --undefined

# Show circular library dependencies
mulle-test linkorder --circular

# Export link order to file
mulle-test linkorder > link_sequence.txt
```

## Detailed Usage

### Command Syntax
```bash
mulle-test linkorder [options]
```

### Options

| Option | Description |
|--------|-------------|
| `-v` | Verbose output with detailed information |
| `--libraries` | Show library dependency relationships |
| `--objects` | Show object file linking order |
| `--undefined` | Check for undefined symbols |
| `--circular` | Detect circular library dependencies |
| `--dot` | Generate GraphViz DOT format output |
| `--json` | Generate JSON format output |
| `--output <file>` | Write output to specified file |
| `--reverse` | Show reverse linking dependencies |

## How It Works

### Link Order Analysis
The `linkorder` command performs the following steps:

1. **Build Analysis**: Examines the build configuration and dependencies
2. **Dependency Resolution**: Determines library and object file relationships
3. **Topological Sorting**: Orders components for proper symbol resolution
4. **Linker Simulation**: Simulates the linking process
5. **Output Generation**: Presents link order in readable format

### Linking Concepts
- **Symbol Resolution**: Functions and variables must be defined before use
- **Library Dependencies**: Libraries must be linked in dependency order
- **Object File Order**: Object files within libraries matter for static linking
- **Linker Scripts**: Custom linking rules and memory layouts

### Link Types
- **Static Linking**: Object files and static libraries
- **Dynamic Linking**: Shared libraries loaded at runtime
- **Incremental Linking**: Partial linking for development
- **Final Linking**: Complete executable creation

## Examples

### Basic Link Order Display
```bash
# Show current project link order
mulle-test linkorder

# Show with verbose details
mulle-test linkorder -v

# Show library relationships
mulle-test linkorder --libraries
```

### Symbol Analysis
```bash
# Check for undefined symbols
mulle-test linkorder --undefined

# Show symbol dependencies
mulle-test linkorder --symbols

# Analyze library usage
mulle-test linkorder --library-usage
```

### Output Formats
```bash
# Generate GraphViz DOT file
mulle-test linkorder --dot > link_deps.dot
dot -Tpng link_deps.dot > link_deps.png

# Generate JSON output
mulle-test linkorder --json > link_order.json

# Save to specific file
mulle-test linkorder --output link_sequence.txt
```

### Troubleshooting Linking
```bash
# Analyze link failures
mulle-test linkorder -v

# Check library dependencies
mulle-test linkorder --libraries

# Verify link order
mulle-test linkorder --circular
```

## Understanding Link Order

### Library Dependencies
- **Direct Dependencies**: Libraries explicitly linked
- **Transitive Dependencies**: Dependencies of linked libraries
- **System Libraries**: Standard system libraries
- **Custom Libraries**: Project-specific libraries

### Linking Sequence
- **Object Files First**: Application object files
- **Library Order**: Most dependent to least dependent
- **System Libraries Last**: Standard libraries at the end
- **Linker Scripts**: Custom ordering rules

### Common Patterns
- **Framework Linking**: UI frameworks linked before base libraries
- **Plugin Systems**: Plugin libraries linked after main application
- **Static Archives**: Archive libraries in dependency order
- **Shared Objects**: Dynamic libraries with proper load order

## Troubleshooting

### Common Issues

#### Undefined Symbols
```bash
# Check symbol definitions
mulle-test linkorder --undefined

# Verify library order
mulle-test linkorder --libraries

# Check object file contents
nm -g libmylib.a
```

#### Circular Dependencies
```bash
# Detect circular dependencies
mulle-test linkorder --circular

# Analyze dependency graph
mulle-test linkorder --dot | dot -Tpng -o graph.png

# Break circular dependency
# (Restructure library dependencies)
```

#### Link Order Problems
```bash
# Check current link order
mulle-test linkorder -v

# Verify library declarations
cat CMakeLists.txt

# Update link order
# (Modify CMakeLists.txt or linker scripts)
```

#### Performance Issues
```bash
# Analyze link time
time mulle-test craft

# Check library sizes
ls -lh lib*.a lib*.so

# Optimize link order
# (Reorder libraries for better cache performance)
```

### Recovery Procedures
```bash
# Clean and relink
mulle-test clean
mulle-test craft

# Force complete rebuild
mulle-test recraft

# Check build logs
tail -f test/.mulle/var/log/craft.log
```

## Advanced Usage

### Link Order Visualization
```bash
# Generate dependency graph
mulle-test linkorder --dot > link.dot

# Convert to PNG
dot -Tpng link.dot > link.png

# View graph
open link.png  # or eog link.png
```

### Custom Link Analysis
```bash
# Extract link targets
mulle-test linkorder --json | jq '.libraries[]'

# Create custom link script
#!/bin/bash
for lib in $(mulle-test linkorder --json | jq -r '.libraries[]'); do
    echo "Linking: $lib"
    # Custom link logic here
done
```

### CI/CD Integration
```bash
# Verify link order in CI
if ! mulle-test linkorder --circular; then
    echo "Circular dependency detected"
    exit 1
fi

# Archive link order
mulle-test linkorder --json > link_order.json
```

### Link Optimization
```bash
# Analyze link performance
mulle-test linkorder --performance

# Check for unused libraries
mulle-test linkorder --unused

# Optimize library order
# (Reorder CMakeLists.txt for better linking)
```

## Related Commands

- **[`craft`](craft.md)**: Build the project
- **[`craftorder`](craftorder.md)**: Show build order
- **[`run`](run.md)**: Run tests
- **[`clean`](clean.md)**: Clean build artifacts

## Technical Details

### Linker Integration
- **GNU ld**: Standard Linux linker
- **LLVM lld**: Modern fast linker
- **macOS ld**: Apple-specific linker
- **Linker Scripts**: Custom linking rules

### Symbol Resolution
- **Symbol Tables**: Function and variable definitions
- **Weak Symbols**: Optional symbol definitions
- **Symbol Visibility**: Public vs private symbols
- **Versioning**: Symbol version management

### Library Formats
- **Static Libraries (.a)**: Archive of object files
- **Shared Libraries (.so/.dylib)**: Dynamic link libraries
- **Object Files (.o)**: Compiled source files
- **Linker Scripts**: Custom linking instructions

### Performance Factors
- **Link Time**: Time to resolve all symbols
- **Memory Usage**: RAM required for linking
- **Disk I/O**: Library file access patterns
- **Cache Efficiency**: Symbol lookup optimization