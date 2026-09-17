# Challenge

A restore that secretly shares storage with its source would be worse than useless — prove yours doesn't.

Using a `--rm` helper, **overwrite `/data/notes/brew.txt` inside `chai-15-restore`** with different content (say, `second brew, extra ginger`). Then check the original: `chai-15-data`'s `notes/brew.txt` must still read `first brew at 6am`, untouched.

Leave `menu.txt` alone in both volumes — the main exercise should stay green while you do this.

**You pass when:** `notes/brew.txt` differs between the two volumes, and the original still says exactly `first brew at 6am` — the copy is independent.
