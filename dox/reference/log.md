# mulle-test log

## Overview

The `log` command displays and manages build and test logs generated during mulle-test operations. It provides access to detailed execution information, error messages, and debugging data stored in the logging system. This command is essential for troubleshooting build failures, analyzing test results, and understanding the execution flow of mulle-test operations.

## Quick Start

### Basic Usage
```bash
# Show recent logs
mulle-test log

# Show specific log file
mulle-test log craft.log

# Show logs with timestamps
mulle-test log --tail 50
```

### Log Analysis
```bash
# Search for errors
mulle-test log | grep -i error

# Show build duration
mulle-test log craft.log | grep "Total time"

# Monitor live logs
mulle-test log --follow craft.log
```

## Detailed Usage

### Command Syntax
```bash
mulle-test log [options] [logfile]
```

### Options

| Option | Description |
|--------|-------------|
| `--tail <n>` | Show last n lines of log |
| `--head <n>` | Show first n lines of log |
| `--follow` | Follow log file (like tail -f) |
| `--grep <pattern>` | Filter log lines containing pattern |
| `--level <level>` | Filter by log level (debug, info, warning, error) |
| `--since <time>` | Show logs since specified time |
| `--until <time>` | Show logs until specified time |
| `--output <file>` | Save filtered log to file |
| `-v` | Verbose output |

## How It Works

### Log System Architecture
The `log` command interacts with the following components:

1. **Log Storage**: Retrieves logs from designated log directories
2. **Log Parsing**: Interprets log format and extracts relevant information
3. **Filtering**: Applies user-specified filters and search criteria
4. **Output Formatting**: Presents logs in readable format
5. **Real-time Monitoring**: Supports live log following

### Log Types
- **Build Logs**: Compilation and linking output
- **Test Logs**: Test execution results and failures
- **System Logs**: mulle-test internal operations
- **Debug Logs**: Detailed execution traces

### Log Levels
- **DEBUG**: Detailed internal operations
- **INFO**: General information and progress
- **WARNING**: Potential issues that don't stop execution
- **ERROR**: Failures and critical problems

## Examples

### Basic Log Viewing
```bash
# Show all available logs
mulle-test log

# Show specific build log
mulle-test log craft.log

# Show recent test logs
mulle-test log test.log
```

### Log Filtering
```bash
# Show only errors
mulle-test log --level error

# Search for specific messages
mulle-test log --grep "undefined reference"

# Show logs from last hour
mulle-test log --since "1 hour ago"
```

### Log Monitoring
```bash
# Follow build log in real-time
mulle-test log --follow craft.log

# Monitor with filtering
mulle-test log --follow --grep "error\|warning" craft.log

# Tail recent logs
mulle-test log --tail 100
```

### Log Analysis
```bash
# Count errors in log
mulle-test log craft.log | grep -c "error"

# Find longest compilation times
mulle-test log craft.log | grep "Compiling" | sort -k3 -n

# Extract failed tests
mulle-test log test.log | grep "FAILED"
```

## Log File Locations

### Default Log Directory
```
test/.mulle/var/log/
├── craft.log          # Build operations
├── test.log           # Test execution
├── clean.log          # Cleanup operations
├── fetch.log          # Dependency fetching
└── system.log         # mulle-test internal logs
```

### Log Rotation
- **Automatic Rotation**: Logs are rotated when they exceed size limits
- **Timestamped Archives**: Old logs are archived with timestamps
- **Compression**: Large archived logs may be compressed
- **Retention Policy**: Configurable log retention periods

### Log Format
```
[TIMESTAMP] [LEVEL] [COMPONENT] Message
2024-01-15 10:30:45 INFO craft Starting build process
2024-01-15 10:30:46 DEBUG compiler Compiling source.c
2024-01-15 10:31:02 ERROR linker Undefined symbol: foo
```

## Troubleshooting

### Common Issues

#### Missing Logs
```bash
# Check log directory exists
ls -la test/.mulle/var/log/

# Verify logging is enabled
mulle-test env | grep LOG

# Check permissions
ls -ld test/.mulle/var/log/
```

#### Empty Logs
```bash
# Check if operations actually ran
mulle-test log --tail 10

# Verify log level settings
mulle-test log --level debug

# Check for log rotation
ls -la test/.mulle/var/log/*.gz
```

#### Log Permission Issues
```bash
# Fix log directory permissions
chmod 755 test/.mulle/var/log/

# Fix log file permissions
chmod 644 test/.mulle/var/log/*.log

# Check ownership
chown -R $USER test/.mulle/var/log/
```

