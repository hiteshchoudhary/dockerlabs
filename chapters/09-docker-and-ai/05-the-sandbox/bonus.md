# Challenge

The jail stops mischief but not *stalling*: code that simply loops forever passes every check and wastes a core indefinitely. Add the missing bar — a **wall-clock timeout**.

Start a container named **`chai-39-timeout`** running something that never exits (an infinite loop). Enforce a hard time limit — a few seconds — after which the container is **force-removed** (`docker rm -f`). When the timeout fires, write a marker to **`workspace/ch39/timeout.txt`** recording that it was killed on the clock.

The canonical form on Linux is the `timeout` utility wrapping `docker wait`; on this Mac (no `timeout` binary by default) a small `sleep`-then-`docker rm -f` guard does the same job — either way, the pattern is *cap the wall clock, then reap*.

**You pass when:** the container `chai-39-timeout` no longer exists (it was reaped, not left running), and `workspace/ch39/timeout.txt` exists recording the timeout.
