# Run tests

Use `mulle-sde test` or `mulle-test test` to run the tests. Each test is
specified by a file with file extensions `.m` or `.aam`. This file
is compiled and linked with **<|PROJECT_NAME|>**.

Extension    | Description
-------------|-------------------------
`.m`, `.aam` | Test source
`.stdin`     | Command standard input
`.stdout`    | Expected command standard output


There are quite a few more options to tweak each test. 
See [mulle-test](//github.com/mulle-sde/mulle-test) for more info.
