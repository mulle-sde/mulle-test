# Run tests

Use `mulle-sde test` to run the tests. Each test is
specified by a file with file extension `.<|PROJECT_EXTENSIONS|>`. This file
is compiled and linked with **<|PROJECT_NAME|>**.

* run specific test with `mulle-sde test run <testfile>`
* rerun only failed tests with `mulle-sde test rerun`


Extension   | Description
------------|-------------------------
`.<|PROJECT_EXTENSIONS|>`      | Test source
`.stdin`    | Command standard input
`.stdout`   | Expected command standard output


There are quite a few more options to tweak each test. 
See [mulle-test](//github.com/mulle-sde/mulle-test) for more info.
