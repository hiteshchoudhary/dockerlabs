# Exercise

**15.1 — Full backup drill: seed, archive, restore, verify.**

1. Create a volume named exactly **`chai-15-data`**, and seed it using a `--rm` throwaway alpine container that mounts it at `/data` and writes:
   - `/data/menu.txt` containing exactly:
     ```
     masala chai, strong, no sugar
     ```
   - `/data/notes/brew.txt` containing exactly:
     ```
     first brew at 6am
     ```
2. Back the volume up with the tar pattern: a `--rm` alpine container mounting **`chai-15-data`** read-only at `/data` and the host directory `workspace/ch15/` at `/backup` (from the lab terminal in `workspace/`: `mkdir -p ch15`, then bind-mount `"$(pwd)/ch15"`), producing **`workspace/ch15/backup.tar.gz`**. Archive *relative* paths (`-C /data .`).
3. Restore into a **new** volume named exactly **`chai-15-restore`**: another throwaway container, tarball extracted with `-C /data`.
4. Run the drill's final step yourself: read the files back out of `chai-15-restore` with one more `--rm` probe. A backup you've never restored is a rumor.

**You pass when:**

- Volumes `chai-15-data` and `chai-15-restore` both exist.
- `workspace/ch15/backup.tar.gz` exists and is a valid gzipped tar containing `menu.txt` and `notes/brew.txt` (as relative paths).
- Inside `chai-15-restore`, `/data/menu.txt` reads exactly `masala chai, strong, no sugar` — same as the original.

The verifier mounts your volumes into its own throwaway probes and reads the state it finds — the commands that produced it are your business.
