# Challenge

The floor below Alpine is **`scratch`** — a completely empty filesystem. No shell, no `ls`, no package manager: just your static binary and the kernel it shares with the host. It's the smallest and quietest an image can get.

Add (or adapt) a final stage `FROM scratch`, strip the binary down with linker flags (`go build -ldflags="-s -w" ...`), and build **`chai-11-api:scratch`**. Then prove emptiness still serves: run a detached container named **`chai-11-mini`** from it, publishing host port **`8111`** to container port `3000`.

Try `docker exec -it chai-11-mini sh` for the full experience — there is no shell to give you. That's the trade: nothing for an attacker, nothing for you either.

**You pass when:** **`chai-11-api:scratch`** exists **under 10 MB** (same scale: `docker image inspect -f '{{.Size}}'`), and **`chai-11-mini`** is running from it with `http://localhost:8111` answering.
