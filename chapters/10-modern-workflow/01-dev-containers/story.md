# Dev Containers

Nine parts ago we killed "works on my machine" for *running* software. There's one place the disease still lives: the machine you *write* software on. New teammate joins, spends day one installing Node, the right Node, the linter, the formatter, the pre-commit hooks — and still ends up with a subtly different setup than everyone else. I've watched teams lose a full sprint to "my ESLint disagrees with your ESLint."

And in 2026 there's a second kind of teammate: **AI coding agents**. An agent that edits your repo needs a machine to run tests and tools on, exactly like a human does. If the agent's environment differs from yours, you get a brand-new genre of bug — *works on my agent*. The fix is the same insight as Chapter 1, pointed at development instead of deployment: stop describing the environment in a README. Ship it.

## One file: `devcontainer.json`

A **dev container** is a container you develop *inside*: your editor, terminal, and tools all execute in the container, while your source code stays on your machine and is bind-mounted in (Part 4 muscle memory). The whole thing is declared by one committed file:

```
project/
└── .devcontainer/
    └── devcontainer.json
```

This is an open specification — [containers.dev](https://containers.dev) — not a VS Code gimmick. VS Code reads it, JetBrains reads it, GitHub Codespaces reads it, and coding agents (GitHub Copilot's agent, Devin-style tools, Claude-based agents) increasingly read it to know what machine your repo expects. Here's a real one:

```json
{
  "name": "chai-api",
  "image": "node:22-alpine",
  "forwardPorts": [8041],
  "postCreateCommand": "npm install",
  "customizations": {
    "vscode": { "extensions": ["dbaeumer.vscode-eslint"] }
  }
}
```

Four fields do most of the work, and each answers one question:

- **`image`** (or **`build`**) — *what machine?* Either a ready-made image, or `"build": { "dockerfile": "Dockerfile" }` to build one — everything you learned in Part 3 applies. There's also a family of purpose-built base images under `mcr.microsoft.com/devcontainers/*` with niceties preinstalled.
- **`forwardPorts`** — *which ports does the app use?* The tooling forwards them to your host automatically, so `localhost:8041` just works while the app runs inside.
- **`postCreateCommand`** — *how do we set it up?* Runs **once** after the container is created — the classic use is `npm install`. This is day-one onboarding, automated.
- **`customizations`** — *how should tools behave inside?* Namespaced per tool. `customizations.vscode.extensions` means every human — and every agent driving VS Code — gets the same linters and formatters. No more ESLint civil wars.

One more field you'll meet in the Challenge: **`features`** — reusable, versioned install scripts (git, Docker-in-Docker, the AWS CLI…) that layer onto any base image. `"features": { "ghcr.io/devcontainers/features/git:1": {} }` beats maintaining that `apt-get` block yourself.

:::notebook What actually happens when a dev container starts
There is no magic runtime — it's the Docker you already know, orchestrated. When VS Code (or the reference `devcontainer` CLI, or an agent platform) opens a repo with this file, it: **(1)** pulls or builds the image; **(2)** `docker run`s it with your project **bind-mounted** (by convention at `/workspaces/<name>`), started with a do-nothing command like `sleep infinity` so it idles; **(3)** runs `postCreateCommand` via `docker exec`; **(4)** keeps using `docker exec` for every terminal, test run, and language server, forwarding `forwardPorts` back to your host. Four steps, all Part 1–4 vocabulary. In the exercise you'll perform steps 2 and 4 by hand — no special CLI required — to prove the file is just instructions for plain Docker.
:::

## Why this matters more now, not less

The classic pitch was onboarding: clone, reopen in container, working environment in minutes, identical for everyone, and deletable — trash the container, your laptop stays clean. Still true. But the sharper 2026 argument is **agents**. When you hand a repo to an AI agent, the agent has to execute code: install dependencies, run the test suite, start the dev server. Platforms that run coding agents boot your `devcontainer.json` to get that environment — same image, same ports, same setup command as every human on the team. One committed file becomes the single source of truth for *every* contributor, carbon or silicon. No devcontainer means every agent improvises its own environment, and you debug the improvisation.

It also quietly fixes the "my laptop is special" problem for humans: the intern on Windows, the senior on a Mac, the CI runner on Linux, and the agent in a datacenter all develop on the *same* Linux userland. Bugs reproduce everywhere or nowhere.

:::notebook devcontainer.json is JSON-with-comments
The spec allows `// comments` and trailing commas (the "JSONC" dialect), because humans maintain this file. Editors handle it fine, but `JSON.parse` alone will choke on a commented file — tooling that reads devcontainer files strips comments first. Keep yours plain JSON if you want maximum compatibility with naive parsers.
:::

## Proving it without the fancy tooling

Since a dev container is plain Docker underneath, you can stand one up with commands you've owned since Part 1: run the dev image detached with the project bind-mounted, keep it idling, then `docker exec` your tools inside it. That's exactly what the exercise does — you'll write the `devcontainer.json` for a small Node project, then act as the "dev container CLI" yourself: start the container, mount the source, and prove the toolchain (`node --version`) lives inside the box, not on your host.

Time to give the project — and any agent that ever touches it — a machine of its own.
