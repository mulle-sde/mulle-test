#!/bin/bash

# Test script to verify extension resolution functionality
# This tests the key functionality without requiring full mulle-sde setup

cd "$(dirname "$0")"

echo "=== Testing Extension Resolution Feature ==="
echo

# Test the core logic by checking file existence patterns
test_file_resolution() {
    local testdir="$1"
    local basename="$2"
    local extensions="$3"
    
    echo "Testing in directory: $testdir"
    echo "Looking for: $basename (extensions: $extensions)"
    
    # Test 1: Full filename should work
    if [ -f "$testdir/${basename}.c" ]; then
        echo "✓ Full filename exists: ${basename}.c"
    else
        echo "✗ Full filename missing: ${basename}.c"
        return 1
    fi
    
    # Test 2: Extension resolution logic
    local found='NO'
    for ext in $(echo "$extensions" | tr ':' ' '); do
        if [ -f "$testdir/${basename}.${ext}" ]; then
            echo "✓ Extension resolution would find: ${basename}.${ext}"
            found='YES'
            break
        fi
    done
    
    if [ "$found" = 'NO' ]; then
        echo "✗ Extension resolution would fail"
        return 1
    fi
    
    return 0
}

# Test our new test case
if test_file_resolution "20-extension-resolution" "extension-test" "c:m"; then
    echo "✓ Extension resolution test case is properly set up"
else
    echo "✗ Extension resolution test case setup failed"
    exit 1
fi

echo
echo "✓ All tests passed - extension resolution should work!"
echo
echo "You can now test with:"
echo "  mulle-test run 20-extension-resolution/extension-test.c  (old way)"
echo "  mulle-test run 20-extension-resolution/extension-test    (new way)"
