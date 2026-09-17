# Exercise

**27.1 — Run a chatty container with its logs capped.**

1. Run a detached container named exactly **`chai-27-app`** from `alpine` that never shuts up — a shell loop that echoes a line every second will do:
   ```
   sh -c 'i=0; while true; do echo "tick $i"; i=$((i+1)); sleep 1; done'
   ```
2. Give it rotation before it ever needs it — explicitly use the **`json-file`** log driver with options **`max-size=1m`** and **`max-file=3`**.
3. Prove the stream flows: `docker logs --tail 5 chai-27-app` should show recent ticks.
4. Confirm the cap is in the container's config: `docker inspect -f '{{json .HostConfig.LogConfig}}' chai-27-app`.

**You pass when:**

- `chai-27-app` is running.
- Its log driver is `json-file` with `max-size=1m` and `max-file=3` configured.
- `docker logs chai-27-app` actually returns output.

The verifier reads the container's live configuration and its log stream — not your terminal history.
