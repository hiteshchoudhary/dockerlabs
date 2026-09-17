# The Sandbox

Here is the defining problem of the AI age, and the reason this chapter is the flagship of the whole Part. Your AI writes code — to answer a question, run a student's homework, test a fix — and *something has to execute it*. That code is **untrusted by construction**: a language model generates plausible text, not safe text, and a student (or a prompt injection) can make it generate anything. Run it directly on your machine and you've handed an unpredictable author a shell with your permissions. This isn't paranoia; it's the single most common way AI systems get owned in 2026.

You already own the tool that solves it. From Part 1: a container is a normal process, fenced off by namespaces and cgroups. From Part 8: you can shrink that fence until almost nothing gets through. Put those together and you get the **sandbox** — the pattern every serious code-executing AI system (OpenAI's, Anthropic's, every "code interpreter") runs on. Today you build one and then *attack it* to prove it holds.

## The threat, made concrete

Look at `workspace/ch39/untrusted.py`. Pretend your tutor just generated it. It has one honest job — compute `6 * 7`, write the answer to `/tmp`, print it — and three pieces of sabotage stitched in:

- **Network:** open a socket to the internet (exfiltrate the answer, phone home).
- **Filesystem:** write `/etc/pwned.txt` (tamper with the system outside its scratch space).
- **Fork bomb:** spawn 200 processes (exhaust the host, deny service to everything else).

Crucially, each attempt *narrates its own outcome* — `BLOCKED` or `ESCAPED`. Run it naked and it's a horror show:

```
$ docker run --rm -v $PWD/untrusted.py:/code/untrusted.py:ro python:3.12-alpine \
    python3 /code/untrusted.py
uid=0 (running as ROOT — bad)
RESULT: 42
[network]    ESCAPED (opened a connection to 1.1.1.1:443 — data could have been exfiltrated)
[filesystem] ESCAPED (wrote /etc/pwned.txt — the rootfs is writable)
[fork-bomb]  ESCAPED (spawned 200 processes unchallenged)
```

A default container is *not* a sandbox. It runs as root, has full network, a writable filesystem, every Linux capability, and no resource ceiling. The mischief walked straight out. Our job is to turn every one of those `ESCAPED` lines into `BLOCKED` — while the legitimate `RESULT: 42` still comes through.

## Building the jail

Six flags, each closing one door. This is Part 8's hardening applied with intent:

```
$ docker run --name chai-39-sandbox \
    --network none \                 # no network stack at all
    --read-only \                    # root filesystem is immutable
    --tmpfs /tmp \                   # ...except a throwaway scratch space
    --cap-drop ALL \                 # surrender every Linux capability
    --pids-limit 64 \                # cap the process count — fork bombs hit a wall
    --memory 128m \                  # cap RAM — the OOM killer backstops runaway allocation
    --user 65534:65534 \             # run as 'nobody', never root
    -v $PWD/untrusted.py:/code/untrusted.py:ro \   # code mounted read-only
    python:3.12-alpine python3 /code/untrusted.py
```

Read each flag as a threat neutralized:

- **`--network none`** gives the container its own empty network namespace — a loopback and nothing else. The socket has nowhere to go.
- **`--read-only`** makes the entire root filesystem immutable, so `/etc/pwned.txt` bounces. But legitimate code often needs *somewhere* to write — hence **`--tmpfs /tmp`**, a small in-memory scratch that lives and dies with the container. Writable where it's safe, frozen everywhere else.
- **`--cap-drop ALL`** removes every Linux capability (Part 8's notebook: capabilities are the shards root's power splits into). The code can't raise privileges, bind low ports, or touch device nodes.
- **`--pids-limit 64`** caps how many processes the cgroup may hold. The fork bomb climbs to the ceiling and gets `Resource temporarily unavailable` — contained, not crashed.
- **`--memory 128m`** caps RAM; a memory bomb meets the OOM killer instead of your swap.
- **`--user 65534:65534`** runs as `nobody`. Even if something leaks through, it leaks as the most powerless user on the box.

Run *that*, and the same script sings a different tune:

```
uid=65534 (running as non-root)
RESULT: 42
[tmp] wrote /tmp/result.txt
[network]    BLOCKED ([Errno 101] Network unreachable)
[filesystem] BLOCKED ([Errno 30] Read-only file system: '/etc/pwned.txt')
[fork-bomb]  BLOCKED after 63 forks ([Errno 11] Resource temporarily unavailable)
```

The legitimate work completed; every attack failed *and said so*. That's a sandbox: not a wall around the code, but a room with no doors that still has a desk to work at.

:::notebook Why containers became THE agent sandbox — and where they stop
Containers won the AI-sandbox role for boring, decisive reasons: they start in milliseconds (an agent may spin up thousands), they're cheap enough to make **one-shot** — a fresh jail per execution, destroyed after, so nothing persists between runs — and the isolation knobs above are one `docker run` away. For running your own AI's generated code, this is the right tool and the industry default.

But be honest about the boundary. A container shares **one kernel** with the host. Every syscall the untrusted code makes is served by *your* kernel, so a kernel-level exploit — a bug in a syscall handler — can in principle escape the namespace. Against genuinely adversarial, unknown code (a public "run anything" service), defenders add a second layer that doesn't share the kernel: **gVisor** (Google) puts a user-space kernel in front of the real one to intercept syscalls; **Kata Containers** and **Firecracker microVMs** (the engine behind AWS Lambda) give each workload a real, lightweight VM with hardware-enforced isolation — container ergonomics, VM boundary. The mental model: containers isolate *processes*; VMs isolate *kernels*. Know which threat you're facing, and layer accordingly. For this course — running code we generated ourselves — the container jail is exactly right.
:::

One thing the jail above still lacks: a clock. A container that merely *sits* — an infinite loop, a hang — passes every check here and wastes a core forever. Runaway *time* is the challenge.

Now build the jail and let the verifier try to break out of it.
