# Challenge

Use an `inspect` **format template** — not your eyes, not grep — to extract `chai-03-box`'s IP address, and write it to **`workspace/ch03/ip.txt`**.

The IP lives deep in inspect's JSON under `.NetworkSettings.Networks`, and because a container can belong to multiple networks, you'll need the `range` construct shown in the chapter.

**You pass when:** `workspace/ch03/ip.txt` contains exactly the container's current IP address (the verifier runs its own template and compares).
