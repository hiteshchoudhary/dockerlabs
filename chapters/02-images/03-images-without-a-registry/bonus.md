# Challenge

Now measure what the *other* escape hatch throws away.

Run a container named **`chai-06-box`** from `chai-06-api:v1` (it doesn't need to stay running). `docker export` that container's filesystem and `docker import` the result as **`chai-06-flat:v1`**. Then put the two images side by side:

```
docker history chai-06-api:v1
docker history chai-06-flat:v1
```

A twenty-row construction story versus one mute row; a stack of layers versus a single flattened blob. Same files, no past.

**You pass when:** `chai-06-flat:v1` exists, its filesystem is a single layer with essentially no history (at most a lone "imported" entry), while the original `chai-06-api:v1` still carries its full multi-layer history for contrast.