#### Large Log Files
```bash
# Compress old logs
gzip test/.mulle/var/log/*.log.1

# Clean old logs
find test/.mulle/var/log/ -name "*.log.*" -mtime +30 -delete

# Limit log size
# (Configure in mulle-test settings)
```

### Recovery Procedures
```bash
# Clear corrupted logs
rm test/.mulle/var/log/*.log

# Restart logging
mulle-test clean
mulle-test craft  # This will regenerate logs

# Restore from backup
cp backup/logs/*.log test/.mulle/var/log/

# Reinitialize log system
rm -rf test/.mulle/var/log/
mulle-test init
```

## Advanced Usage

### Log Analysis Scripts
```bash
# Extract build times
#!/bin/bash
mulle-test log craft.log | grep "Total time" | awk '{print $3}'

# Generate error summary
mulle-test log | grep -i error | sort | uniq -c | sort -nr

# Monitor build progress
mulle-test log --follow craft.log | grep "Compiling\|Linking"
```

### Custom Log Filtering
```bash
# Complex filtering
mulle-test log --grep "error\|warning" --level error --since "1 day ago"

# Export filtered logs
mulle-test log --grep "test.*failed" --output failed_tests.log

# Statistical analysis
mulle-test log | awk '/ERROR/ {errors++} /WARNING/ {warnings++} END {print "Errors:", errors, "Warnings:", warnings}'
```

### Integration with External Tools
```bash
# Send logs to external analyzer
mulle-test log craft.log | curl -X POST -d @- http://log-analyzer.example.com

# Archive logs
tar czf logs_$(date +%Y%m%d).tar.gz test/.mulle/var/log/

# Compare logs
diff <(mulle-test log craft.log) <(mulle-test log craft_old.log)
```

### CI/CD Integration
```bash
# Fail build on errors
if mulle-test log --level error | grep -q "error"; then
    echo "Build failed due to errors"
    exit 1
fi

# Archive logs for CI
mulle-test log --output build_$(date +%s).log

# Generate log summary
mulle-test log | grep -E "(ERROR|WARNING|INFO)" | tail -20 > log_summary.txt
```

## Log Management

### Log Rotation Configuration
```bash
# Configure log rotation
export MULLE_LOG_MAX_SIZE=10M
export MULLE_LOG_MAX_FILES=5
export MULLE_LOG_COMPRESS=yes

# Manual rotation
mulle-test log --rotate

# Clean old logs
mulle-test log --clean --older-than 7d
```

### Log Level Configuration
```bash
# Set global log level
export MULLE_LOG_LEVEL=DEBUG

# Set component-specific levels
export MULLE_CRAFT_LOG_LEVEL=INFO
export MULLE_TEST_LOG_LEVEL=DEBUG

# Temporary log level override
MULLE_LOG_LEVEL=TRACE mulle-test craft
```

### Log Output Configuration
```bash
# Enable colored output
export MULLE_LOG_COLOR=yes

# Set log format
export MULLE_LOG_FORMAT="[%timestamp] [%level] %message"

# Redirect logs
mulle-test craft 2>&1 | tee build.log
```

## Related Commands

- **[`run`](run.md)**: Run tests (generates test logs)
- **[`craft`](craft.md)**: Build project (generates build logs)
- **[`clean`](clean.md)**: Clean artifacts (generates clean logs)
- **[`env`](env.md)**: Show environment (includes log settings)

## Technical Details

### Log Storage Format
- **Text Format**: Human-readable plain text
- **Structured Format**: JSON or XML for machine processing
- **Binary Format**: Compressed binary logs for large volumes
- **Indexed Format**: Fast lookup for large log files

### Log Processing
- **Real-time Parsing**: Efficient parsing of streaming logs
- **Memory Efficient**: Low memory footprint for large logs
- **Concurrent Access**: Safe reading of active log files
- **Encoding Support**: UTF-8 and other character encodings

### Performance Considerations
- **I/O Optimization**: Buffered reading for performance
- **Indexing**: Optional log indexing for fast searches
- **Compression**: Automatic compression of archived logs
- **Rotation**: Efficient log rotation without service interruption

### Security Considerations
- **Log Sanitization**: Removal of sensitive information
- **Access Control**: Proper file permissions on log files
- **Audit Trail**: Immutable log records for compliance
- **Encryption**: Optional encryption for sensitive logs