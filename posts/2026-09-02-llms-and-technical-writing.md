---
title: LLMs are bad at Technical Writing 
og-description: Why does LLM technical writing make me want to tear my eyes out? 
tags: llms, ai
---

## Framing

We've all been there, someone lets an LLM write a commit message, a pull request, or a technical document; you stare at it, what does this all mean? why is there so much text? why did it start using fancy words?

## So what are common issues I have with LLM written content?

* They love dropping in random jargon, "seam", "circuit-breaker", etc.
* They can't keep a consistent style
* They write huge blocks of text with no respect for the scannability of the document as a whole
* Their signal:noise ratio is awful, I can read multiple paragraphs without a single useful point being made

## How did we do this in the before times?

A couple jobs back, I remember working at another startup where we had a team called the Technical Writing team, they were people with things called "Humanities Degrees" in a subject called "English", they were in charge of making sure our documentation was easy to understand.

They were one of the first teams to go as soon as the business started having to tighten its belt.

They made our product better in a way that was hard to quantify, they had something that AI guys on twitter love to talk about, *taste*, they'd come over to my desk and say "I don't like how you wrote this sentence, you introduced a fancy word our customers don't know, either define it or find a simpler way to say it".

Sure it was annoying, but it made our product _better_.

## What are some useful rules?

* Don't use a complex word when a simple word will do
  * Don't: "Entering the wrong database credentials will elicit an error from the form" 
  * Do: "Entering the wrong database username and password will result in an error being shown"
* If you need a complex word, define it properly once
  * eg. "In this documentation Cohort means a group of users who are advertised to"
* A sentence is better than a paragraph if they deliver the same content
* Be direct and concise, use the active voice over the passive voice
  * Don't: "It's often the case that users who're attempting a migration will wish to keep a copy of the old configuration as according to their organization's business continuity manual."
  * Do: "Make sure you save a copy of your configuration before migrating."
* Focus on the reader
  * Why would someone come to this document? What do they want?
  * Is the reader highly technical or an average end user?
  * Will they want code samples? Do they need screenshots?
* Make the text easy to scan
  * Use numbered lists, bullet points, headers, pictures
  * Avoid having many paragraphs in a row
* Stick to onsistent terminology
  * Decide once if your documentation is british or american english
  * If you always capitalise SQL, it should always be capitalised, no exceptions

## Give me some side by sides

