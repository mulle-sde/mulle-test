# mulle-test craftorder

## Overview

The `craftorder` command displays the order in which project components and dependencies are built. It shows the dependency graph and build sequence used by mulle-sde, helping users understand the build process and troubleshoot dependency issues. This command is essential for understanding complex project build orders and resolving build failures.

## Quick Start

### Basic Usage
```bash
# Show build order for current project
mulle-test craftorder

# Show detailed build information
mulle-test craftorder -v

# Show build order with dependencies
mulle-test craftorder --dependencies
```

### Analysis Usage
```bash
# Check for circular dependencies
mulle-test craftorder --check-circular

# Show only local components
mulle-test craftorder --local-only

# Export build order to file
mulle-test craftorder > build_order.txt
```

## Detailed Usage

### Command Syntax
```bash
mulle-test craftorder [options]
```

### Options

| Option | Description |
|--------|-------------|
| `-v` | Verbose output with detailed information |
| `--dependencies` | Show dependency relationships |
| `--local-only` | Show only local project components |
| `--check-circular` | Check for circular dependencies |
| `--dot` | Generate GraphViz DOT format output |
| `--json` | Generate JSON format output |
| `--output <file>` | Write output to specified file |
| `--reverse` | Show reverse dependency order |

## How It Works

### Build Order Analysis
The `craftorder` command performs the following steps:

1. **Dependency Analysis**: Examines project dependencies and their relationships
2. **Graph Construction**: Builds dependency graph showing build prerequisites
3. **Topological Sorting**: Orders components based on dependencies
4. **Cycle Detection**: Identifies circular dependency issues
5. **Output Generation**: Presents build order in readable format

### Dependency Types
- **Direct Dependencies**: Explicitly declared project dependencies
- **Transitive Dependencies**: Dependencies of dependencies
- **Build Dependencies**: Components required for building
- **Runtime Dependencies**: Components needed at runtime

### Build Phases
- **Configuration Phase**: Setting up build environment
- **Compilation Phase**: Compiling source code
- **Linking Phase**: Linking object files and libraries
- **Installation Phase**: Installing built components

## Examples

### Basic Build Order Display
```bash
# Show current project build order
mulle-test craftorder

# Show with verbose details
mulle-test craftorder -v

# Show dependency relationships
mulle-test craftorder --dependencies
```

### Dependency Analysis
```bash
# Check for circular dependencies
mulle-test craftorder --check-circular

# Show only local components
mulle-test craftorder --local-only

# Show reverse dependencies
mulle-test craftorder --reverse
```

### Output Formats
```bash
# Generate GraphViz DOT file
mulle-test craftorder --dot > dependencies.dot
dot -Tpng dependencies.dot > dependencies.png

# Generate JSON output
mulle-test craftorder --json > build_order.json

# Save to specific file
mulle-test craftorder --output build_sequence.txt
```

### Troubleshooting Builds
```bash
# Analyze build failures
mulle-test craftorder -v

# Check dependency issues
mulle-test craftorder --dependencies

# Verify build order
mulle-test craftorder --check-circular
```

## Understanding Build Order

### Dependency Graph
- **Nodes**: Project components and external dependencies
- **Edges**: Dependency relationships (A depends on B)
- **Roots**: Components with no dependencies
- **Leaves**: Components that nothing depends on

### Build Sequence
- **Topological Order**: Dependencies built before dependents
- **Parallel Building**: Independent components built simultaneously
- **Incremental Builds**: Only rebuild changed components
- **Cache Utilization**: Reuse unchanged dependency builds

### Common Patterns
- **Library Dependencies**: Core libraries built first
- **Header Dependencies**: Headers generated before compilation
- **Tool Dependencies**: Build tools created before use
- **Test Dependencies**: Test frameworks built before tests

## Troubleshooting

### Common Issues

#### Circular Dependencies
```bash
# Detect circular dependencies
mulle-test craftorder --check-circular

# Analyze dependency graph
mulle-test craftorder --dot | dot -Tpng -o graph.png

# Break circular dependency
# (Edit dependency declarations)
```

#### Missing Dependencies
```bash
# Check declared dependencies
mulle-sde dependency list

# Verify dependency availability
mulle-sde status

# Add missing dependencies
mulle-sde dependency add <dependency>
```

#### Build Order Problems
```bash
# Check build order
mulle-test craftorder -v

# Verify dependency declarations
cat sourcetree.config

# Update dependency information
mulle-sde reflect
```

#### Performance Issues
```bash
# Analyze build parallelism
mulle-test craftorder --dependencies

# Check for bottlenecks
# (Components with many dependents)

# Optimize build order
# (Reorder dependencies for better parallelism)
```

### Recovery Procedures
```bash
# Clean dependency cache
mulle-sde clean all

# Reinitialize build environment
mulle-test init

# Update dependency information
mulle-sde reflect

# Verify build order
mulle-test craftorder
```

## Advanced Usage

### Graph Visualization
```bash
# Generate dependency graph
mulle-test craftorder --dot > deps.dot

# Convert to PNG
dot -Tpng deps.dot > deps.png

# View graph
open deps.png  # or eog deps.png
```

### Build Order Scripting
```bash
# Extract build targets
mulle-test craftorder --json | jq '.targets[]'

# Create custom build script
#!/bin/bash
for target in $(mulle-test craftorder --json | jq -r '.targets[]'); do
    echo "Building: $target"
    # Custom build logic here
done
```

### CI/CD Integration
```bash
# Verify build order in CI
if ! mulle-test craftorder --check-circular; then
    echo "Circular dependency detected"
    exit 1
fi

# Archive build order
mulle-test craftorder --json > build_order.json
```

### Dependency Analysis
```bash
# Find unused dependencies
mulle-test craftorder --dependencies | grep -v used

# Analyze dependency depth
mulle-test craftorder --json | jq 'max_by(.depth)'

# Check for missing dependencies
mulle-test craftorder 2>&1 | grep "missing"
```

## Related Commands

- **[`craft`](craft.md)**: Build the project
- **[`fetch`](fetch.md)**: Fetch dependencies
- **[`clean`](clean.md)**: Clean build artifacts
- **[`recraft`](recraft.md)**: Clean and rebuild

## Technical Details

### Dependency Resolution
- **Source Tree Analysis**: Parses sourcetree configuration
- **Graph Algorithms**: Uses topological sorting for ordering
- **Cycle Detection**: Implements cycle detection algorithms
- **Cache Management**: Caches dependency information

### Output Formats
- **Text Format**: Human-readable build order
- **JSON Format**: Machine-readable structured data
- **DOT Format**: GraphViz graph description
- **Verbose Format**: Detailed dependency information

### Integration Points
- **mulle-sde**: Core build system integration
- **CMake**: Build configuration system
- **Dependency Manager**: External dependency handling
- **Cache System**: Build artifact caching

### Performance Characteristics
- **Analysis Speed**: Fast dependency graph construction
- **Memory Usage**: Minimal memory footprint
- **Scalability**: Handles large dependency graphs
- **Caching**: Results cached for repeated queries