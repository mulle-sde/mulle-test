# mulle-test env

## Overview

The `env` command displays all environment variables available to mulle-test, sorted alphabetically. This is useful for debugging environment-related issues, checking configuration, and understanding the runtime context.

## Quick Start

```bash
# Display all environment variables
mulle-test env
```

## Description

The `env` command executes the system's `env` command and sorts the output alphabetically. This provides a comprehensive view of all environment variables that are accessible to mulle-test during execution.

## Examples

### Basic Usage
```bash
# View all environment variables
mulle-test env
```

### Filtering Specific Variables
```bash
# Find PATH-related variables
mulle-test env | grep PATH

# Find mulle-specific variables
mulle-test env | grep MULLE

# Find compiler-related variables
mulle-test env | grep CC
```

### Saving Environment for Debugging
```bash
# Save environment to file for analysis
mulle-test env > environment_snapshot.txt

# Compare environments
mulle-test env > env1.txt
# ... make some changes ...
mulle-test env > env2.txt
diff env1.txt env2.txt
```

### Integration with Scripts
```bash
# Extract specific variable
MULLE_ARCH=$(mulle-test env | grep '^MULLE_ARCH=' | cut -d= -f2)
echo "Architecture: $MULLE_ARCH"

# Check if variable is set
if mulle-test env | grep -q '^MY_VAR='; then
    echo "MY_VAR is set"
else
    echo "MY_VAR is not set"
fi
```

### Debugging Environment Issues
```bash
# Check for missing required variables
REQUIRED_VARS=("PATH" "MULLE_HOSTNAME" "MULLE_UNAME")
for var in "${REQUIRED_VARS[@]}"; do
    if ! mulle-test env | grep -q "^${var}="; then
        echo "Warning: $var is not set"
    fi
done

# Verify PATH contains expected directories
if mulle-test env | grep '^PATH=' | grep -q '/usr/local/bin'; then
    echo "PATH includes /usr/local/bin"
else
    echo "Warning: /usr/local/bin not in PATH"
fi
```

## Output

The command outputs environment variables in the format `VARIABLE_NAME=value`, one per line, sorted alphabetically:

```
CC=gcc
CFLAGS=-O2 -g
HOME=/home/user
MULLE_ARCH=x86_64
MULLE_HOSTNAME=myhost
MULLE_UNAME=linux
PATH=/usr/local/bin:/usr/bin:/bin
PWD=/home/user/project
SHELL=/bin/bash
...
```

## Troubleshooting

### Common Issues

**Empty output**
```bash
# Check if env command is available
which env

# Verify mulle-test can execute commands
mulle-test --help
```

**Variables not showing expected values**
```bash
# Compare with direct env command
mulle-test env | grep MY_VAR
env | grep MY_VAR

# Check for variable name typos
mulle-test env | grep -i myvar
```

**Sorting issues**
```bash
# Verify sort command availability
which sort

# Check locale settings
locale
```

### Environment Variable Problems

**Missing required variables**
```bash
# Check for common required variables
mulle-test env | grep -E '^(PATH|HOME|USER|SHELL)='

# Verify mulle-specific variables
mulle-test env | grep '^MULLE_'
```

**Incorrect variable values**
```bash
# Compare with expected values
EXPECTED_PATH="/usr/local/bin:/usr/bin"
CURRENT_PATH=$(mulle-test env | grep '^PATH=' | cut -d= -f2)

if [ "$CURRENT_PATH" != "$EXPECTED_PATH" ]; then
    echo "PATH mismatch!"
    echo "Expected: $EXPECTED_PATH"
    echo "Current:  $CURRENT_PATH"
fi
```

### Integration Issues

**Script compatibility**
```bash
# Ensure scripts handle sorted output correctly
mulle-test env | while IFS='=' read -r key value; do
    echo "Variable: $key"
    echo "Value: $value"
    echo "---"
done
```

**Parsing complex values**
```bash
# Handle values with spaces or special characters
mulle-test env | while IFS='=' read -r key value; do
    # Use printf to handle special characters safely
    printf "Variable: %s\n" "$key"
    printf "Value: %s\n" "$value"
done
```

## Technical Details

### Implementation
The command executes:
1. `env` - to get all environment variables
2. `sort` - to sort output alphabetically

### Output Format
- Variables are listed as `NAME=value`
- One variable per line
- Sorted alphabetically by variable name
- Values preserve original formatting and special characters

### Environment Variables
The output includes all environment variables available to the mulle-test process, including:
- System variables (PATH, HOME, USER, etc.)
- mulle-specific variables (MULLE_*, etc.)
- User-defined variables
- Shell-specific variables

### Security Considerations
- Environment variables may contain sensitive information
- Be cautious when logging or sharing environment output
- Consider filtering sensitive variables in production scripts

## Related Commands

- [`version`](version.md) - Show mulle-test version
- [`uname`](uname.md) - System information
- [`arch`](arch.md) - Architecture information
- [`libexec-dir`](libexec-dir.md) - Installation path

## See Also

- [Environment setup guide](../environment.md) - Setting up mulle-test environment
- [Configuration guide](../configuration.md) - mulle-test configuration options
- [Debugging guide](../debugging.md) - Troubleshooting mulle-test issues