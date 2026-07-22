# Refactoring Summary: TEST_* Global Variables

## Overview
Refactored the codebase to use standardized global variables `TEST_PLATFORM`, `TEST_CONFIGURATION`, and `TEST_SDK` throughout. Eliminated `MULLE_PLATFORM` usage entirely. All `mulle-craft` calls now consistently pass platform, sdk, and configuration parameters.

## Changes Made

### 1. Main Entry Point (`mulle-test`)
- **Eliminated MULLE_PLATFORM** - no longer used
- **Initialized** three global variables directly:
  - `TEST_PLATFORM` - defaults to `MULLE_TEST_PLATFORMS` first entry, then `MULLE_UNAME`
  - `TEST_CONFIGURATION` - defaults to `Debug`
  - `TEST_SDK` - defaults to `Default`
- **Added validation** to ensure none of these variables are ever empty
- **Exported** all three variables for use throughout the codebase
- **Updated --platform option** to set `TEST_PLATFORM` directly

### 2. Option Parsing (`src/mulle-test-run.sh`)
- Updated to sync `TEST_PLATFORM` and `TEST_CONFIGURATION` when command-line options override defaults
- Removed all `MULLE_PLATFORM` assignments
- Added logging for both `OPTION_*` and `TEST_*` values for debugging

### 3. mulle-craft Calls - Now Consistent
All `mulle-craft searchpath` calls now include `--platform`, `--sdk`, and `--configuration`:

#### `src/mulle-test-compiler.sh`
- Framework and header searchpath calls now pass all three parameters

#### `src/mulle-test-execute.sh`
- Updated `test::execute::r_add_bin_lib_to_custompath()` signature to accept sdk parameter
- All binary and library searchpath calls now pass platform, sdk, and configuration
- Updated all function call sites to pass sdk parameter

#### `src/mulle-test-run.sh`
- `test::link_args::main` calls now pass `--platform`, `--sdk`, and `--configuration`

### 4. Complete MULLE_PLATFORM Elimination

Replaced all `MULLE_PLATFORM` references with `TEST_PLATFORM`:

#### `src/mulle-test-environment.sh`
- Replaced `MULLE_PLATFORM` with `TEST_PLATFORM` in `test::environment::r_get_test_datafile()`
- Replaced `OPTION_CONFIGURATION` with `TEST_CONFIGURATION`
- Replaced `OPTION_SDK` with `TEST_SDK`
- Updated validation check to use `TEST_PLATFORM`
- Simplified platform detection (removed fallback logic since TEST_PLATFORM is guaranteed non-empty)

#### `src/mulle-test-compiler.sh`
- Replaced `OPTION_CONFIGURATION` with `TEST_CONFIGURATION` in mulle-craft searchpath calls
- Replaced `MULLE_PLATFORM` with `TEST_PLATFORM` in:
  - Cross-compilation detection
  - Platform-specific linker flags
  - Target platform determination

#### `src/mulle-test-execute.sh`
- Replaced `MULLE_PLATFORM` with `TEST_PLATFORM` in:
  - Path construction for dependencies
  - Coverage profile file naming
  - Platform detection for emulator selection
- Replaced `OPTION_CONFIGURATION` with `TEST_CONFIGURATION` in dependency path construction

#### `src/mulle-test-run.sh`
- Replaced `OPTION_CONFIGURATION` with `TEST_CONFIGURATION` in c_flags matching
- Replaced `MULLE_PLATFORM` with `TEST_PLATFORM` in:
  - Sanitizer file checks
  - Test result logging messages

#### `src/mulle-test-cmake.sh`
- Replaced `OPTION_CONFIGURATION` with `TEST_CONFIGURATION` in:
  - Log settings
  - mulle-make invocation
- Replaced `MULLE_PLATFORM` with `TEST_PLATFORM` in:
  - Cross-compilation detection
  - Toolchain name construction

#### `src/mulle-test-link-args.sh`
- Updated local `OPTION_*` variables to initialize from `TEST_*` globals:
  - `OPTION_PLATFORM` from `TEST_PLATFORM`
  - `OPTION_CONFIGURATION` from `TEST_CONFIGURATION`
  - `OPTION_SDK` from `TEST_SDK`
- This maintains backward compatibility with the function's command-line parsing

## Benefits

1. **Consistency**: Single source of truth for platform, configuration, and SDK values
2. **Safety**: Validation ensures these critical values are never empty
3. **Clarity**: Clear distinction between:
   - `OPTION_*` variables (command-line parsing)
   - `TEST_*` variables (actual values used throughout)
4. **Maintainability**: Easier to track where values come from and how they're used
5. **Standardization**: All `mulle-craft` calls now consistently pass platform, sdk, and configuration
6. **Simplification**: Eliminated `MULLE_PLATFORM` entirely - one less variable to track

## Backward Compatibility

- `OPTION_*` variables still used for command-line parsing
- All existing command-line options continue to work
- Documentation references to `MULLE_PLATFORM` left unchanged (only in comments/help text)

## Validation

All modified shell scripts pass bash syntax checking (`bash -n`).
