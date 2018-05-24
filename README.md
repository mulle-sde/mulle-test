# ☑︎ mulle-test, Cross platform tests

**mulle-test** tests your C or Objective C library.


Executable   | Description
-------------|--------------------------------
`mulle-test` | Run a single or multiple test


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
   return( 0);	  // important!
}
EOF

cat <<EOF > example/example.stdout
Hello World
EOF
```

## Running tests

Run the test with `mulle-test`.



## GitHub and Mulle kybernetiK

The development is done on
[Mulle kybernetiK](https://www.mulle-kybernetik.com/software/git/mulle-test/master).
Releases and bug-tracking are on [GitHub](https://github.com/mulle-sde/mulle-test).
