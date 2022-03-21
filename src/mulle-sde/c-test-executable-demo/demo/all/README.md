# Run tests

Use `mulle-sde test` or `mulle-test test` to run the tests. Each test is
specified by an `.args` file which gives command line parameters to the
executable **<|PROJECT_NAME|>** to be tested.

Extension   | Description
------------|-------------------------
`.args`     | Command arguments
`.stdin`    | Command standard input
`.stdout`   | Expected command standard output

There are quite a few more options to tweak each test. 
See [mulle-test](//github.com/mulle-sde/mulle-test) for more info.
