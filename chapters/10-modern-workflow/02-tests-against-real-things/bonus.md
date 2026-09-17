# Challenge

Real integration tests rarely need just one dependency. Extend **`workspace/ch42/integration.sh`** with a second throwaway: a Redis from `redis:alpine` named exactly **`chai-42-cache`** (also `--rm`).

Same four moves: start it, wait until `redis-cli ping` answers `PONG`, do a real round-trip (`SET` the value `chai aur docker`, `GET` it back), tear it down. Append two more lines to `workspace/ch42/result.txt` (again, the value must come from the `GET`):

```
PASS redis
roundtrip-redis=chai aur docker
```

Then re-run the script.

**You pass when:** `result.txt` carries all four marker lines (postgres + redis), and neither **`chai-42-db`** nor **`chai-42-cache`** exists afterward in any state.
