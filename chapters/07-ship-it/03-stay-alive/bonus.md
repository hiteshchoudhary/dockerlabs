# Challenge

You've read about the OOM killer. Now summon it — on purpose, in a cage.

Run a container named **`chai-26-oom`** with a hard **32 MiB** memory cap and *no swap headroom* (`--memory 32m --memory-swap 32m`), whose command is a memory hog that must blow past the cap — the chapter's one-liner works verbatim in `alpine`:

```
sh -c 'head -c 100m /dev/zero | tail'
```

`tail` buffers all 100 MB looking for the last lines; the kernel stops it at 32 MiB. Don't use `-d` if you want the satisfaction of watching it die: the shell prints `Killed`. Then read the post-mortem like a professional: `docker inspect -f '{{.State.OOMKilled}} {{.State.ExitCode}}' chai-26-oom`.

**You pass when:** `chai-26-oom` exists with a 32 MiB memory limit, is no longer running, and the kernel's fingerprints are on it — `OOMKilled` is `true` (or exit code `137`).
