# mulle-tests Cross platform tests

Test C and Objective C library code

Used in conjunction with **mulle-bootstrap** and **cmake**. **mulle-bootstrap**
is a prerequisite, because some of its shell library functions are used.


## Embed mulle-testss with mulle-bootstrap

```
echo "https://www.mulle-kybernetik.com/repositories/mulle-tests" >> .bootstrap/embedded_repositories
mulle-bootstrap fetch
```

## Setting it up

This is how you set it up your tests, assuming your C library is of the same
name as the current directory and you already places `mulle-tests` in your
project directory. This creates a **tests** directory, where tests to be
written are placed:


```
name="`basename ${PWD}"`

mkdir tests
cd tests

#
# create build script
#
cat > ./build-test.sh <<EOF
#!/usr/bin/env bash

LIBRARY_SHORTNAME="${name}"

if [ -d ../.bootstrap ]
then
	( cd .. ; mulle-buildstrap -a )
fi

. "../mulle-tests/test-c-common.sh"
. "../mulle-tests/test-tools-common.sh"
. "../mulle-tests/build-test-common.sh"
EOF
chmod 755 build-test.sh

#
# create test script
#
cat > ./run-test.sh <<EOF
#!/usr/bin/env bash

LIBRARY_SHORTNAME="${name}"

. "../mulle-tests/test-c-common.sh"
. "../mulle-tests/test-tools-common.sh"
. "../mulle-tests/run-test-common.sh"
EOF
chmod 755 run-test.sh
```


## Writing a test

Here is a simple test, that checks that "Hello World" is properly output:

```
cd tests
mkdir example

cat <<EOF > example/example.c
#include <stdio.h>

main()
{
   printf( "Hello World\n");
   return( 0);	  // important!
}
EOF

cat <<EOF > example/example.stdout
Hello World
EOF
```
