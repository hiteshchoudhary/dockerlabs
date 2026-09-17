# Challenge

Your Mac is arm64 — so run the **amd64** variant on it anyway.

Pull the foreign-CPU entry explicitly with `docker pull --platform linux/amd64 127.0.0.1:8125/chai-25-api:1.0`, then run it (`--rm`, name it **`chai-25-probe`**) and capture its output into **`workspace/ch25/arch.txt`**.

The image's default command prints `/arch.txt` — a file written *at build time* by `uname -m`. If everything worked, the file says `x86_64` even though it just ran on an arm64 machine: the build baked the foreign architecture in, and QEMU is now executing those x86-64 binaries live under your fingers.

**You pass when:** the local `127.0.0.1:8125/chai-25-api:1.0` image is the `amd64` variant, and `workspace/ch25/arch.txt` says `x86_64`.
