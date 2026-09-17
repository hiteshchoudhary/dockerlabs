# Challenge

Catch the daemon writing its diary.

Put **`chai-27-app`** through one full **stop → start** cycle, then pull the daemon's record of it out of `docker events` — query a time window that covers your cycle (`--since`/`--until` so the command exits instead of streaming forever), filter to this container, and save the output to **`workspace/ch27/events.txt`** (from the lab terminal: `./ch27/events.txt`; create the folder if needed).

Read the file before you verify: you'll find the whole choreography — `kill (signal=15)`, then (because our little shell loop ignores polite signals) a second `kill (signal=9)` after the 10-second grace period, then `stop`, `die (exitCode=137)`, `start`. The daemon recorded exactly how ungraceful your app's shutdown was — production dashboards are built on this distinction.

**You pass when:** `workspace/ch27/events.txt` contains at least one `container stop` **and** one `container start` event for a `chai-27-*` container.
