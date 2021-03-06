# mulle-test

☑︎ Runs tests and compares results against expectations

![Last version](https://img.shields.io/github/tag/mulle-sde/mulle-test.svg)

**mulle-test** can test your C or Objective C library. But it can also test
shell scripts or binaries. Basically anything that creates text output.

The loop **mulle-test** does is compile, execute, diff. A test always fails,
if the return code is not 0. A test also fails, if there is an expected output
file present, and the actual produced output differs from the expectation.

As you would manually:

```
cc -o a.out a.c
./a.out > a.result
diff a.stdout a.result
```



Executable   | Description
-------------|--------------------------------
`mulle-test` | Run a single or multiple test


## Writing a test

Here is a simple test, that checks that "Hello World" is properly output.
It consists of a sourcefile `example.c` and the expected test output file
`example.stdout`:

```
mkdir test
cd test
mkdir example

cat <<EOF > example/example.c
#include <stdio.h>

main()
{
   printf( "Hello World\n");
   return( 0);   // important!
}
EOF

echo "Hello World" > example/example.stdout
```

## Running tests

Run the test with `mulle-test`.


## Test support files

Extension            | Description
---------------------|----------------------
`<name>.stdout`      | Contents must match exactly standard output of the test executable
`<name>.stdin`       | File fed to standard input of the test executable
`<name>.stderr`      | Contents must match exactly standard error of the test executable
`<name>.errors`      | Each line must grep for test diagnostics
`<name>.ccdiag`      | Each line must grep for compiler diagnostics
`<name>.environment` | Environment variables to set for test executable
`<name>.diff`        | An executable script that will be used to diff test output and expected output


If for a test there is no support file `<name>.<ext>` found, a file with the
name `default.<ext>` will be searched for instead.


### stdin stdout stderr

These file are binaries. Changes in whitespace only will be detected, and will
produce a warning.

### ccdiag

Each line is a `egrep` statement. An example file to expect a compiler warning
could be:

```
may not respond to
```

### errors

Usually a test that returns non-nil is assumed to have failed. If an `errors`
file is present, failure is the expected outcome. The contents of the file
are `egrep`ed with the test output.

### environment

The contents of this file are loaded before executing the test.

Example:

```
export FOO="1848"
```

### diff

This is an executable or script, that is used to compare the output of the
test with the expected files `stdout` and `stderr`. Typical use is to remove
some content before diffing such as:

```
#! /bin/sh
# remove all lines starting from "__DATE__" and ending with ");"
sed -e '/__DATE__/,/);/d'  | diff "$@"
```

## Technical info

**mulle-test** is based on **mulle-sde**. mulle-test compiles your project and
all  dependencies as *shared* libraries. This is different from **mulle-sde**,
which compiles *static* libraries by default.

The reason for shared libraries is two-fold. For one the numerous test
executables are not so big. Secondly it supports some alternative testing
methodologies like 'UnitKit' better.


## Install

### Manually

Install the pre-requisites:

* [mulle-bashfunctions](https://github.com/mulle-nat/mulle-bashfunctions)
* [mulle-make](https://github.com/mulle-nat/mulle-make)


Install latest version into `/usr` with sudo:

```
curl -L 'https://github.com/mulle-sde/mulle-test/archive/latest.tar.gz' \
 | tar xfz - && cd 'mulle-test-latest' && sudo ./bin/installer /usr
```

### Packages

OS    | Command
------|------------------------------------
macos | `brew install mulle-kybernetik/software/mulle-test`


## GitHub and Mulle kybernetiK

The development is done on
[Mulle kybernetiK](https://www.mulle-kybernetik.com/software/git/mulle-test/master).
Releases and bug-tracking are on [GitHub](https://github.com/mulle-sde/mulle-test).
