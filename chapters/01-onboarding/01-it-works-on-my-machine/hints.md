The command is `docker version` (not `docker --version` — the short flag only proves the CLI binary exists; the full command makes the daemon answer too). If the `Server` section errors, start Docker Desktop and wait for the whale icon to settle.

---

Running a container: `docker run <image>`. Naming it: add `--name <something>` before the image name. Docker pulls `hello-world` from Docker Hub automatically the first time. If a name is already taken, remove the old container: `docker rm <name>`.

---

Full commands: `docker run --name chai-01-hello hello-world` — and for the challenge: `docker run --name chai-01-echo alpine echo "hello chaicode"`. Anything after the image name overrides the image's default command. Read it back with `docker logs chai-01-echo`.
