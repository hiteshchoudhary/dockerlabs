# Exercise

**41.1 — Declare the dev environment, then stand it up with plain Docker.**

The scaffold at `workspace/ch41/project/` is a tiny Node app (no dependencies). Give it a dev container definition, then prove the definition is just Docker by performing the tooling's job yourself.

1. **Write the definition.** Create **`workspace/ch41/project/.devcontainer/devcontainer.json`** with all four core fields:
   - `"image"` (a Node-capable image such as `node:22-alpine`) **or** a `"build"` object,
   - `"forwardPorts"` including this chapter's port, **8041**,
   - `"postCreateCommand"` (the project's setup step — `npm install` fits),
   - `"customizations"` (e.g. a `vscode.extensions` list, so humans and agents get the same tools).
2. **Be the dev container CLI.** Start a detached container named exactly **`chai-41-dev`** from your dev image with the project folder **bind-mounted** into it (convention: `/workspaces/project`), kept idling with a do-nothing command (`sleep infinity`).
3. **Prove the toolchain is inside.** `docker exec` a `node --version` in `chai-41-dev` and confirm it answers — the environment now belongs to the container, not to your laptop.

**You pass when:**

- `.devcontainer/devcontainer.json` exists in the project and parses, with `image` (or `build`), `forwardPorts` containing `8041`, `postCreateCommand`, and `customizations` all present.
- A container named `chai-41-dev` is running with a bind mount whose source is `workspace/ch41/project`.
- `node --version` executed inside `chai-41-dev` succeeds.

The verifier reads the file and inspects the running container's state — it never looks at how you got there.
