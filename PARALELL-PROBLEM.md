## The Actual Bug: `setsid` + Signal Interruption

### How `run-test` gets executed
When the scanner finds `run-test`, it dispatches it as a **parallel background job** via `__parallel_execute`. The outer `all_tests` is at `__parallel_end` → `wait`, blocked. The background job runs `run-test` through:

```
__parallel_execute subshell
  └─ _run_in_directory_parallel subshell
       └─ test::execute::a_out
            └─ mulle-timeout 360 ./run-test   ← TIMEOUT WRAPS IT
                 └─ setsid bash -c "./run-test"  ← NEW SESSION/PGID
                      └─ run-test
                           ├─ mulle-test run --no-run-script calli.none.m
                           │    └─ mulle-timeout 360 ./calli.none
                           │         └─ setsid bash -c "./calli.none"  ← nested NEW SESSION
                           ├─ mulle-test run --no-run-script calli.O0.m
                           │    └─ ...
                           └─ ... (48 total)
```

### Why things get orphaned

**`mulle-timeout` uses `setsid` to start the command in a new session** (line 182 in `mulle-timeout`). This fully detaches the child from the parent's process group. Any of these scenarios leave orphans:

1. **Ctrl-C / SIGINT**: Sent to the *foreground* process group. The outer `mulle-test` and `__parallel_end`'s `wait` receive it. `wait` is interrupted, returns non-zero. The main process exits. But the `setsid`-created bash running `run-test` is in a **different session** — it never received SIGINT.

2. **`fail()` in the main process**: `fail()` calls `exit 1`. If this fires between `__parallel_begin` (line 1083) and `__parallel_end` (line 1092), the `wait` never runs. Background jobs are orphaned. The `fail()` call most likely to fire here is from an unrelated parallel job's `__parallel_status` writing to `_parallel_statusfile` followed by something reading it... no, that's in `__parallel_end` too.

3. **The deeper nesting**: Each of the 48 child `mulle-test` processes also wraps its compiled test in `mulle-timeout` → `setsid`. So even if the middle layer (`run-test`) is killed, the currently-running compiled test is in *yet another* separate session and survives.

### Why "all tests fine" but background leak
`run-test` ignores individual child failures (line 181-183: `log_verbose` only). So tests DO run and "pass" (in the sense that they complete). But from the outer framework's perspective, `run-test` ran for 48× test duration and either timed out (360s) or completed. The orphan issue is about cleanup when interrupted, not about test results.

### The missing piece: no signal traps
There are **zero `trap` handlers** in `mulle-test-run.sh`, `mulle-test-execute.sh`, and `mulle-parallel.sh`. There's no cleanup mechanism when SIGINT/SIGTERM hits the main process. Combined with `setsid`, interrupted runs always leave orphans.
