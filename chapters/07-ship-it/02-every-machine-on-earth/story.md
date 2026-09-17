# Every Machine on Earth

Here's a failure you can reproduce right now. Build any image on your Mac, ship it to a typical cloud server, run it, and read the greeting: `exec format error`. Nothing is corrupt. Your Apple Silicon laptop is an **arm64** machine, most cloud servers are **amd64** (x86_64), and a compiled binary only runs on the CPU family it was compiled for. An image built on your laptop contains arm64 binaries all the way down — alpine's `sh`, node, everything. The server's CPU literally cannot decode those instructions.

So does "build once, run anywhere" die here? No — but it needs two pieces of machinery you haven't used deliberately yet: manifest lists and emulated builds.

## One tag, many CPUs

Pull `alpine` on your Mac and on an Intel server and both work. Same name, different bytes — and *unlike* the `latest` sloppiness from last chapter, this is by design. The tag doesn't point at an image; it points at a **manifest list** (also called a multi-arch image): a small index document that says "for arm64, use this manifest; for amd64, that one." The daemon pulling it picks the entry matching its own platform, automatically. You can see the whole menu without pulling anything:

```
$ docker buildx imagetools inspect alpine
Name:      docker.io/library/alpine:latest
MediaType: application/vnd.oci.image.index.v1+json
Manifests:
  Platform:  linux/amd64
  Platform:  linux/arm64
  Platform:  linux/arm/v7
  ...
```

Every official image ships like this. Your images, so far, don't — they're single-platform, whatever your laptop happens to be. This chapter fixes that.

:::notebook Inside a manifest list
Last chapter you saw that a tag points at a manifest — a JSON list of layer digests. A **manifest list** is one level higher: a JSON array of manifest digests, each annotated with `os` and `architecture` (and sometimes `variant`, like `arm/v7`). All the referenced manifests and their layers live in the same repository; the list is just a router. Registries return it with its own `Docker-Content-Digest`, so a manifest list can be pinned by digest like anything else. When a daemon pulls, it sends its platform preferences and walks the list; `--platform` on `docker pull`/`run` overrides that choice — which the challenge below exploits.
:::

## `buildx`: building for CPUs you don't own

`docker buildx` is the modern build client (it's been running your builds under the hood since Part 3 — `docker build` is an alias for it). Its trick for foreign CPUs is **QEMU**: a user-space emulator the kernel invokes transparently whenever a binary for another architecture starts. During an amd64 build on your arm64 Mac, every `RUN` command executes inside the emulator — slower than native, but faithful.

One catch: the default builder stores images straight into your local daemon, and the daemon can only hold *one platform per tag*. A multi-platform build needs a builder that can assemble and push a manifest list itself — the **`docker-container` driver**, a BuildKit instance running in (what else) a container:

```
$ docker buildx create --name chai-25-builder --driver docker-container --driver-opt network=host
$ docker buildx build --builder chai-25-builder \
    --platform linux/amd64,linux/arm64 \
    -t 127.0.0.1:8125/chai-25-api:1.0 \
    --provenance=false \
    --output type=registry,registry.insecure=true .
```

That one command builds the Dockerfile **twice** — once per platform, in parallel — then writes both manifests plus the manifest list directly to the registry. Unpack the unusual flags, because each earns its place:

- `--driver-opt network=host` — the builder container shares the daemon host's network, so it can reach a registry published on `127.0.0.1`. Without it, "localhost" inside the builder is the builder itself, and the push fails with `connection refused`.
- `--output type=registry,registry.insecure=true` — push straight from the builder, and allow plain HTTP. Your *daemon* trusts `127.0.0.1` automatically, but the builder container is a separate BuildKit with its own rules — it must be told. (`--push` is shorthand for `type=registry`, but the shorthand has nowhere to hang the `insecure` option.)
- `--provenance=false` — buildx likes to attach build-attestation documents to the index; switching them off keeps the manifest list exactly two entries, one per CPU, while you're learning to read them.

And the scaffold Dockerfile makes the duplication visible: its `RUN uname -m > /arch.txt` executes once natively and once under QEMU, so the amd64 image *permanently contains* `x86_64` in a file — proof the build really happened on a foreign architecture.

## Reading the result

The registry now holds one tag serving two CPUs:

```
$ docker buildx imagetools inspect 127.0.0.1:8125/chai-25-api:1.0
MediaType: application/vnd.docker.distribution.manifest.list.v2+json
Manifests:
  Platform:  linux/amd64
  Platform:  linux/arm64
```

`imagetools inspect` talks to the registry directly from your machine — no pull, no builder needed. This is the exact check the verifier runs, and the exact check a release pipeline runs before declaring an image shippable.

:::notebook How QEMU sneaks into a RUN command
The mechanism is a Linux kernel feature called **binfmt_misc**: a registration table saying "when asked to execute a binary with *this* magic number, launch *this* interpreter instead." Docker Desktop pre-registers QEMU for foreign architectures, so when the amd64 build stage runs `/bin/sh`, the kernel spots an x86-64 ELF header on an arm64 machine and quietly starts `qemu-x86_64` with the binary as its argument. The process doesn't know it's emulated. It's also 5–10× slower than native — fine for a lab or nightly build; real release pipelines often pair one arm64 and one amd64 machine as remote builder nodes and skip emulation entirely.
:::

Worth knowing before you're in a real pipeline: this same builder pattern is how CI systems produce every official multi-arch image you've ever pulled — build all platforms, push one tag, and no consumer ever thinks about CPUs again. That's the finish line: your image behaving like `alpine` does.

Time to put your own manifest list on the wire.
