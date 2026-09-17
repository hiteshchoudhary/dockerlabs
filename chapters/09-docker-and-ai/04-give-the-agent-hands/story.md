# Give the Agent Hands (MCP)

So far our AI can think (Chapter 35) and remember (Chapter 36). It still can't *do* anything — it can't fetch a webpage, query your database, or read a file. Every vendor used to solve this with proprietary "plugins," which meant every tool had to be integrated with every AI product separately: the classic M×N integration mess. The industry's fix arrived in late 2024 and took over with startling speed: the **Model Context Protocol**.

## What MCP is

**MCP** is an open protocol that standardizes how AI applications talk to external tools. Two roles:

- An **MCP server** wraps some capability — fetch a URL, query Postgres, drive a browser, call GitHub — and exposes it as typed, described **tools**.
- An **MCP client** (Claude Desktop and Claude Code, VS Code + Copilot, Cursor, your own agent…) connects to servers, discovers their tools, and lets the model invoke them mid-conversation.

Write a server once and every MCP client can use it; teach a client MCP once and it can use every server. M×N becomes M+N — the same trick USB pulled on hardware ports, which is why "USB-C for AI" became the standard analogy.

Under the covers it's nothing exotic: **JSON-RPC 2.0** messages. In the most common local setup they flow over the humblest transport imaginable — **stdin and stdout**. The client *launches the server as a subprocess*, writes requests to its stdin, reads replies from its stdout. No port, no HTTP, no daemon. Any process that can read and write lines can be an MCP server.

Read that again: *the client launches the server as a subprocess.* Now the Docker question asks itself.

## Why containers are the packaging

An MCP server is an arbitrary program — Python with its pip tree, Node with its npm tree — that you're expected to download and let your AI assistant execute *on your machine*. That's two old problems in one new outfit:

- **Distribution.** "Install uv, then Python 3.12, then…" — the works-on-my-machine chapter, all over again. A container image ships the server with its entire environment; `docker run` replaces the setup README.
- **Trust.** These servers run with your permissions, and prompt-injected agents plus malicious lookalike servers are not hypothetical. A container gives the server *your CPU but not your filesystem* — it sees only what you explicitly mount or pass.

Docker leaned in: the **Docker MCP Catalog** is a curated set of official server images on Docker Hub under the `mcp/` namespace — `mcp/fetch`, `mcp/time`, `mcp/postgres`, hundreds more — and Docker Desktop's **MCP Toolkit** manages catalog servers and their client wiring from a GUI. We'll do it the terminal way, because one raw handshake teaches more than any GUI.

And the transport fit is perfect: a stdio subprocess is exactly what `docker run -i` produces. The container *is* the subprocess; `-i` (Chapter 3) keeps stdin open so JSON-RPC can flow in. No `-t` — this is a machine conversation, not a terminal session, and a pseudo-TTY would garble the stream.

## Speaking the protocol by hand

Every MCP session opens the same way: the client sends an `initialize` request — protocol version, its capabilities, who it is. Pipe one into a catalog server and read the reply:

```
$ printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"chai-lab","version":"1.0.0"}}}' \
    | docker run -i --rm mcp/fetch
{"jsonrpc":"2.0","id":1,"result":{"protocolVersion":"2024-11-05","capabilities":{"prompts":{...},"tools":{...}},"serverInfo":{"name":"mcp-fetch","version":"1.23.0"}}}
```

Look at what came back: the server identifies itself (`serverInfo`) and declares its **capabilities** — it has `tools` to offer (for `mcp/fetch`: a `fetch` tool that retrieves a URL and returns it as model-friendly markdown). In a real session the client would answer with an `initialized` notification, call `tools/list` to get the tool schemas, and then the model could start invoking them. Every AI-tool integration you'll meet begins with these exact bytes — you've just performed, by hand, the handshake your editor performs every time it boots.

:::notebook One line in, one line out — the whole transport
MCP's stdio transport is newline-delimited JSON-RPC: each message is one JSON object on one line, requests carry an `id`, responses echo it back. That plainness is a superpower — debugging an MCP server is `docker run -i` and your own eyeballs; no proxy, no packet capture. Notice the server also stays honest about streams: protocol on **stdout**, logs on **stderr** (rerun the handshake without `2>/dev/null` if a server seems chatty — that noise is stderr, and real clients ignore it). For remote servers MCP defines an HTTP-based transport, but local tooling overwhelmingly runs the subprocess way — which is why "an MCP server" in 2026 so often means "a container image with `-i`".
:::

## Registering it with a real client

Clients discover servers from a config file — the de-facto shape (Claude Desktop popularized it; most clients read something equivalent) is a JSON map of server name → *how to launch the subprocess*:

```json
{
  "mcpServers": {
    "fetch": {
      "command": "docker",
      "args": ["run", "-i", "--rm", "mcp/fetch"]
    }
  }
}
```

That's the whole trick, and it's beautifully dumb: the client neither knows nor cares that the server is containerized — it just spawns `command` with `args` and speaks JSON-RPC to the pipes. `docker` is the command; the sandboxing rides along for free. This file (with a server for your notes DB, one for the web, one for the codebase) is how the TutorAI agent grows hands — and next chapter we make sure those hands can't reach anything they shouldn't.

Now shake hands with a server yourself.
