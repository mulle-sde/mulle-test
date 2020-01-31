# mulle-test

☑︎ Runs tests and compares results against expectations

![Last version](https://img.shields.io/github/tag/mulle-sde/mulle-test.svg)


**mulle-test** tests your C or Objective C library. It is based on
**mulle-sde**. It will compile your project and all dependencies as *shared*
libraries. This is different from **mulle-sde**, which compiles *static*
libraries by default.

The reason for shared libraries is two-fold. For one the numerous test
executables are not so big. Secondly it supports some alternative testing
methodologies like 'UnitKit' better.



Executable   | Description
-------------|--------------------------------
`mulle-test` | Run a single or multiple test


## Writing a test

Here is a simple test, that checks that "Hello World" is properly output:

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

cat <<EOF > example/example.stdout
Hello World
EOF
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


If for a test there is no support file `<name>.<ext>` found, a file with the
name `default.<ext>` will be searched for instead.


### stdin stdout stderr

These file are binaries. Changes in whitespace will be detected-

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


## Install

### Manually

Install the pre-requisites:

* [mulle-bashfunctions](https://github.com/mulle-nat/mulle-bashfunctions)
* [mulle-make](https://github.com/mulle-nat/mulle-make)


Install latest version into `/usr` with sudo:

```
curl -L 'https://github.com/mulle-sde/mulle-test/archive/latest.tar.gz' \
 | tar xfz - && cd 'mulle-test-latest' && sudo ./install /usr
```

### Packages

OS    | Command
------|------------------------------------
macos | `brew install mulle-kybernetik/software/mulle-test`


## GitHub and Mulle kybernetiK

The development is done on
[Mulle kybernetiK](https://www.mulle-kybernetik.com/software/git/mulle-test/master).
Releases and bug-tracking are on [GitHub](https://github.com/mulle-sde/mulle-test).