Here are some examples of asking an LLM to generate documentation for my [scala-mcp](https://github.com/andimiller/scala-mcp) project, with and without the rules.

Note: these were all run by Fable 5 to demonstrate, in theory that's the latest and greatest model from Anthropic


### End User Documentation

Document how to add a custom MCP connector to Claude Desktop

:::: {style="display: flex; gap: 20px;"}
::: {.column width="50%"}

# Adding a custom MCP connector to Claude Desktop

Claude Desktop can talk to servers built with this library in two ways:

1. **Local stdio server** — Claude Desktop launches your server as a subprocess
   and speaks MCP over stdin/stdout. Configured in `claude_desktop_config.json`.
   Use the `mcp-stdio` module for this.
2. **Remote HTTP connector** — Claude Desktop connects to a running Streamable
   HTTP server over the network. Added through **Settings → Connectors → Add
   custom connector**. Use the `mcp-http4s` module for this.

Stdio is the simplest path for a personal or single-machine tool; HTTP is the
right choice when the server holds shared state, needs authentication, or is
used by more than one client.

## 1. Local stdio server

### Write the server

```scala
//> using dep net.andimiller.mcp::mcp-core::0.13.0
//> using dep net.andimiller.mcp::mcp-stdio::0.13.0

import cats.effect.{IO, IOApp}
import io.circe.{Decoder, Encoder}
import net.andimiller.mcp.core.logging.NoOpLogging.given
import net.andimiller.mcp.core.schema.JsonSchema
import net.andimiller.mcp.core.server.*
import net.andimiller.mcp.stdio.StdioTransport

case class GreetRequest(name: String) derives JsonSchema, Decoder
case class GreetResponse(message: String) derives JsonSchema, Encoder.AsObject

object GreetServer extends IOApp.Simple:
  val greet =
    tool.name("greet")
      .description("Greet someone by name")
      .in[GreetRequest]
      .out[GreetResponse]
      .run(req => IO.pure(GreetResponse(s"Hello, ${req.name}!")))

  def run: IO[Unit] =
    ServerBuilder[IO]("greet-server", "1.0.0")
      .withTool(greet)
      .build
      .flatMap(StdioTransport.run[IO])
```

> **stdout is the protocol channel.** A stdio server must never print anything
> except MCP frames to stdout — a stray `println` will corrupt the stream and
> Claude Desktop will drop the connection. Send diagnostics to stderr, or wire
> in a log4cats-backed `Logging` instead of `NoOpLogging`.

### Package it

Claude Desktop launches the configured command on every app start, so you want
something that starts fast and doesn't depend on a warm build cache:

- **Assembly jar** (JVM) — add [sbt-assembly](https://github.com/sbt/sbt-assembly)
  and set `assembly / assemblyPrependShellScript :=
  Some(sbtassembly.AssemblyPlugin.defaultShellScript)` to get a self-executing
  jar you can invoke directly. Run `sbt assembly` to produce it.
- **Scala Native binary** — `sbt myServerNative/nativeLink` produces a
  standalone binary with instant startup and no JVM requirement (the core and
  stdio modules cross-build to Native).
- **`sbt run`** — fine while developing, but slow to start and noisy; prefer a
  packaged binary for day-to-day use.

### Configure Claude Desktop

Open **Claude Desktop → Settings → Developer → Edit Config**, which opens
`claude_desktop_config.json`:

- macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
- Windows: `%APPDATA%\Claude\claude_desktop_config.json`

Add your server under `mcpServers`. With a self-executing assembly jar or a
Native binary:

```json
{
  "mcpServers": {
    "greet": {
      "command": "/absolute/path/to/greet-server"
    }
  }
}
```

Or launching a plain jar explicitly through `java`:

```json
{
  "mcpServers": {
    "greet": {
      "command": "java",
      "args": ["-jar", "/absolute/path/to/greet-server.jar"]
    }
  }
}
```

Notes:

- Use **absolute paths** — Claude Desktop does not run the command from your
  project directory, and it does not load your shell profile, so anything on a
  custom `PATH` (like a specific `java`) should be given by full path.
- Environment variables can be passed with an `"env": { ... }` object next to
  `command`/`args`.

Restart Claude Desktop after editing the file. Your server's tools appear
under the tools icon in the chat input, and its resources and prompts under
the attach (+) menu.

## 2. Remote HTTP connector

### Write and run the server

```scala
//> using dep net.andimiller.mcp::mcp-core::0.13.0
//> using dep net.andimiller.mcp::mcp-http4s::0.13.0

import cats.effect.{IO, IOApp}
import com.comcast.ip4s.*
import net.andimiller.mcp.core.logging.NoOpLogging.given
import net.andimiller.mcp.http4s.McpHttp

object GreetHttpServer extends IOApp.Simple:
  def run: IO[Unit] =
    McpHttp.basic[IO]
      .name("greet-server").version("1.0.0")
      .port(port"8080")
      .withTool(GreetServer.greet)
      .serve
      .useForever
```

The MCP endpoint is served at `/mcp` — so this server is reachable at
`http://localhost:8080/mcp`. Use `McpHttp.streaming` instead of `McpHttp.basic`
if you need sessions, per-session state, subscriptions, or authentication.

Before involving Claude Desktop you can sanity-check the server with the
embedded Explorer UI: add `.withExplorer(redirectToRoot = true)` to the builder
and open `http://localhost:8080/explorer/index.html` in a browser.

### Add the connector

1. In Claude Desktop, open **Settings → Connectors**.
2. Click **Add custom connector**.
3. Enter a name and the server URL, e.g. `http://localhost:8080/mcp`.
4. Click **Add**, then enable the connector's tools from the tools menu in the
   chat input.

A connector added on claude.ai in the browser must be reachable from the
public internet — put the server behind a real hostname with TLS (or a tunnel
such as `ngrok`/`cloudflared`) and authentication before exposing it. For
servers that need auth, `McpHttp.streaming`'s `.authenticated[U]` hook lets
you validate credentials per request; see the per-user tool visibility docs
for gating individual tools by user.

## Troubleshooting

- **Server never connects (stdio):** check Claude Desktop's MCP logs —
  `~/Library/Logs/Claude/mcp*.log` on macOS, `%APPDATA%\Claude\logs` on
  Windows. The most common causes are a relative path in `command`, a `java`
  that isn't on Claude Desktop's `PATH`, or output written to stdout.
- **Connection drops mid-session (stdio):** almost always something writing to
  stdout — a library printing a banner, or debug output. Redirect it to stderr.
- **Tools don't appear after a config change:** fully quit and restart Claude
  Desktop; the config is only read at startup.
- **HTTP connector fails to add:** confirm the URL includes the `/mcp` path
  and that the server is actually up (`curl -X POST http://localhost:8080/mcp`
  should return a JSON-RPC error rather than a connection refusal).

:::

::: {.column width="50%"}

# Adding your MCP server to Claude Desktop

This guide shows you how to connect an MCP (Model Context Protocol) server
built with scala-mcp to Claude Desktop. There are two ways to do it, depending on which transport
your server uses:

| Your server uses | How Claude Desktop connects | Section |
|------------------|-----------------------------|---------|
| `mcp-stdio` | Runs your server as a subprocess, configured in `claude_desktop_config.json` | [Local stdio server](#local-stdio-server) |
| `mcp-http4s` | Connects to your server's URL as a custom connector | [Remote HTTP connector](#remote-http-connector) |

If you don't have a server yet, the [quick start](https://andimiller.github.io/scala-mcp/getting-started/quick-start.html)
walks you through building one.

## Local stdio server

Claude Desktop launches stdio servers itself and talks to them over
stdin/stdout. You give it a command to run in a config file.

### 1. Package your server

Claude Desktop needs a single command it can execute. Pick one:

**Fat JAR with sbt-assembly** — a fat JAR is a single JAR file holding your
code and every dependency. Add a main class and assembly settings to your
build, then:

```bash
sbt assembly
```

With `assemblyPrependShellScript` set (as the scala-mcp example servers do),
the output is directly executable:

```scala
assembly / assemblyPrependShellScript := Some(sbtassembly.AssemblyPlugin.defaultShellScript)
```

**Scala Native binary** — if your server cross-builds for Native:

```bash
sbt myServerNative/nativeLink
```

This produces a self-contained binary with no JVM required and a fast
startup time, which is a good fit for Claude Desktop since it starts the
server on launch.

> **Avoid `sbt run` here.** sbt prints build output to stdout, which
> corrupts the MCP handshake. Always point Claude Desktop at a packaged
> artifact.

### 2. Keep stdout clean

On stdio, stdout belongs to the protocol. Anything else your server prints
there will break the connection. `StdioTransport` handles this for the
library's own messages, but make sure your logging goes to stderr — for
example, configure your SLF4J backend with a stderr appender, or keep the
no-op default:

```scala
import net.andimiller.mcp.core.logging.NoOpLogging.given
```

### 3. Edit the Claude Desktop config

1. Open Claude Desktop.
2. Go to **Settings → Developer → Edit Config**. This opens (or creates)
   `claude_desktop_config.json`:
   - macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
   - Windows: `%APPDATA%\Claude\claude_desktop_config.json`
3. Add your server under the `mcpServers` key:

```json
{
  "mcpServers": {
    "my-server": {
      "command": "/absolute/path/to/my-server-binary"
    }
  }
}
```

If you built a plain fat JAR without the shell script prefix, run it through
`java`:

```json
{
  "mcpServers": {
    "my-server": {
      "command": "java",
      "args": ["-jar", "/absolute/path/to/my-server.jar"]
    }
  }
}
```

Use absolute paths — Claude Desktop does not run the command from your
project directory, and it does not load your shell profile, so commands from
your `PATH` may not resolve. You can pass environment variables with an
`"env"` object next to `"command"` if your server needs them.

### 4. Restart and verify

1. Fully restart Claude Desktop (quit it, don't just close the window).
2. Open a new chat and click the **connectors icon** (the sliders below the
   message box). Your server should be listed with its tools.
3. Ask Claude to use one of your tools to confirm the round trip works.

## Remote HTTP connector

If your server uses `mcp-http4s`, Claude Desktop connects to it over the
network as a **custom connector** — Claude's name for a remote MCP server
you add by URL — instead of launching a subprocess.

### 1. Run your server

An `McpHttp` server serves the MCP endpoint at `/mcp`:

```scala
McpHttp.basic[IO]
  .name("my-server").version("1.0.0")
  .port(port"8080")
  .withTool(myTool)
  .serve
  .useForever
```

For anything beyond local testing, put it behind HTTPS — Claude's clients
expect remote connectors to be reachable over a secure URL.

### 2. Add the connector

1. In Claude Desktop, go to **Settings → Connectors**.
2. Click **Add custom connector**.
3. Enter a name and your server's MCP URL, for example
   `https://my-server.example.com/mcp`.
4. Click **Add**. If your server requires OAuth, Claude walks you through
   the sign-in flow; a server without auth connects immediately.

> Custom connectors require a paid Claude plan (Pro, Max, Team, or
> Enterprise). On Team and Enterprise plans an admin may need to enable
> them for the organisation.

### 3. Verify

Open a new chat, click the connectors icon, and enable your connector. Its
tools appear in the list, and you can toggle individual tools on or off.

## Troubleshooting

- **Server doesn't appear after a restart** — check the config file is
  valid JSON and that the command path is absolute and executable.
- **Server appears but immediately disconnects** — something is writing to
  stdout. Check your logging configuration (see
  [Keep stdout clean](#2-keep-stdout-clean)).
- **Logs** — Claude Desktop writes MCP logs to
  `~/Library/Logs/Claude/mcp*.log` on macOS and
  `%APPDATA%\Claude\logs\` on Windows. Your server's stderr output lands
  in the per-server `mcp-server-<name>.log` file, which makes it the best
  place to look when a tool call fails.
- **Slow startup warnings** — a JVM fat JAR can take a few seconds to
  start. If Claude Desktop times out waiting for the handshake, prefer a
  Scala Native binary.

## See also

- [Quick start](https://andimiller.github.io/scala-mcp/getting-started/quick-start.html) — build the server this guide connects
- [Server construction](https://andimiller.github.io/scala-mcp/getting-started/server-construction.html) — stdio and HTTP transports in detail
- [Examples](https://andimiller.github.io/scala-mcp/examples/) — runnable servers with Claude client configs

:::
::::



### Technical Documentation

Explain the connect flow for an MCP client

:::: {style="display: flex; gap: 20px;"}
::: {.column width="50%"}

# The MCP client connect flow

Connecting to an MCP server is more than opening a socket — the protocol
requires a JSON-RPC handshake before any tools can be called. This page walks
through what happens between "I have a transport" and "I have a working
client", both at the wire level and in terms of this library's types.

In this library the whole flow is wrapped in a single
`Resource[F, McpClient[F]]` — `StdioMcpClient.builder ... .connect` or
`StreamableHttpMcpClient.builder ... .connect` — so most users never see the
intermediate steps. Understanding them still pays off when debugging a
connection, implementing a custom transport, or deciding what capabilities to
advertise.

## The five steps

```
Client                                          Server
  │  1. open transport (spawn / HTTP)             │
  │──────────────────────────────────────────────▶│
  │  2. initialize request                        │
  │──────────────────────────────────────────────▶│
  │  3. initialize response                       │
  │◀──────────────────────────────────────────────│
  │  4. notifications/initialized                 │
  │──────────────────────────────────────────────▶│
  │  5. normal operation (tools/list, ...)        │
  │◀─────────────────────────────────────────────▶│
```

### 1. Open the transport

- **Stdio:** the client spawns the server as a subprocess and speaks
  newline-delimited JSON-RPC over its stdin/stdout.
- **Streamable HTTP:** the client sends each request as a `POST` to the MCP
  endpoint (e.g. `http://localhost:8080/mcp`), and optionally opens a
  long-poll `GET` with `Accept: text/event-stream` on the same endpoint to
  receive server-initiated traffic (notifications, and server→client requests
  like elicitation).

As soon as the channel exists, the library starts a background session loop
(`ClientSession`) that reads every incoming message and dispatches it:
responses complete their pending request, notifications are published to the
`McpClient.notifications` stream (and the `ClientHandler.handleNotification`
callback), and server-initiated requests are routed to your `ClientHandler`.

At this point you have an `UninitializedMcpClient[F]` — a client that can do
exactly one thing: `initialize`.

### 2. Send `initialize`

The client sends the `initialize` request, declaring three things:

- **`protocolVersion`** — the protocol revision it wants to speak. The
  library's default is `2025-11-25`; override it with the `protocolVersion`
  argument to `initialize` if you need an older revision.
- **`clientInfo`** — the client's name and version (`Implementation`), used
  by servers for logging and diagnostics. Set via `.withInfo(...)`.
- **`capabilities`** — which *server-initiated* callbacks this client is
  prepared to answer: `sampling` (run a completion for the server),
  `elicitation` (ask the user for input), `roots` (expose filesystem roots).
  Set via `.withCapabilities(...)`; the default is none.

```json
{
  "jsonrpc": "2.0",
  "id": 0,
  "method": "initialize",
  "params": {
    "protocolVersion": "2025-11-25",
    "capabilities": {
      "elicitation": { "form": {} }
    },
    "clientInfo": { "name": "my-client", "version": "0.1.0" }
  }
}
```

Capabilities are a contract, not a hint: a well-behaved server will only send
`sampling/createMessage`, `elicitation/create`, or `roots/list` requests if
the client advertised the matching capability — and if you advertise one, you
must pass a `ClientHandler` that actually answers it (the default
`ClientHandler.noop` replies `MethodNotFound` to everything).

### 3. Receive the `initialize` response

The server replies with the mirror image — its negotiated protocol version,
its own `serverInfo`, and *its* capabilities (which of tools, resources,
prompts, subscriptions, and logging it supports):

```json
{
  "jsonrpc": "2.0",
  "id": 0,
  "result": {
    "protocolVersion": "2025-11-25",
    "capabilities": {
      "tools": { "listChanged": true },
      "resources": { "subscribe": true },
      "prompts": {}
    },
    "serverInfo": { "name": "greet-server", "version": "1.0.0" }
  }
}
```

**Streamable HTTP only:** the response to `initialize` also carries an
`Mcp-Session-Id` header. The client captures it and attaches it to every
subsequent request — that header *is* the session. The SSE `GET` stream is
opened once the session id is known.

If the server returns a JSON-RPC error, or a result that doesn't decode as an
`InitializeResponse`, the library raises
`ClientSession.InitializeFailedException` and no client is produced.

### 4. Send `notifications/initialized`

The client acknowledges with a fire-and-forget notification:

```json
{ "jsonrpc": "2.0", "method": "notifications/initialized" }
```

This tells the server the handshake is complete and it may now send its own
requests and notifications. The library sends this automatically as part of
`initialize`.

One HTTP-specific subtlety the library handles for you: `initialize` doesn't
return until the SSE `GET` stream is confirmed subscribed on the server side.
Without that barrier, a server-initiated request fired during your very first
tool call (say, an elicitation) could be published before anyone is listening
and silently vanish.

### 5. Normal operation

`initialize` yields a fully-typed `McpClient[F]`. The negotiated values are
plain fields rather than effects or `Option`s — the existence of the client is
proof the handshake succeeded:

```scala
client.serverInfo          // Implementation(name, version)
client.serverCapabilities  // ServerCapabilities
client.protocolVersion     // String
```

From here the capability-driven methods are available: `listTools` /
`callTool`, `listResources` / `readResource` / `subscribe`, `listPrompts` /
`getPrompt`, and `ping`. Check `serverCapabilities` before relying on an
optional feature — calling `subscribe` against a server that didn't advertise
`resources.subscribe` will earn you a JSON-RPC error
(`ClientSession.McpRemoteException`).

## Disconnecting

Teardown runs when the `Resource` is released:

- **Stdio:** the client signals EOF on the child's stdin and cancels the
  message-reader fiber; the server sees EOF and shuts down.
- **Streamable HTTP:** the client sends an HTTP `DELETE` to the endpoint with
  the `Mcp-Session-Id` header, so the server can free per-session state
  (`.stateful` context, subscriptions), and closes the SSE stream.

There is no protocol-level "goodbye" message — transport closure is the
shutdown signal.

## Doing it manually

If the builders don't fit — you spawned the process yourself, you're testing
over in-memory pipes, or you need to control handshake timing — drop down a
layer:

```scala
import net.andimiller.mcp.core.client.ClientSession
import net.andimiller.mcp.core.protocol.{ClientCapabilities, Implementation}

// any MessageChannel[F]: stdio pipes, HTTP, or in-memory queues
ClientSession.resource[IO](channel).use { uninit =>
  for
    client <- uninit.initialize(
                Implementation("my-client", "0.1.0"),
                ClientCapabilities(),
                protocolVersion = "2025-11-25"
              )
    tools  <- client.listTools()
  yield tools
}
```

`StdioMcpClient.fromStreams` and `StreamableHttpMcpClient.fromHttpClient` both
return this same `UninitializedMcpClient[F]`, so you can separate "transport
is up" from "handshake has run" whenever that distinction matters.

## Failure modes at a glance

| Symptom | Meaning |
|---|---|
| `InitializeFailedException` | The server rejected `initialize` (version mismatch, auth failure) or returned an undecodable response. |
| `McpRemoteException` | A post-handshake request failed server-side; carries the JSON-RPC error code and message. |
| `McpDecodeException` | The server's response didn't match the protocol shape; carries the offending JSON body. |
| Hangs on first request (stdio) | The server is writing non-protocol output to stdout, or never started its read loop. |
| `400 Missing Mcp-Session-Id` (HTTP) | A request reached the server without the session header — the session id from `initialize` wasn't threaded through (the library's client does this automatically). |

:::

::: {.column width="50%"}

# The MCP client connect flow

This page explains what happens when an MCP (Model Context Protocol)
client connects to a server —
both at the protocol level and in terms of what scala-mcp's `McpClient`
does for you. Read this if you want to understand what `.connect` actually
does, or if you need to control the handshake yourself.

## The flow at a glance

Connecting has three phases. Every MCP client goes through them, whatever
the transport:

```
Client                                Server
  │                                     │
  │ 1. open transport                   │
  │────────────────────────────────────>│  (spawn subprocess / open HTTP)
  │                                     │
  │ 2. initialize request               │
  │────────────────────────────────────>│
  │    initialize response              │
  │<────────────────────────────────────│
  │                                     │
  │ 3. notifications/initialized        │
  │────────────────────────────────────>│
  │                                     │
  │    ── session is live ──            │
  │    tools/list, tools/call, ...      │
```

1. **Open the transport.** For stdio this means spawning the server as a
   subprocess and attaching to its stdin/stdout. For streamable HTTP it
   means having an HTTP client pointed at the server's MCP endpoint.
2. **The `initialize` handshake.** The client sends an `initialize`
   request; the server replies with its identity and capabilities. All MCP
   messages are JSON-RPC: JSON objects that name a method and carry its
   parameters. The spec allows only one `initialize` per session.
3. **The `initialized` notification.** The client sends
   `notifications/initialized` to confirm it is ready. After this, both
   sides can send normal requests and notifications.

## What the handshake exchanges

The `initialize` request carries three things:

- **`protocolVersion`** — the MCP spec version the client wants to speak.
  scala-mcp defaults to `McpProtocol.DefaultVersion` (currently
  `2025-11-25`). The server replies with the version it will actually use,
  which may be older.
- **`clientInfo`** — the client's name and version, an `Implementation`.
  Set it with `.withInfo(Implementation("my-client", "0.1.0"))`.
- **`capabilities`** — what the client itself can do, a
  `ClientCapabilities`. Declare `sampling`, `elicitation`, or `roots` here
  only if you install a handler for them — see
  [Client handlers](https://andimiller.github.io/scala-mcp/clients/client-handlers.html).

The response carries the mirror image: `serverInfo`, the server's
`capabilities` (does it have tools? resources? does it support
subscriptions?), and the confirmed `protocolVersion`.

## How scala-mcp runs the flow

Both transports give you two entry points, depending on how much control
you want.

### The builder: one step

`StdioMcpClient.builder` and `StreamableHttpMcpClient.builder` wrap
"open transport + initialize + initialized" into a single
`Resource[F, McpClient[F]]`:

```scala
StdioMcpClient
  .builder[IO]
  .withCommand("./my-server-binary")
  .withInfo(Implementation("my-client", "0.1.0"))
  .connect                     // Resource[IO, McpClient[IO]]
  .use { client =>
    client.listTools().flatMap(t => IO.println(s"${t.tools.size} tool(s)"))
  }
```

By the time `.use` runs, the handshake is done. That's why
`McpClient[F]` exposes the negotiated values as plain fields — no effects,
no `Option`s:

```scala
client.serverInfo          // Implementation(name, version)
client.serverCapabilities  // ServerCapabilities
client.protocolVersion     // String
```

The existence of an `McpClient` is proof the handshake succeeded.

### The low-level entry point: two steps

`StdioMcpClient.fromStreams` and
`StreamableHttpMcpClient.fromHttpClient` stop after phase 1. They return
an `UninitializedMcpClient[F]`, and you run the handshake yourself:

```scala
def initialize(
    info: Implementation,
    capabilities: ClientCapabilities,
    protocolVersion: String = McpProtocol.DefaultVersion
): F[McpClient[F]]
```

`initialize` sends the request, decodes the response, sends
`notifications/initialized`, and yields the typed client. Use this route
when you spawned the process yourself, when you're testing over in-memory
byte streams, or when you need to time the handshake precisely. Call it
once — the spec allows one `initialize` per session.

## Transport differences

The three phases are the same on both transports, but the mechanics differ.

### Stdio

- Phase 1 spawns the server process; messages are newline-delimited JSON
  over its stdin/stdout.
- Releasing the client `Resource` signals EOF on the child's stdin and
  stops the message-reader fiber, which is how a stdio session ends.

### Streamable HTTP

- Every request is a `POST` to the single MCP endpoint (e.g.
  `http://localhost:8080/mcp`).
- The server assigns a session in its `initialize` response via the
  `Mcp-Session-Id` header. The client captures it and sends it on every
  subsequent request — this is what ties your `tools/call` to the state
  created at initialize time.
- The builder also opens an SSE `GET` on the same endpoint — SSE
  (Server-Sent Events) is an HTTP response the server keeps open and
  streams messages down — so the server can push notifications and
  server-initiated requests. Turn this off with `.withSse(false)` if you
  only need request/response.
- Releasing the client `Resource` sends an HTTP `DELETE` to the endpoint,
  which tells the server to free the session's state.

## When connecting fails

- A JSON-RPC error in response to `initialize` (wrong endpoint, server
  rejected the protocol version) raises
  `ClientSession.InitializeFailedException`, carrying the error code and
  message.
- A response that doesn't decode as an `initialize` result (you pointed
  the client at something that isn't an MCP server) also raises
  `InitializeFailedException`, with the decode failure attached.
- With the builder, either failure happens during `Resource` acquisition,
  so `.use` never runs and the `Resource` still closes the transport.

After a successful connect, failures from individual calls surface as
`ClientSession.McpRemoteException` (the server returned a JSON-RPC error)
or `ClientSession.McpDecodeException` (the server returned JSON that
didn't match the protocol shape).

## See also

- [Client construction](https://andimiller.github.io/scala-mcp/clients/client-construction.html) — full builder API for both transports
- [Client handlers](https://andimiller.github.io/scala-mcp/clients/client-handlers.html) — handling server-initiated requests, and the capabilities to advertise for them
- [Examples → CLI client](https://andimiller.github.io/scala-mcp/examples/cli-client.html) — a runnable REPL over either transport

:::
::::



### Product Feature RFC

Product Feature RFC, "propose a new standard endpoint that's included in the default streamable HTTP transport which returns to return a full openapi spec for the tools

:::: {style="display: flex; gap: 20px;"}
::: {.column width="50%"}

# RFC: OpenAPI spec endpoint for the streamable HTTP transport

- **Status:** Draft
- **Target modules:** `mcp-http4s`, `mcp-openapi`

## Summary

Add a standard, session-less endpoint to the streamable HTTP transport —
`GET /mcp/openapi.json` — that returns an OpenAPI 3.1 document describing
every tool the server exposes. The endpoint is served by default alongside the
existing `POST` / `GET` / `DELETE /mcp` routes, with a builder knob to disable
or customise it.

## Motivation

Every MCP tool already carries a full JSON Schema for its input (and
optionally its output) — the raw material of an OpenAPI spec. But today the
only way to see it is to perform the whole MCP handshake: `initialize`,
capture `Mcp-Session-Id`, send `tools/list`, decode the JSON-RPC envelope.
That shuts out a large ecosystem of tooling that speaks plain HTTP + OpenAPI:

- **Discovery without a client.** `curl http://host/mcp/openapi.json` answers
  "what can this server do?" — useful for humans, CI checks, and API catalogs
  that index OpenAPI documents.
- **Codegen.** Existing OpenAPI generators can produce typed client bindings
  for a server's tools in any language, without an MCP SDK.
- **Contract testing and diffing.** `oasdiff` and friends can flag breaking
  changes between deployments; the spec becomes a reviewable artifact, which
  pairs naturally with the golden-testing module's snapshot approach.
- **Symmetry.** This library already converts OpenAPI operations *into* MCP
  tools (the `mcp-openapi` module and the `openapi-mcp-proxy` CLI). This RFC
  is the inverse arrow — MCP tools *out* to OpenAPI — completing the round
  trip and enabling round-trip tests.

## Goals and non-goals

**Goals**

- A default-on, unauthenticated-friendly `GET` endpoint returning a valid
  OpenAPI 3.1 document covering the server's tools.
- Zero configuration for the common case; the document is derived entirely
  from state the builder already holds (`name`, `version`, tool definitions).
- Correct interaction with `.authenticated` servers and per-user tool
  visibility.

**Non-goals**

- **A REST invocation bridge.** The document describes tools as virtual REST
  operations, but this RFC does not add routes that execute them (see
  [Alternatives](#alternatives-considered)). Invocation remains JSON-RPC
  `tools/call` over `POST /mcp`.
- Describing resources and prompts. They have no request/response schema
  pair, so they map poorly onto OpenAPI operations; they can be revisited
  later as `x-mcp-resources` / `x-mcp-prompts` extensions if there is demand.
- Changing the MCP protocol itself. This is purely a transport-level
  affordance, like the embedded Explorer UI.

## Design

### Endpoint

```
GET /mcp/openapi.json
```

- Sits beside the existing routes in `StreamableHttpTransport.buildRoutes`
  (`POST | GET | DELETE -> Root / "mcp"`), so it introduces no path
  conflicts.
- **No `Mcp-Session-Id` required** — the whole point is pre-handshake
  discovery.
- Responds `200` with `Content-Type: application/vnd.oai.openapi+json` (the
  registered OpenAPI media type, falling back to `application/json` semantics
  for consumers that don't know it).
- Sends an `ETag` derived from a hash of the document so catalogs polling for
  changes get cheap `304`s. The document for a given tool set is a pure
  value, so this is trivially correct.

### Why OpenAPI 3.1

MCP tool schemas are JSON Schema. OpenAPI 3.1's schema dialect *is* JSON
Schema 2020-12, so `inputSchema` and `outputSchema` embed **unchanged** — no
lossy translation layer of the kind OpenAPI 3.0 (with its `nullable` and
restricted keyword set) would force. This also mirrors what the `mcp-openapi`
module's `sttp.apispec` model already supports.

### Document shape

Each tool becomes one path item under a virtual `tools` namespace. For the
quick-start `greet` tool on a server named `greet-server` v`1.0.0`:

```json
{
  "openapi": "3.1.0",
  "info": {
    "title": "greet-server",
    "version": "1.0.0",
    "x-mcp": { "protocolVersion": "2025-11-25", "transport": "streamable-http" }
  },
  "servers": [{ "url": "/mcp" }],
  "paths": {
    "/tools/greet": {
      "post": {
        "operationId": "greet",
        "description": "Greet someone by name",
        "requestBody": {
          "required": true,
          "content": {
            "application/json": {
              "schema": {
                "type": "object",
                "properties": { "name": { "type": "string" } },
                "required": ["name"]
              }
            }
          }
        },
        "responses": {
          "200": {
            "description": "Tool result",
            "content": {
              "application/json": {
                "schema": {
                  "type": "object",
                  "properties": { "message": { "type": "string" } },
                  "required": ["message"]
                }
              }
            }
          }
        }
      }
    }
  }
}
```

The paths are **descriptive, not routable** — a consumer that wants to call
`greet` still does so via `tools/call`. The `x-mcp` extension in `info` makes
that unambiguous, and generated clients get correct types even if their
transport glue needs to be MCP-aware.

### Field mapping

| MCP `ToolDefinition` | OpenAPI |
|---|---|
| `name` | path segment `/tools/{name}` and `operationId` |
| `title` | operation `summary` |
| `description` | operation `description` |
| `inputSchema` | `requestBody.content["application/json"].schema`, verbatim |
| `outputSchema` (present) | `responses.200.content["application/json"].schema`, verbatim |
| `outputSchema` (absent) | the generic `CallToolResponse` content shape (array of content blocks) |
| `annotations` (readOnlyHint, destructiveHint, …) | `x-mcp-annotations` extension on the operation |
| `icons`, `_meta` | `x-mcp-icons` / `x-mcp-meta` extensions |
| server `name` / `version` | `info.title` / `info.version` |

Tool-level JSON-RPC failures map to a shared `default` error response
(`JsonRpcError`'s shape) declared once in `components.responses` and
referenced from every operation.

### Interaction with authentication and per-user tools

This is the one genuinely subtle design point. `McpHttp.streaming`'s
`.authenticated[U]` binds a user at `initialize`, and `.withToolIf` /
`.withToolIfF` filter the tool list **per session** — so "the server's tools"
is not always a well-defined session-less concept.

Proposed behaviour, in order of server flavour:

1. **Unauthenticated server** (`McpHttp.basic`, or `streaming` without
   `.authenticated`): the endpoint is public and lists all tools. This is the
   same information `tools/list` would hand any anonymous session, so nothing
   new is exposed.
2. **Authenticated server:** the endpoint runs the same `authCheck` injection
   point the JSON-RPC routes use. Unauthenticated requests get the
   builder's `onUnauthorized` response; authenticated ones get a spec with
   the `withToolIf` predicates evaluated against *their* user — exactly the
   tool set an `initialize` by that user would see. Effectful `withToolIfF`
   predicates run per spec request, mirroring their per-init semantics.

This keeps the invariant that the spec endpoint never reveals a tool the
requesting principal couldn't list over MCP. In particular it must **not**
fall back to "all tools" on an authenticated server — hidden-tool gating is
a security feature and the spec endpoint must respect it.

### Builder surface

Default-on for both HTTP builders, with an opt-out and light customisation:

```scala
McpHttp.streaming[IO]
  .name("greet-server").version("1.0.0")
  .withTool(greet)
  .withOpenApiSpec()                    // default; explicit call allows config
  // .withOpenApiSpec(enabled = false)  // opt out
  // .withOpenApiSpec(path = "spec.json", extraInfo = ...)  // customise
```

Following the precedent set by `.withExplorer`, the endpoint is part of the
transport's value proposition and should work with zero configuration —
hence default-on. Servers that consider even tool *names* sensitive on an
unauthenticated deployment can disable it.

The Explorer UI should also link to the spec (it already knows the endpoint
origin), giving it a free "export as OpenAPI" affordance.

## Implementation sketch

1. **`mcp-openapi`: the pure conversion.** Add
   `ToolsToOpenApi.render(info: Implementation, tools: List[ToolDefinition]): sttp.apispec.openapi.OpenAPI`.
   The module already depends on `sttp.apispec` and owns the opposite
   direction (`OpenApiOperation.build`); putting the renderer here keeps
   `mcp-http4s` free of a new dependency edge and makes the function usable
   from stdio servers, tests, and build tasks (e.g. "write the spec to a file
   at compile time").
2. **`mcp-http4s`: the route.** `StreamableHttpTransport.buildRoutes` gains a
   `GET -> Root / "mcp" / "openapi.json"` case, threading through the
   existing `authCheck` injection point. The tool list (and, on authenticated
   servers, the visibility predicates) is already available where the routes
   are built. This adds an `mcp-http4s → mcp-openapi` module dependency —
   acceptable, since `mcp-openapi` is small, cross-built to the same
   platforms, and has no transport dependencies. If that edge is unwanted,
   the alternative is a `ToolSpecRenderer` interface in core with the openapi
   module supplying the instance, at the cost of the endpoint no longer being
   default-on.
3. **Round-trip test.** Feed the rendered spec back through
   `OpenApiOperation.build` and assert the reconstructed `ToolDefinition`s
   match the originals (modulo the `x-mcp-*` extensions). This test is the
   strongest guarantee the mapping table above stays honest, and fits
   naturally into the golden-munit snapshot suite.

## Alternatives considered

- **Describe the real wire (`POST /mcp` with a JSON-RPC envelope).** Honest
  but useless: one operation whose request schema is a `oneOf` over every
  method, which defeats codegen and diffing — the two main consumers.
- **A live REST bridge (actually serve `POST /mcp/tools/{name}`).** Makes the
  spec executable, which is attractive, but it's a second invocation surface
  with its own session, auth, and elicitation semantics (what does a REST
  call do when a tool elicits?). Worth a separate RFC; this proposal's
  virtual-path shape is forward-compatible with it — the bridge would simply
  make the documented paths real.
- **Serve it under `/.well-known/`.** Better for org-level crawlers, but
  MCP servers are frequently mounted under a path prefix on a shared host,
  where `/.well-known/` (a host-root concept) doesn't compose. `/mcp/openapi.json`
  travels with the mount point. A deployment can always add the well-known
  alias itself.
- **A `tools/openapi` JSON-RPC method instead of an HTTP route.** Keeps it
  transport-agnostic, but requires a full MCP client and session — which is
  precisely the barrier this RFC exists to remove.

## Open questions

1. Should `GET /mcp/openapi.json` on an **authenticated** server offer an
   anonymous "public subset" (tools with no `withToolIf` gate) rather than
   requiring credentials? Defaulting to require-auth is the conservative
   choice proposed here.
2. Should resources with templates be represented as `GET` operations with
   path parameters? Deferred — see non-goals.
3. Is `application/vnd.oai.openapi+json` worth the compatibility risk versus
   plain `application/json`? Proposed: send the vendor type; it degrades
   gracefully.
4. Should the stdio transport get an equivalent (e.g. a `--dump-openapi`
   convention or a `ToolsToOpenApi` doc example)? The pure renderer in
   `mcp-openapi` makes this cheap for users to do themselves either way.

:::

::: {.column width="50%"}

# RFC: OpenAPI spec endpoint for the streamable HTTP transport

| | |
|---|---|
| **Status** | Draft |
| **Target modules** | `mcp-http4s`, `mcp-openapi` |
| **New endpoint** | `GET /mcp/openapi.json` |

## Summary

Add a standard endpoint to the streamable HTTP transport that returns an
OpenAPI 3.1 document (the standard machine-readable description format for
HTTP APIs) describing the server's tools. The endpoint is on by default in
both `McpHttp.basic` and `McpHttp.streaming`, requires no MCP session, and
one builder call turns it off.

## Motivation

Today the only way to find out what tools a server exposes is to speak MCP:
open a session, run the `initialize` handshake, then call `tools/list`.
That shuts out a large ecosystem of tooling that already understands
OpenAPI:

- **Discovery without a handshake** — a `curl` or a browser tab can answer
  "what does this server do?" No JSON-RPC client needed.
- **Existing OpenAPI tooling** — docs UIs, API gateways,
  client generators, and contract-testing tools all consume
  `openapi.json` directly.
- **Symmetry with what we already ship** — the
  [OpenAPI MCP Proxy](https://andimiller.github.io/scala-mcp/tools/openapi-mcp-proxy.html)
  turns an OpenAPI spec into MCP tools. This endpoint is the same bridge in
  the other direction, and closes a round trip: a spec emitted by a
  scala-mcp server can be fed back through the proxy to reproduce the same
  tools.

Everything needed already exists in the codebase: `ToolDefinition` carries
its input and output schemas as JSON Schema (`inputSchema: Json`,
`outputSchema: Option[Json]`), and the `mcp-openapi` module already depends
on sttp's `openapi-model` for the OpenAPI document type.

## Goals

- One `GET` endpoint, JSON response, served by default on both HTTP builders.
- Accurate schemas: the spec contains exactly what `tools/list` reports.
- Respect per-user tool visibility on authenticated servers.
- No new third-party dependencies.

## Non-goals

- **A REST bridge.** The spec documents the tools; it does not add
  REST-style `POST /mcp/tools/{name}` routes that actually execute them.
  An extension on each path (see below) tells readers that calls go over
  JSON-RPC. A bridge could be a follow-up RFC.
- **Resources and prompts.** Tools map cleanly onto OpenAPI operations;
  resources and prompts don't. They stay out of scope.
- **OpenAPI 3.0 output.** See "Why 3.1" below.

## Proposed design

### The endpoint

```
GET /mcp/openapi.json
```

- Lives under the same `/mcp` prefix as the transport's existing
  `POST`/`GET`/`DELETE` routes, so it inherits any router mount point and
  middleware unchanged.
- Returns `200 OK` with `Content-Type: application/json`.
- Needs no `Mcp-Session-Id` — it's a plain HTTP GET, usable before any
  session exists.

### Document shape

One OpenAPI 3.1 document. `info` comes from the server's name and version
(the same `Implementation` sent in the `initialize` response). Each tool
becomes one path item:

| MCP tool field | OpenAPI location |
|----------------|------------------|
| `name` | path (`/mcp/tools/{name}`) and `operationId` |
| `title` | operation `summary` |
| `description` | operation `description` |
| `inputSchema` | `requestBody` → `application/json` schema |
| `outputSchema` | `200` response → `application/json` schema |
| `annotations` (read-only hint etc.) | `x-mcp-annotations` extension |

Tools with no `outputSchema` get a `200` response with the generic MCP
content-result schema (text/image/resource content items). The spec defines
that schema once in `components/schemas` and references it from each such
response.

Two extensions make the document honest about what it describes:

- Top level: `"x-mcp": { "endpoint": "/mcp", "protocolVersion": "2025-11-25" }`
  — where the real JSON-RPC endpoint is and which MCP version it speaks.
- Per operation: `"x-mcp-transport": "json-rpc"` — the path is a
  description of a tool, not a callable REST route.

### Example

For the quick-start `greet` tool:

```json
{
  "openapi": "3.1.0",
  "info": { "title": "my-server", "version": "1.0.0" },
  "x-mcp": { "endpoint": "/mcp", "protocolVersion": "2025-11-25" },
  "paths": {
    "/mcp/tools/greet": {
      "post": {
        "operationId": "greet",
        "description": "Greet someone by name",
        "x-mcp-transport": "json-rpc",
        "requestBody": {
          "required": true,
          "content": {
            "application/json": {
              "schema": {
                "type": "object",
                "properties": { "name": { "type": "string" } },
                "required": ["name"]
              }
            }
          }
        },
        "responses": {
          "200": {
            "description": "Tool result",
            "content": {
              "application/json": {
                "schema": {
                  "type": "object",
                  "properties": { "message": { "type": "string" } },
                  "required": ["message"]
                }
              }
            }
          }
        }
      }
    }
  }
}
```

### Why OpenAPI 3.1

MCP tool schemas are JSON Schema, produced by `derives JsonSchema`.
OpenAPI 3.1 uses standard JSON Schema natively, so `inputSchema` and
`outputSchema` embed word-for-word — no conversion, no loss. OpenAPI 3.0
has its own schema dialect and would need a rewrite that loses information
(no `const`, different `nullable` handling). Emitting 3.1 means the
endpoint copies out schemas the server already holds, unchanged.

### Builder API

On by default, per builder:

```scala
McpHttp.basic[IO]
  .name("my-server").version("1.0.0")
  .withTool(greetTool)
  .withOpenApiSpec(false)   // opt out; default is true
  .serve
```

`McpHttpConfig` gains a matching `openApiSpecEnabled: Boolean = true` for
the `serve*` convenience methods, alongside the existing
`explorerEnabled` flag.

### Authentication and per-user tools

The streaming builder complicates "the server's tools" in two ways, and the
endpoint handles both:

1. **`.authenticated[U]`** — the spec endpoint runs the same `extract`
   function on the incoming `GET`. When `extract` finds no user, the
   endpoint replies with the configured `onUnauthorized` response. The spec
   never leaks tool schemas past the auth the JSON-RPC endpoint enforces.
2. **`.withToolIf` / `.withToolIfF`** — the endpoint evaluates the
   visibility predicates against the extracted user, exactly as the server
   does when a session starts. Different users can receive different specs,
   matching what their own `tools/list` would return.

Servers built from a session factory (`StdioTransport`-style
`ctx => F[Server[F]]` wiring) can register tools dynamically per session;
the spec reflects the statically registered tools only. This RFC documents
that limitation rather than solving it.

### Implementation sketch

- **`mcp-openapi`** gains the converter — the natural home, as the inverse
  of the existing `OpenApiOperation`, which converts OpenAPI operations to
  `ToolDefinition`s:

  ```scala
  object ToolSpec:
    def toOpenApi(info: Implementation, tools: List[ToolDefinition]): OpenAPI
  ```

  Built on the `sttp.apispec.openapi` types already on this module's
  classpath, and rendered to JSON with `openapi-circe`.

- **`mcp-http4s`** adds a module dependency on `mcp-openapi` (platforms are
  compatible: openapi builds for JVM/JS/Native, http4s for JVM/JS) and one
  route next to the existing three in `StreamableHttpTransport`:

  ```scala
  case GET -> Root / "mcp" / "openapi.json" => Ok(spec)
  ```

- The builder assembles the document once at `.serve` time and caches it,
  since the tool list on an unauthenticated server never changes. A server
  with visibility predicates rebuilds the document on each request, since
  the answer depends on the caller.

### Testing

- Golden tests via `mcp-golden-munit`: snapshot the emitted spec for the
  example servers, so schema-derivation changes show up as reviewable
  diffs.
- Round-trip test: feed the emitted spec to `OpenApiOperation.build` and
  assert the reconstructed `ToolDefinition`s match the originals in name,
  description, and input schema.

## Alternatives considered

- **`GET /mcp` with content negotiation** — overloads a path the
  transport already uses for its server-push stream; a typo in the
  `Accept` header would silently return the wrong thing. Rejected.
- **`/.well-known/mcp-openapi.json`** — well-known URIs must sit at the
  server root, which breaks when you mount the MCP routes under a prefix,
  and the name would need registering with IANA. Rejected.
- **Serving the spec as an MCP resource instead** — keeps it inside the
  protocol, but the whole point is reaching consumers that don't speak
  MCP. Adding it later as well would be cheap.

## Open questions

1. Should the Explorer UI link to (or render) the spec? It already has the
   tool list over MCP, so a link would be a convenience only.
2. Should `x-mcp-annotations` be flattened into individual extensions
   (`x-mcp-read-only: true`) for easier gateway filtering?
3. Is a YAML variant (`/mcp/openapi.yaml`) worth the extra dependency, or
   do we leave conversion to the consumer?

:::
::::

# Conclusion

The left side is default fable, the right side was given the extra guidance to follow the rules, you can make your own mind up with you prefer.
