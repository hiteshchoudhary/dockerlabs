# CMD vs ENTRYPOINT

Two Dockerfile instructions decide what a container runs. They look interchangeable, half the internet uses them interchangeably, and interviewers love them precisely because they aren't. Here's the version you'll never have to un-learn.

## One question: what is this image?

- **`CMD`** sets the *default* command — a suggestion. Anything you type after the image name in `docker run` **replaces it entirely**. You've been doing this since Chapter 1: `docker run alpine echo "hello chaicode"` wiped alpine's default `/bin/sh` and ran your echo instead.
- **`ENTRYPOINT`** sets the *fixed* executable — a commitment. Arguments after the image name don't replace it; they're **appended to it** as arguments.

And the pattern that makes both shine is using them *together*:

```dockerfile
ENTRYPOINT ["ping"]
CMD ["localhost"]
```

- `docker run pinger` → runs `ping localhost` — sensible default.
- `docker run pinger google.com` → runs `ping google.com` — same tool, your target.

So ask of every image: is it a *service* or a *tool*? A service (like the ChaiCode API) usually gets by with plain `CMD` — the default matters, and on the rare occasion someone overrides it (`docker run chai-07-api:v1 sh` to poke around), replacing the whole command is exactly what they want. A tool — something that behaves like a CLI binary — wants `ENTRYPOINT` for the executable and `CMD` for default arguments. That's how the official images you already use are built; run `docker image inspect postgres --format '{{.Config.Entrypoint}} {{.Config.Cmd}}'` sometime and you'll find `docker-entrypoint.sh` + `postgres`.

At runtime you can override each independently: arguments after the image name override `CMD`; the `--entrypoint` flag overrides `ENTRYPOINT`. That flag is a debugging staple — when a container dies instantly and you need a look inside its image, `docker run --rm --entrypoint sh -it <image>` gets you a shell where the normal startup would have crashed.

## Exec form vs shell form

Both instructions accept two syntaxes, and the difference bites harder than the CMD/ENTRYPOINT distinction itself:

```dockerfile
CMD ["node", "server.js"]     # exec form — JSON array
CMD node server.js            # shell form — plain string
```

**Exec form** runs your program *directly* — `node` becomes the container's process, PID 1, exactly as written. **Shell form** wraps it: Docker actually runs `/bin/sh -c "node server.js"`, so PID 1 is a shell, and your program is its child.

Three consequences, in ascending order of pain:

1. Shell form gives you shell features — variable expansion, pipes. Occasionally useful, and `$VAR` silently *not* expanding in exec form is a classic confusion (exec form has no shell, so nothing expands).
2. With a shell-form `ENTRYPOINT`, appended arguments go nowhere — `sh -c` ignores them. Your carefully designed tool image stops accepting arguments and nothing tells you why.
3. **Signals.** `docker stop` sends SIGTERM to PID 1. If PID 1 is `sh`, it doesn't forward the signal; your app never hears it, the 10-second grace period expires, and the app gets SIGKILLed mid-write. Remember Chapter 2, wondering why some containers take exactly ten seconds to stop? Shell form is the usual culprit.

The rule the whole ecosystem follows: **exec form, always, for both instructions** — `docker image inspect` should show real JSON arrays in `.Config.Entrypoint` and `.Config.Cmd`, never a smuggled `/bin/sh -c`. Reach for shell form only when you consciously need a shell, and then prefer being explicit: `CMD ["sh", "-c", "node server.js"]`.

:::notebook PID 1, zombies, and why tini exists
On a normal Linux box, PID 1 is `init`/`systemd`, which carries two special duties: it **adopts orphaned processes** and **reaps zombies** (dead children whose exit status nobody collected — each one pins a process-table slot until reaped). In a container's PID namespace, *your app* is PID 1, and it inherits the duties without the training: most apps never call `wait()` for adopted orphans. A long-running container whose app spawns and abandons subprocesses slowly fills with zombies — `docker top` shows a graveyard of `<defunct>` entries.

PID 1 is also exempt from default signal handlers: an unhandled SIGTERM that would kill any normal process does nothing to PID 1, which is the second reason containers ignore `docker stop`.

The fix is a 25 KB init called **tini**: it runs as PID 1, forwards every signal to your app, reaps every zombie, and Docker ships it built in — `docker run --init ...` (or `init: true` in Compose, Part 6). For a single-process Node/Go server it's optional; the moment your container forks workers or shells out, it's cheap insurance. The rule of thumb many teams adopt: `--init` everywhere, think never.
:::

## The tool you're about to build

In `workspace/ch09/` there's a five-line script, `greet.sh` — it echoes `chai says:` followed by whatever arguments it receives. Your job is to package it the way real CLI tool images (think `docker run amazon/aws-cli s3 ls`) are packaged: `ENTRYPOINT` locks in the executable, `CMD` supplies a default argument, and users swap the argument just by typing after the image name. You'll `COPY` the script somewhere respectable like `/usr/local/bin/`, and since `RUN` is at your disposal, a `RUN chmod +x` makes sure it's executable no matter what the host thought.

Build it, then interrogate your own image with `docker image inspect` — if you see arrays, not `sh -c`, you've built it right, and the two probe runs will prove it behaves like a binary.
