# Environments

Chapter 10 gave you the twelve-factor rule: one image, config from the environment. Compose is where that rule either becomes effortless or becomes a mess of copied YAML files named `compose-dev-final-2.yaml`. This chapter is the effortless version: four mechanisms — variables, `env_file`, profiles, and override files — that let a single `compose.yaml` serve your laptop, CI, and production without ever forking it.

## Variables: parameterize the file itself

Compose substitutes `${VAR}` references *before* it does anything else:

```yaml
services:
  web:
    environment:
      CHAI_MODE: ${CHAI_MODE:-prod}
```

Values come from your shell environment, or — far more usefully — from a file named **`.env`** sitting next to the compose file:

```
# .env — picked up automatically, never passed to containers by itself
CHAI_MODE=dev
```

`${CHAI_MODE:-prod}` means "use `CHAI_MODE`, default to `prod` if unset" — you saw the syntax in Chapter 19's challenge; there's also `${VAR:?error message}` to make a missing variable fail loudly instead of defaulting silently. Note carefully what `.env` is for: it feeds the *substitution step*, i.e. the YAML text. It does not magically enter your containers. That distinction bites everyone once; make it bite you now, cheaply.

## `env_file`: feed the container, in bulk

To put variables *inside* a container you already know `environment:` (that's `-e`). When there are twenty of them, point at a file instead:

```yaml
services:
  web:
    env_file:
      - web.env
```

```
# web.env — goes straight into the container's environment
CHAI_MESSAGE=chai is ready
```

Same file format, completely different destination. **`.env` configures the compose file; `env_file` configures the container.** Say it twice.

:::notebook Who wins? The precedence ladder
When the same variable is set in several places, Compose resolves container environment in this order, strongest first: values from `docker compose run -e` overrides → `environment:` in the YAML → `env_file:` entries (in listed order) → variables baked into the image with `ENV` (Chapter 10). Separately, for *substitution* (`${...}` in the YAML), your shell environment beats `.env` — which is exactly why `WEB_PORT=8119 docker compose up` worked in Chapter 19 despite no `.env` at all. When you're unsure what won, don't guess: `docker compose config` prints the fully resolved file with every substitution done and every env_file merged — it's the single best debugging command in all of Compose.
:::

## Profiles: services that only sometimes exist

Every stack accumulates tooling that shouldn't always run — a database GUI, a mail-catcher, a load generator. Don't comment them in and out of the YAML like an animal; give them a **profile**:

```yaml
services:
  debug:
    image: alpine
    command: sleep infinity
    profiles: ["debug"]
```

A service with `profiles` is invisible to normal commands. `docker compose up -d` skips it; `docker compose ps` doesn't list it; it doesn't even appear in `docker compose config`. It only exists when you ask:

```
$ docker compose --profile debug up -d     # tooling joins the stack
$ docker compose --profile debug down      # and leaves with it
```

Services *without* profiles always run — profiles opt services out of the default set, they never remove the core stack. One compose file, and `up` means "the app" while `--profile debug up` means "the app plus my toolbelt".

## Override files: the local layer

The fourth mechanism is file merging. If a **`compose.override.yaml`** exists next to `compose.yaml`, Compose reads both and merges the override on top — automatically, no flags. The convention: `compose.yaml` is the committed truth; the override is your personal, usually gitignored, local layer:

```yaml
# compose.override.yaml — my machine only
services:
  web:
    ports:
      - "9999:3000"   # I have something else on the usual port
```

Mappings merge key-by-key; scalar values replace; lists mostly append (ports being the classic surprise — you can end up publishing *both* ports). For deliberate stacking beyond the default pair, `-f` chains files explicitly: `docker compose -f compose.yaml -f compose.prod.yaml config` — later files win. And again, `docker compose config` shows you the merged result before you bet a deploy on it.

:::notebook Four mechanisms, one decision rule
They overlap, so here's the rule I give teams. Value differs per *developer or per run* → variable with a sane default (`${PORT:-8021}`). Many values that belong to one *service* and might be secret-ish → `env_file` (and gitignore the real one, commit a `web.env.example`). Whole *services* that are optional → profiles. Structural differences per *environment* — different mounts, ports, build targets — → override/`-f` files. If you find yourself templating YAML with `sed`, you've missed one of the four. And credentials? Env vars still leak into `docker inspect` and logs; real secret handling is Part 8's opening argument.
:::

The exercise wires up three of the four on a tiny build-based service (the scaffolded app just echoes its own environment back as JSON — the point is the wiring, not the app), and the challenge flips the profile on. You'll use the override file the first time your laptop disagrees with the repo — which is to say, soon.

Go configure one stack three ways.
