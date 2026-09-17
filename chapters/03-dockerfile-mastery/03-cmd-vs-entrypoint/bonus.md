# Challenge

The one thing arguments can't change is the `ENTRYPOINT` itself — for that there's the `--entrypoint` flag, and it's a debugging move you'll use on real images that crash before you can look inside them.

Use it on your own tool: run a container named **`chai-09-peek`** from **`chai-09-tool:v1`**, overriding the entrypoint to **`cat`** so that instead of *executing* `/usr/local/bin/greet`, the container *prints its source code* and exits. (Note where the override goes: `--entrypoint` takes just the executable, before the image name — its arguments go after the image name, in CMD's slot. That split trips everyone once.)

**You pass when:** `chai-09-peek` exists, was created from `chai-09-tool:v1`, exited cleanly (code `0`), and its logs contain the script's source (the `chai says:` line) rather than a greeting.
