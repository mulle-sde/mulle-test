# test support scripts

Used in conjunction with **mulle-bootstrap** and **cmake**.


This is how you set it up, assuming your Objective-C library is the of the same
name as the current directory

```
#
# get scripts
#
echo "https://www.mulle-kybernetik.com/repositories/mulle-tests" >> .bootstrap/embedded_repositories
mulle-bootstrap fetch

#
# setup tests folder
#
mkdir tests
cd tests
ln -s "../mulle-tests/build-for-test.sh"
name="`basename ${PWD}"`

#
# create test scripts
#
cat > ./run-test.sh <<EOF
#!/usr/bin/env bash

LIBRARY_SHORTNAME="${name}"
LIB_PATH="../dependencies/lib"

. "../mulle-tests/run-test-m-common.sh"
. "../mulle-tests/run-test-common.sh"
EOF
chmod 755 run-test.sh
ln -s  run-test.sh run-all-tests.sh
```

