# Bind Mounts & Live Code

Chapter 13 solved durability: volumes keep data alive across container generations. But volumes have a personality — Docker owns them, hides them inside its own storage (on your Mac, inside a VM you can't even browse), and that's exactly right for a database. It's exactly *wrong* for the problem every developer hits next: *I'm editing code on my machine and I want the container to see every save, right now.* Rebuilding an image per keystroke is not a workflow.

For that, Docker has a second kind of mount.

## Bind mounts: your directory, their filesystem

A **bind mount** grafts a host directory (or single file) that *you* choose onto a path inside the container. No copying — both sides see the same bytes, live, in both directions:

```
$ docker run -d --name web -p 8080:80 \
    -v /Users/you/project/site:/usr/share/nginx/html \
    nginx:alpine
```

How does Docker know this is a bind mount and not a volume? The first field: a **path** (starts with `/` or `./`) means bind mount; a bare **name** means volume. This is the most consequential punctuation in Docker — and the source of a classic bug: `-v site:/usr/share/nginx/html` quietly creates an empty *volume* named `site` and mounts that. Your files never appear, nginx serves 403, and nothing errors. Bind mounts want **absolute paths**; from a shell, `"$(pwd)/site"` is the standard incantation.

Save a file on the host and the container sees it the same instant — it's literally the same directory, visible through two namespaces. That's the entire dev-container workflow (Part 6 turns it into `compose watch`): image holds the runtime, bind mount holds your ever-changing code.

One more difference from volumes worth respecting: if the container path already had files (from the image), a bind mount **shadows** them — they're not merged, not deleted, just invisible while the mount sits on top. A *named volume* mounted on a non-empty image path behaves differently: on first use it's seeded with a copy of the image's files. Bind mounts never copy anything, either direction.

## `:ro` — trust, but mount read-only

Both mount kinds accept flags after the container path. The one you should reach for constantly:

```
-v "$(pwd)/site":/usr/share/nginx/html:ro
```

**`ro`** makes the mount read-only *from inside the container*. The host edits freely; the container can look but not touch. For anything the container only serves — static sites, config files, TLS certs — read-only should be your reflex: a compromised or misbehaving process can no longer scribble on your source tree. The verifier for this chapter refuses a writable mount on principle.

:::notebook Ownership, UIDs, and why Mac lies to you
Inside a bind mount, Linux doesn't see usernames — it sees numeric UIDs. On a **Linux host** this bites hard: a container process running as UID 0 writes `root`-owned files into your project (hello, un-deletable `node_modules`), and a container running as UID 1000 may be unable to read files your host user 501 owns. On **Docker Desktop for Mac/Windows** there's a file-sharing layer (VirtioFS on modern Macs) between your filesystem and the Linux VM, and it *transparently maps ownership* — everything just works, which means Mac developers ship UID bugs they never saw. The fixes when it bites: run the container with `--user "$(id -u):$(id -g)"`, or make the image's user match. Remember this the first time CI (Linux) fails on what "worked on my Mac" — that sentence again.
:::

## tmpfs: the third kind — fast and deliberately forgetful

Some data shouldn't survive *or* touch a disk: caches, session scratch, secrets you'd rather not leave in a writable layer. A **tmpfs mount** is a RAM-backed filesystem that exists only while the container runs:

```
$ docker run -d --tmpfs /cache nginx:alpine
```

Writes go to memory, never to the writable layer, and vanish completely at container stop. (Linux-native feature; Docker Desktop provides it via its VM. `--tmpfs` takes options like `--tmpfs /cache:size=64m` to cap it.)

## The decision table

| | **Volume** | **Bind mount** | **tmpfs** |
|---|---|---|---|
| Who owns the location | Docker | You | Kernel (RAM) |
| Survives container removal | ✅ | ✅ (it's your dir) | ❌ by design |
| Visible in Finder / editor | ❌ | ✅ | ❌ |
| Typical use | databases, app state | source code, config in | caches, scratch, secrets |
| Performance | best (native, no CoW) | good; file-sharing tax on Mac | fastest |
| First field in `-v` | a name | an absolute path | (no `-v`; `--tmpfs`) |

Rule of thumb: **data the app owns → volume. Files you own → bind mount. Files nobody should keep → tmpfs.**

:::notebook `-v` vs `--mount`
Everything `-v` does, `--mount` does with long-form key=value pairs: `--mount type=bind,src="$(pwd)/site",dst=/usr/share/nginx/html,ro`. Same engine feature, two spellings. `--mount` is more verbose, but it's explicit about `type=` (bind/volume/tmpfs) and *fails loudly* if a bind source doesn't exist — where `-v` "helpfully" creates a directory, hiding your typo. Scripts and compose files tend toward the explicit form; fingers tend toward `-v`. Both appear in the wild; read both fluently.
:::

Verification-wise, you already own the tool: `docker inspect -f '{{json .Mounts}}'` shows every mount with its `Type` (`volume`, `bind`, `tmpfs`), `Source`, `Destination`, and `RW` flag. That JSON is the ground truth for everything this chapter's verifier checks.

The scaffolding for the exercise is already in your workspace at `ch14/site/` — a small `index.html` waiting to be served. Mount it into nginx read-only, then edit it on the host and watch the container serve your change with zero Docker commands in between.
