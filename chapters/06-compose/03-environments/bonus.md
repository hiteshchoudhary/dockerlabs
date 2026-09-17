# Challenge

Flip the toolbelt on. Bring the stack up *with* the `debug` profile activated, so the sleeper joins the running project — then step into it (`docker compose exec debug sh`) and prove to yourself it can reach `web` by service name (`wget -qO- http://web:3000/`), because profile services join the same project network.

**You pass when:** the `debug` service's container is up and running under project `chai-21` — alongside the still-running `web`, which must keep answering on `8021`.
