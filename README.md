# ☕ Chai aur Docker Lab

A practical Docker book by **Hitesh** — with a live lab built in. Every chapter teaches real Docker (concepts, examples, and "Under the Hood" internals), then ends in a hands-on exercise and an optional challenge, verified against your actual Docker state. All on your own machine.

## Requirements

- **Docker Desktop** (or Docker Engine) — running
- **Node.js** 18+

## Start the lab

```bash
npm install
npm start
```

Your browser opens `http://localhost:4321`. Tasks are listed on the left, the story in the middle, and a real terminal at the bottom — everything runs locally, nothing leaves your machine.

## How it works

- Each chapter = the reading + **Exercise** (main task) + **Challenge** (bonus). A Chapter/Exercise toggle at the top cuts straight to the work.
- Hit **Verify** — the lab inspects your real Docker state (containers, images, ports…), never the commands you typed. Any valid approach passes.
- Progress is saved in your browser (localStorage). Completed episodes fill the chai glasses on the tray.
- **Reset chapter** wipes only that episode's containers (everything prefixed `chai-`), never your own.

## For instructors

Visit [https://chaicode.com](https://chaicode.com) for instructor resources.