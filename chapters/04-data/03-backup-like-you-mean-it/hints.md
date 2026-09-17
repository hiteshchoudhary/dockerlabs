Seeding without a long-lived container: `docker volume create chai-15-data`, then `docker run --rm -v chai-15-data:/data alpine sh -c 'echo "masala chai, strong, no sugar" > /data/menu.txt && mkdir -p /data/notes && echo "first brew at 6am" > /data/notes/brew.txt'`. The `sh -c` wrapper keeps the redirects inside the container (Chapter 3's lesson).

---

The backup bridge needs both mounts: `mkdir -p ch15 && docker run --rm -v chai-15-data:/data:ro -v "$(pwd)/ch15":/backup alpine tar czf /backup/backup.tar.gz -C /data .` — run from `workspace/`, absolute path on the bind side. The trailing `.` with `-C /data` archives relative paths; sanity-check with `tar tzf ch15/backup.tar.gz`.

---

Restore and verify: `docker volume create chai-15-restore && docker run --rm -v chai-15-restore:/data -v "$(pwd)/ch15":/backup alpine tar xzf /backup/backup.tar.gz -C /data`, then read it back: `docker run --rm -v chai-15-restore:/data:ro alpine cat /data/menu.txt`. Challenge: `docker run --rm -v chai-15-restore:/data alpine sh -c 'echo "second brew, extra ginger" > /data/notes/brew.txt'` — then cat both volumes' `brew.txt` and compare.
