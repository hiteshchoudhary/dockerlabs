# Exercise

**3.1 — Break into a live container, plant a file, extract it.**

1. Run a **detached** container named exactly **`chai-03-box`** from the `alpine` image that stays alive (alpine's default command exits instantly — give it something long-running to do, like sleeping for an hour).
2. Using `exec`, create the file **`/app/status.txt`** inside the running container containing exactly:
   ```
   all systems go
   ```
   (You'll need to create the `/app` directory too.)
3. Extract your planted file to the host with `docker cp`, landing it at **`workspace/ch03/status.txt`** (the lab terminal opens in `workspace/`, so from there: `./ch03/status.txt` — create the folder if needed).

**You pass when:**

- `chai-03-box` is running and was created from `alpine`.
- Inside it, `/app/status.txt` contains `all systems go`.
- On the host, `workspace/ch03/status.txt` exists with the same content.
