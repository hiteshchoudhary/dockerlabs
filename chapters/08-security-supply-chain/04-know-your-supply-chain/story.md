# Know Your Supply Chain

Every image you've built this Part starts with a `FROM` line — which means every image you ship contains software you didn't write, chosen by people you've never met, updated on a schedule you don't control. That's a **supply chain**, and attacking it is one of the growth industries of the decade: compromise one popular base image or build system and you compromise everyone downstream. The audit's question for this chapter is blunt: *for the images you ship, can you say exactly what's inside and where it came from?*

## The lie in the tag

Here's the uncomfortable fact underneath it all, first met in Chapter 4: **tags are mutable**. `alpine:3.22` is not a version — it's a sticky note. The Alpine maintainers re-point it with every patch release; a registry compromise could re-point it at anything. Two builds of the same Dockerfile, a week apart, can contain different bits — and you'd never know, because the Dockerfile didn't change.

What *is* immutable is the **digest** — the sha256 of the image's manifest, which you also met in Chapter 4. Content-addressed: same digest, same bits, mathematically. Every pulled image records the digest it came from:

```
$ docker pull alpine
$ docker image inspect -f '{{index .RepoDigests 0}}' alpine
alpine@sha256:8a1f59ffb675680d47db6337b49d22281a139e9d709335b492be023728e11715
```

And `FROM` accepts it directly:

```dockerfile
FROM alpine@sha256:8a1f59ffb675680d47db6337b49d22281a139e9d709335b492be023728e11715
```

This is **digest pinning**. A pinned build is *reproducible in its inputs*: nobody — not the maintainers, not an attacker holding the registry — can change what your build starts from without changing your Dockerfile, where the diff is visible in code review. The cost is that updates become deliberate: you bump the digest on purpose (bots like Renovate and Dependabot automate exactly this), instead of receiving whatever the sticky note points at today. For anything you ship, that trade is a bargain. The common convention keeps both readability and rigor: `FROM alpine:3.22@sha256:8a1f...` — tag for humans, digest for the machine (only the digest is enforced).

## Knowing what's inside: SBOMs

Pinning freezes *which* base you build on; it doesn't tell you *what's in it*. That's the job of an **SBOM** — a Software Bill of Materials: a machine-readable inventory (SPDX is the usual format) of every package and version in an image. When the next OpenSSL CVE drops, the difference between "grep the SBOMs, done in a minute" and "rebuild and manually inspect everything we've ever shipped" is the difference between a calm Tuesday and a very bad week. Enterprise customers increasingly just demand SBOMs up front — our fictional auditor included.

Docker's CVE-scanning frontend for this is **Docker Scout**: `docker scout quickview <image>` gives a vulnerability summary, `docker scout cves` the detailed list, `docker scout recommendations` suggests base-image updates. Know it exists; note that it requires a Docker Hub login (`docker login`), so this lab — which stays account-free — teaches the underlying artifacts instead. They matter more anyway: scanners come and go, the artifacts are standard.

## Provenance: who built this, from what?

An SBOM answers *what's inside*. **Provenance** answers *how it came to be*: which Dockerfile, which source revision, which builder, when — in the SLSA format the wider supply-chain world standardized on. BuildKit generates both at build time as **attestations**, signed-metadata documents that travel *with* the image through any OCI registry:

```
$ docker buildx build --sbom=true --provenance=true -t <ref> --push .
```

A consumer can then pull not just bits, but *answers*: `docker buildx imagetools inspect <ref>` shows the attestations attached to the image, and `--format '{{ json .SBOM }}'` digs the actual documents out. That's the supply-chain endgame: every artifact carries its own inventory and birth certificate.

:::notebook Where attestations physically live
No sidecar database, no separate upload: attestations ride inside the image index itself. A modern pushed image is an **index** (a manifest list — the same structure that serves multi-arch in Chapter 25) whose entries are the platform images... plus one oddity: a manifest with platform `unknown/unknown`, annotated `vnd.docker.reference.type: attestation-manifest` and pointing (via `vnd.docker.reference.digest`) at the image manifest it vouches for. Its "layers" are the SBOM and provenance JSON documents, content-addressed like any other blob. That design means any plain OCI registry — including the `registry:2` container you're about to run — stores attestations with zero special support, and deleting the image deletes its evidence trail atomically. When you run `imagetools inspect` in the challenge, that `unknown/unknown` entry is what you're looking at.
:::

## The rest of the base-image conversation

Digest pinning and attestations are process; the third lever is *choice of base*. The smaller the base, the shorter its SBOM and the fewer CVEs it can possibly carry: `alpine` (~8 MB) over `debian` (~120 MB); for compiled apps, **distroless**-style bases (no shell, no package manager — nothing for an attacker to live off) or hardened-minimal vendors like Chainguard, whose images ship with SBOMs attached and near-zero known CVEs as a product promise. You already hold the skill that makes these usable: multi-stage builds from Chapter 11 — build on a fat image, ship on a minimal one. And the no-shell debugging problem this creates has an answer waiting in Chapter 43.

## This chapter's build

The exercise pins the ChaiCode base by digest — you'll fetch alpine's real digest from your own machine and build `chai-33-api:v1` on it; the verifier checks the pin is genuine, not decorative. The challenge closes the loop: your own registry from Chapter 24 (`registry:2`, this time on port 8133), a buildx builder that's allowed to talk plain HTTP to it (the `buildkitd.toml` in `workspace/ch33` handles that — the same insecure-registry dance as Chapter 25), and a push with full SBOM and provenance attached. Then you get to *inspect your own supply chain evidence* sitting in your own registry.

Time to stop trusting sticky notes.
