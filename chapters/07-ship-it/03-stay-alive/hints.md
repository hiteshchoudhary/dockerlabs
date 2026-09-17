All three settings are `docker run` flags, stacked before the image name: `--restart unless-stopped --memory 64m --cpus 0.5`. If you already ran chai-26-app without them, remove and recreate it (`docker rm -f chai-26-app`) — or know that `docker update` can change limits and restart policy on a live container.

---

Full harness: `docker run -d --name chai-26-app --restart unless-stopped --memory 64m --cpus 0.5 nginx:alpine`. Check with `docker inspect -f '{{.HostConfig.RestartPolicy.Name}} {{.HostConfig.Memory}} {{.HostConfig.NanoCpus}}' chai-26-app` — expect `unless-stopped 67108864 500000000` (bytes and billionths of a core).

---

Challenge: `docker run --name chai-26-oom --memory 32m --memory-swap 32m alpine sh -c 'head -c 100m /dev/zero | tail'` — it prints `Killed` after a moment. `--memory-swap 32m` (equal to `--memory`) denies swap so the kill is immediate. Post-mortem: `docker inspect -f '{{.State.OOMKilled}} {{.State.ExitCode}}' chai-26-oom` → `true 137`.
