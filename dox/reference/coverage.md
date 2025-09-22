# mulle-test coverage

## Overview

The `coverage` command generates code coverage information for test execution. It provides detailed reports on which parts of the codebase are exercised by tests, helping identify untested code paths and measure test effectiveness. Coverage analysis supports both clang and mulle-objc coverage formats.

## Quick Start

### Basic Usage
```bash
# Generate coverage report
mulle-test coverage

# Run tests with coverage
mulle-test run --coverage

# Generate coverage for specific test
mulle-test crun --coverage test/my_test.c
```

### Coverage Workflow
```bash
# Clean build with coverage
mulle-test recraft --coverage

# Run tests to generate coverage data
mulle-test run

# Generate coverage report
mulle-test coverage

# View coverage results
# (Coverage files generated in build directory)
```

## Detailed Usage

### Command Syntax
```bash
mulle-test coverage [options]
```

### Options

| Option | Description |
|--------|-------------|
| `--clang` | Generate clang coverage (default) |
| `--objc` | Generate mulle-objc coverage |
| `--html` | Generate HTML coverage report |
| `--xml` | Generate XML coverage report |
| `--json` | Generate JSON coverage report |
| `--output <dir>` | Output directory for reports |
| `--include <pattern>` | Include files matching pattern |
| `--exclude <pattern>` | Exclude files matching pattern |
| `-v` | Verbose output |

## How It Works

### Coverage Generation Process
The `coverage` command performs the following steps:

1. **Instrumentation**: Compiles code with coverage instrumentation
2. **Test Execution**: Runs tests to collect coverage data
3. **Data Collection**: Gathers execution statistics
4. **Report Generation**: Creates human-readable coverage reports
5. **Analysis**: Calculates coverage percentages and metrics

### Coverage Types
- **Line Coverage**: Percentage of executable lines executed
- **Branch Coverage**: Percentage of branches executed
- **Function Coverage**: Percentage of functions called
- **File Coverage**: Coverage statistics per source file

### Output Formats
- **HTML Reports**: Interactive web-based coverage reports
- **XML Reports**: Machine-readable coverage data
- **JSON Reports**: Structured coverage information
- **Text Reports**: Simple command-line coverage summaries

## Examples

### Basic Coverage Generation
```bash
# Generate default coverage report
mulle-test coverage

# Generate HTML coverage report
mulle-test coverage --html

# Generate coverage in custom directory
mulle-test coverage --output coverage_reports
```

### Advanced Coverage Analysis
```bash
# Generate multiple report formats
mulle-test coverage --html --xml --json

# Include only specific files
mulle-test coverage --include "src/*.c"

# Exclude test files from coverage
mulle-test coverage --exclude "test/*"
```

### Integration with Testing
```bash
# Run tests with coverage instrumentation
mulle-test run --coverage

# Generate coverage for specific test
mulle-test crun --coverage test/unit_test.c

# Combine multiple test runs
mulle-test run --coverage
mulle-test rerun --coverage
mulle-test coverage  # Merge results
```

### CI/CD Integration
```bash
# Generate coverage for CI
mulle-test recraft --coverage
mulle-test run
mulle-test coverage --xml --output coverage/

# Check coverage thresholds
COVERAGE=$(mulle-test coverage --json | jq '.total.line_percent')
if (( $(echo "$COVERAGE < 80" | bc -l) )); then
    echo "Coverage too low: $COVERAGE%"
    exit 1
fi
```

## Coverage Data Interpretation

### Coverage Metrics
- **Line Coverage**: Lines executed / total executable lines
- **Branch Coverage**: Branches taken / total branches
- **Function Coverage**: Functions called / total functions
- **File Coverage**: Files with coverage / total files

### Coverage Levels
- **High Coverage (80%+)**: Well-tested code
- **Medium Coverage (50-80%)**: Moderately tested code
- **Low Coverage (<50%)**: Poorly tested code
- **Zero Coverage**: Untested code

### Coverage Gaps
- **Uncovered Lines**: Code never executed
- **Partial Branches**: Conditional logic not fully tested
- **Dead Code**: Unreachable code sections
- **Error Paths**: Exception/error handling not tested

## Troubleshooting

### Common Issues

#### No Coverage Data
```bash
# Ensure tests were run with coverage
mulle-test run --coverage

# Check if coverage tools are installed
which llvm-cov
which gcov

# Verify build configuration
mulle-test recraft --coverage
```

#### Incorrect Coverage
```bash
# Clean previous coverage data
mulle-test clean
mulle-test recraft --coverage

# Check source file paths
mulle-test coverage -v

# Verify test execution
mulle-test run --coverage --verbose
```

#### Report Generation Failures
```bash
# Check output directory permissions
mkdir -p coverage_reports
mulle-test coverage --output coverage_reports

# Verify report format support
mulle-test coverage --html  # Check HTML generation

# Use simpler format
mulle-test coverage  # Default text format
```

### Performance Issues
```bash
# Use faster coverage method
mulle-test coverage --clang  # Faster than objc

# Reduce report complexity
mulle-test coverage --exclude "test/*"

# Generate reports separately
mulle-test coverage --html
mulle-test coverage --xml
```

## Advanced Usage

### Custom Coverage Configuration
```bash
# Configure coverage options
export COVERAGE_OPTIONS="--include src/* --exclude test/*"
mulle-test coverage $COVERAGE_OPTIONS

# Set coverage thresholds
export MIN_LINE_COVERAGE=80
export MIN_BRANCH_COVERAGE=70

# Custom report generation
mulle-test coverage --output reports/ --html --xml
```

### Integration with Scripts
```bash
# Automated coverage analysis
#!/bin/bash
mulle-test recraft --coverage
mulle-test run

if mulle-test coverage --json > coverage.json; then
    echo "Coverage report generated"
    cat coverage.json | jq '.total'
else
    echo "Coverage generation failed"
    exit 1
fi
```

### Coverage Trends
```bash
# Track coverage over time
mulle-test coverage --json > coverage_$(date +%Y%m%d).json

# Compare coverage reports
# (Use external tools to compare JSON files)

# Generate coverage diff
# (Compare before/after changes)
```

## Related Commands

- **[`run`](run.md)**: Run tests (use with --coverage)
- **[`crun`](crun.md)**: Run single test (use with --coverage)
- **[`recraft`](recraft.md)**: Clean rebuild (use with --coverage)
- **[`rerun`](rerun.md)**: Rerun failed tests (use with --coverage)

## Technical Details

### Coverage Implementation
- **Instrumentation**: Compiler-based code instrumentation
- **Data Collection**: Runtime execution profiling
- **Report Generation**: Post-processing of coverage data
- **Format Conversion**: Multiple output format support

### File Formats
- **`.profraw`**: Raw coverage data (clang)
- **`.profdata`**: Indexed coverage data (clang)
- **`.gcda/.gcno`**: GCC coverage data
- **`.coverage`**: mulle-objc coverage data

### Integration Points
- **Build System**: CMake coverage configuration
- **Compiler**: Clang/GCC coverage instrumentation
- **Test Framework**: Test execution with coverage
- **Report Tools**: External coverage report generators

### Performance Impact
- **Build Time**: Increased compilation time
- **Runtime**: Slight performance overhead
- **Disk Space**: Additional coverage data files
- **Memory**: Increased memory usage during testing