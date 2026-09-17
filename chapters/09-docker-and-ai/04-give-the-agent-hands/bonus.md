# Challenge

You've spoken the protocol by hand; now write the config that lets a *real* client do it for you. Create **`workspace/ch38/mcp-config.json`** registering your containerized server, in the de-facto client-config shape from the chapter:

- a top-level `mcpServers` object,
- containing a server entry (name it what you like — `"fetch"` is natural),
- whose `command` is **`docker`** and whose `args` launch the server exactly the way you just did: `run`, `-i`, `--rm`, then the **`mcp/fetch`** image.

Drop that file into Claude Desktop or any MCP client and your AI gains a web-fetching hand — sandboxed in a container it can't see out of.

**You pass when:** `mcp-config.json` parses, and it registers a server launched via `docker` with `run`, `-i`, `--rm`, and an `mcp/` image in its `args`.
