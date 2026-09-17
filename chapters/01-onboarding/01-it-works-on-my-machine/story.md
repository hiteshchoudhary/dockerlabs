# It Works on My Machine

"Huh. Works on my machine."

Every engineer has said it. Every engineer has heard it. In fifteen years of shipping software and teaching developers, I've watched this one sentence burn more hours than any bug — because it isn't a bug. It's the absence of a shared truth about *where code runs*.

Here's how it usually goes. You join a team and clone the repo. `npm install` fails — some native module wants a version of Python you don't have. You fix that; the app boots and immediately crashes because Redis isn't running. You install Redis. Now Postgres is the wrong major version. Three hours in, a teammate glances at your screen and says the sentence. Meanwhile, the same app that runs fine on their laptop crashed on the production server last night — Ubuntu ships a different OpenSSL than macOS. Same code, three machines, three different outcomes.

## Why software breaks between machines

An application was never just its code. What actually runs is a stack:

- your code,
- a language runtime (Node 20.11? 22.1? it matters),
- installed packages, each with their own native dependencies,
- system libraries (OpenSSL, libc, ImageMagick…),
- an operating system with its own defaults,
- environment variables and config files.

Traditional deployment ships the top of that stack and *hopes* the rest matches on the other side. It never quite does. Machines drift — a brew upgrade here, an apt-get there — in a hundred invisible ways. The industry's answer to this, and the subject of this book, is blunt: **stop shipping hope. Ship the whole stack.**

## Images and containers

Docker packs an application *together with its entire environment* into a single artifact, and runs it identically anywhere. Two definitions carry the whole book, so read them twice:

- An **image** is a frozen, complete environment: your app plus the exact runtime, packages, and system libraries it needs, snapshotted into one immutable, versioned artifact. If you think in git, an image is like a commit of an entire machine. If you think in code: a class.
- A **container** is a running instance of an image — the object to the image's class. Start one or start fifty: each is identical, whether it runs on your laptop, a teammate's Mac, or a server in Mumbai.

Build the image once, and "works on my machine" becomes "works on every machine" — because you're no longer hoping the machines match. You brought the machine with you.

:::notebook A container is not a virtual machine
A VM boots an entire second operating system on emulated hardware — gigabytes of disk, minutes to start. A container is just a **normal process** on your machine, isolated by two Linux kernel features:

- **Namespaces** give the process a private view of the system: its own process list, network stack, hostname, and filesystem. Inside, it genuinely believes it's alone on the machine.
- **cgroups** cap what it may consume: CPU, memory, I/O.

No second OS, no hypervisor. That's why a container starts in milliseconds and your laptop can run dozens of them, but would choke on three VMs. This distinction has real cost implications — misjudge it and you'll overprovision servers for years.
:::

## Check your install

Everything in this book runs on your machine, so first prove Docker is actually there and awake:

```
$ docker version
Client:
 Version:    28.x
 ...
Server: Docker Desktop
 Engine:
  Version:   28.x
  ...
```

The output has **two sections**, and both matter. `Client` is the CLI you just invoked. `Server` is the Docker **daemon** — the background service that does all the real work. `docker --version` (with the dashes) only proves the CLI binary exists; `docker version` makes the daemon answer too. If the `Server` section shows an error like *"Cannot connect to the Docker daemon"*, the daemon isn't running: start Docker Desktop and give the whale a moment to settle.

## Your first container

The ceremonial first command of every Docker developer:

```
$ docker run hello-world
Unable to find image 'hello-world:latest' locally
latest: Pulling from library/hello-world
...
Hello from Docker!
This message shows that your installation appears to be working correctly.
```

Read that output slowly — it narrates four things that just happened:

1. The client sent `run hello-world` to the daemon.
2. The daemon looked for the `hello-world` image locally, didn't find it, and **pulled** it from Docker Hub — the public registry; think npm, but for environments.
3. The daemon created a **container** from that image and started it.
4. The container printed its message and exited.

:::notebook What actually happens on `docker run`
Docker is several programs pretending to be one. The client talks to the **daemon** (`dockerd`); the daemon pulls images from a **registry**, then delegates to **containerd** (which manages container lifecycles), which calls **runc** — the low-level tool that actually creates the namespaced, cgrouped process. One command, four layers, and at the bottom: an ordinary Linux process. You'll meet each layer again in this book; for now, just know the chain exists — it explains almost every error message you'll ever see from Docker.
:::

## Name your containers

One habit to build from day one. Docker assigns random names (`vigorous_hopper`, `nostalgic_turing`) unless you choose one:

```
$ docker run --name web nginx
```

Named containers make every later command readable — `docker logs web` beats `docker logs 3f9a1c...`. **This book's convention:** every container you create in the lab gets a `chai-` prefix. It keeps your lab work instantly recognizable, and the lab's cleanup scripts only ever touch that prefix — so nothing here can interfere with your other Docker work.

One more thing before the exercise: a container that exits does **not** disappear. It sits in the `Exited` state, visible with `docker ps -a` (plain `docker ps` shows only running ones). That's why the exercise below is checkable at all — and it's where the next chapter picks up.

Now prove all of this works on *your* machine.
