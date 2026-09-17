# Tests Against Real Things

Here's a test suite I've seen at more companies than I can count: hundreds of green unit tests, database mocked, queue mocked, cache mocked. Deploy on Friday. Production falls over by dinner — because the *real* Postgres treats `NULL` differently than the mock did, or the real driver escapes a string the fake never saw. The tests weren't testing the app. They were testing the team's *beliefs* about Postgres. **Mocks don't verify behavior; they verify assumptions** — and assumptions are exactly the thing that breaks.

For years the excuse was cost: a real database in every test run meant a shared "test DB" server — slow to provision, polluted by yesterday's data, fought over by CI jobs. Then containers made real infrastructure cheap enough to *throw away*. A fresh Postgres now costs about two seconds and zero cleanup debt. That changed the economics of testing, and an entire pattern grew around it.

## The Testcontainers pattern

**Testcontainers** began as a Java library and is now a family (Java, Go, Node, Python, .NET, Rust…) under the Docker umbrella. The idea fits in one sentence: *your test code starts real dependencies as disposable containers, waits until they're actually ready, runs real assertions against them, and guarantees teardown.* In Node it reads like this:

```js
const { PostgreSqlContainer } = require("@testcontainers/postgresql");

const pg = await new PostgreSqlContainer("postgres:16-alpine").start();
const client = new Client({ connectionString: pg.getConnectionUri() });
// ...real INSERTs, real SELECTs, real constraint violations...
await pg.stop();
```

No mock. The test talks to a genuine Postgres 16 — the same image production runs — born for this test run and gone after it. Every language binding does the same four moves, and those moves are the actual lesson:

1. **Start throwaway.** The container is unnamed-or-unique, on a **random free host port** so twenty CI jobs can run in parallel without colliding.
2. **Wait for *ready*, not *running*.** `docker ps` saying `Up` means the process started — not that the database accepts connections. Real wait strategies poll a health command, a log line, or a port.
3. **Test against reality.** A round-trip — write it, read it back — through the real wire protocol, real types, real error messages.
4. **Tear down, always.** Even when tests fail. Leaked containers are the pattern's cardinal sin.

:::notebook Ryuk, the container reaper
How does the library guarantee teardown even when the test process is `kill -9`'d mid-run? It can't — dead processes run no cleanup code. So Testcontainers starts one extra container: **Ryuk**, the reaper. Every resource the library creates is labeled with the test session's id; Ryuk holds an open TCP connection to your test process and watches for labeled resources. When your process dies, the connection drops, and Ryuk deletes everything with that session's labels, then removes itself. It's a beautiful trick you already have the vocabulary for: labels (Part 2) plus a supervising container. Our lab's `chai-NN-` prefix discipline is the same idea done by convention instead of by reaper.
:::

## The pattern with bare hands

Libraries are the right tool in a real codebase. But you're in a Docker book, so today you build the pattern from primitives — one shell script that *is* an integration test. Every move maps to a command you own:

**Start throwaway** — `--rm` makes deletion automatic the moment the container stops:

```
$ docker run -d --rm --name chai-42-db -e POSTGRES_PASSWORD=secret \
    -p 8042:5432 postgres:16-alpine
```

**Wait for ready** — the postgres image ships `pg_isready`, purpose-built for this:

```
$ docker exec chai-42-db pg_isready -h 127.0.0.1 -U postgres
127.0.0.1:5432 - accepting connections
```

Loop until that exits `0` (give up after ~30 tries — a wait strategy that can hang forever is a bug). One sharp edge worth knowing: ask via `-h 127.0.0.1`, not the default Unix socket. During first boot the image runs a *temporary* initialization server that answers on the socket, then restarts; TCP only answers once the real server is up.

**Test reality** — the image also ships `psql`, so the round-trip needs no client on your host:

```
$ docker exec chai-42-db psql -h 127.0.0.1 -U postgres -tAq \
    -c "CREATE TABLE notes(body text); INSERT INTO notes VALUES ('chai aur docker'); SELECT body FROM notes;"
chai aur docker
```

That's a real table in a real database — parsed by the real SQL engine. If your SQL is wrong, *Postgres* tells you, not a mock's imagination. (The flag stack matters when you capture output in a script: `-t` no headers, `-A` no alignment, `-q` no command tags — without `-q` you'd also capture `CREATE TABLE` and `INSERT 0 1`.)

**Tear down** — `docker rm -f chai-42-db`, and thanks to `--rm` nothing remains. Not a container, not a graveyard entry in `docker ps -a`. The proof of a good integration script is what it *leaves behind*: nothing but a results file.

:::notebook Fixed port here, random ports in real life
This script publishes on 8042 because lab chapters own fixed ports. Real Testcontainers never does this — it passes `-p 5432` with no host part, letting the kernel pick any free ephemeral port, then asks Docker which one it got (`docker port <name> 5432`). That single trick is what lets a hundred parallel CI jobs each run their own Postgres on one machine. Bonus subtlety: because our test runs `psql` *inside* the container via `exec`, the published port isn't even load-bearing — it's there so you can point a host tool like TablePlus at a throwaway DB, a genuinely useful habit.
:::

## Why this beats mocks-that-lie

An integration test like this catches the failures mocks structurally cannot: schema drift, type coercion surprises, transaction isolation, collation, the driver's actual error text. And because the database is *born fresh* each run, you also get what the shared test-DB era never had — perfect reproducibility. No "it fails on CI because someone left rows in the table." The container is the test fixture, and the fixture is disposable.

Your exercise: write that script — start, wait, round-trip, tear down — and leave behind a `result.txt` that proves the whole journey happened.
