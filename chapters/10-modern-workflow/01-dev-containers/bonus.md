# Challenge

Base image plus hand-rolled install scripts is the old way. The spec's answer is **features**: versioned, reusable install units that layer onto any dev container image.

Extend your **`workspace/ch41/project/.devcontainer/devcontainer.json`** with a `"features"` object that adds at least one feature — the classic first pick is git:

```
ghcr.io/devcontainers/features/git:1
```

(Any feature works; the value for each key is an options object, `{}` when you're happy with defaults.)

**You pass when:** `devcontainer.json` still parses with all exercise fields intact, and contains a `features` object with at least one feature entry.
