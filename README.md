# mulle-tests Cross platform tests

Test C and Objective C **library** code

Used in conjunction with [mulle-build](//github.com/mulle-nat/mulle-build) and
[cmake](//cmake.org). [mulle-bootstrap](//github.com/mulle-nat/mulle-bootstrap),
a dependency of **mulle-build** is a prerequisite, because some of its shell
library functions are used.


## Embed mulle-tests with mulle-bootstrap

This will place `mulle-tests` into `tests/mulle-tests`
```
mulle-bootstrap setting -r -g embedded_repositories 'https://github.com/mulle-nat/mulle-tests;tests/mulle-tests
mulle-bootstrap fetch
```

## Set it up

Let `mulle-tests-init` produce the two scripts `tests/build-test.sh` and
`tests/run-test.sh`:

```
./tests/mulle-tests/mulle-tests-init

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

## Running tests

Run the tests with `mulle-test`.


