# Small Is Fast

Run `docker images` and look at what this part has produced so far: Node-based images in the 150 MB range — for apps of a few kilobytes. Nobody blinks at that until the day it costs money: every deploy pulls those megabytes to every server, every scale-up event waits on them, every registry bill grows with them. And there's a second bill, quieter: everything inside an image is **attack surface**. A package manager, a shell, curl — wonderful for you, equally wonderful for whoever compromises the container. Part 8 makes that case fully; today we get the sizes down an order of magnitude.

## The insight: build tools ≠ runtime needs

Why are images fat? Because *building* software needs far more than *running* it. Compilers, package managers, dev headers, git — all essential at build time, all dead weight afterwards. The naive Dockerfile installs the whole toolchain, produces a binary, and then **ships the toolchain along with it**.

The fix is built into Dockerfiles: **multi-stage builds**. Write several `FROM` blocks in one file; each starts a fresh **stage**; later stages can reach back and pluck files out of earlier ones with `COPY --from=`. Only the *final* stage becomes your image — everything else is scaffolding, used and discarded:

```dockerfile
# ---- stage 1: the workshop (has the whole Go toolchain) ----
FROM golang:alpine AS build
WORKDIR /src
COPY go.mod main.go ./
RUN CGO_ENABLED=0 go build -o /api .

# ---- stage 2: the product (has the binary and nothing else) ----
FROM alpine
COPY --from=build /api /api
CMD ["/api"]
```

`AS build` names the first stage; `COPY --from=build` is the crane that lifts one file across. The `golang:alpine` toolchain — a quarter gigabyte — appears in your final image not at all. This works in every compiled ecosystem, and the same pattern serves interpreted ones too: a Node build stage runs `npm ci` *including* devDependencies, compiles the TypeScript, and the final stage copies in only `dist/` plus production `node_modules`.

For this exercise the ChaiCode API has been rewritten in Go (`workspace/ch11/app/` — `main.go` and `go.mod`). You don't need Go installed, and that's the second lesson hiding in this chapter: *the build stage is the toolchain*. Teammates build this image with nothing but Docker — the "works on my machine" story, applied to compilers.

## Choosing the final base

The final `FROM` decides what surrounds your app:

- **`alpine`** (~5 MB compressed) — a real, minimal Linux: `apk` package manager, busybox shell. You can still `exec` in and look around. The workhorse choice, and today's target.
- **`debian:*-slim`** (~30 MB) — trimmed Debian. Bigger, but glibc-based: the safe harbor when native dependencies object to Alpine (see the notebook).
- **`gcr.io/distroless/*`** (~2–20 MB) — Google's "just enough OS": libc and certificates, **no shell, no package manager**. Nothing for an attacker to live off; nothing for you to `exec` into either.
- **`scratch`** (0 bytes) — literally empty. Only a static binary can live here: no libc, no `/etc/ssl`, no `/tmp`, no shell. The floor, and your challenge.

That `CGO_ENABLED=0` in the build stage is what makes the small bases possible: it forces a fully **static** binary — every library baked in, zero runtime demands on its surroundings. It'll run on any of the four bases unmodified.

:::notebook What's actually inside a base image — and musl vs glibc
Unwrap `alpine` and you find no kernel — containers share the host's — just a root filesystem: `/bin` (one busybox binary wearing 300 command names), `/etc`, `/lib` with its C library, and package-manager metadata. An image is a tarball of userland; "distro" inside a container means *that*, nothing more.

The C library is the detail that bites. Most of Linux uses **glibc**; Alpine ships **musl** — smaller, stricter, but binary-incompatible. Software compiled against glibc can crash on Alpine with the wonderfully unhelpful `not found` (the missing file is the glibc loader itself, `ld-linux-*.so`). Python wheels and Node native modules are the classic victims — many ship prebuilt glibc binaries, and on Alpine pip/npm silently falls back to compiling from source: slow builds, missing-header errors, DNS quirks under musl's resolver. Rule of thumb: static Go/Rust → Alpine or scratch, always. Native-heavy Python/Node → try Alpine, and retreat to `-slim` without guilt. Distroless splits the difference: glibc compatibility at near-Alpine size, no shell to debug with — pair it with `docker debug` (Part 10).
:::

## The budget

Talk is cheap; budgets are enforced. Your target: the Go API as **`chai-11-api:slim`**, measured by `docker image inspect -f '{{.Size}}'` at **under 20 MB** — versus the ~150 MB a naive single-stage Node build weighs. The verifier will put your image on the scale. For reference, a well-built alpine-final image for this app lands under 10 MB; if you're over budget, you almost certainly shipped a stage you meant to discard.

Two flourishes worth knowing. You can build *a specific stage* with `--target build` — handy for grabbing a debug-friendly image with the toolchain still in it. And linker flags shave real megabytes off Go binaries: `go build -ldflags="-s -w"` drops symbol tables and DWARF debug info — the challenge expects you to use them on the way down to `scratch`.

Off to the workshop — build big, ship small.
