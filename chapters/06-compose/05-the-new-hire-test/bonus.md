# Challenge

The new hire will eventually want to *look inside* the database. Add **`adminer`** (a one-container database GUI, image `adminer`) to the stack — but debug tooling doesn't belong in the default boot, so put it behind the profile **`debug`**, exactly like Chapter 21's sleeper. Give it no published ports (the lab owns only 8023/8123 on this chapter — in real life you'd map one, or use a `compose.override.yaml` to add the mapping locally). It still reaches `db` by service name over the project network.

Bring the stack up with the profile active.

**You pass when:** the `adminer` service sits behind the `debug` profile in your config, its container is up and running under project `chai-23` — and the core four are still running and healthy around it.
