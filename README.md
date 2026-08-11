# TinyStats

<p align="center">
  <b>Real-time system metrics dashboard — 71 KB binary</b><br/>
  A rewrite of <a href="https://github.com/javimosch/ministats">MiniStats</a> in Machin/MFL.<br/>
  Same features, 1400× smaller binary.
</p>

<p align="center">
  <img src="https://img.shields.io/github/license/javimosch/machin-tinystats" />
  <img src="https://img.shields.io/github/stars/javimosch/machin-tinystats" />
</p>

## Why?

[MiniStats](https://github.com/javimosch/ministats) is a real-time multi-machine metrics dashboard built with Bun/TypeScript. It works, but the compiled binary is **99 MB** because it bundles the entire Bun runtime.

TinyStats is the same app rebuilt in [Machin/MFL](https://github.com/javimosch/machin) — a language that compiles through C to native code. The result:

| | MiniStats (Bun) | TinyStats (Machin) |
|---|---|---|
| Binary size | 99 MB | **71 KB** |
| Compression | 25 MB (.xz) | 71 KB (already tiny) |
| Runtime bundled | yes (Bun) | no (pure C output) |
| Dependencies | libc, libm | libc, libm |
| Source lines | ~300 TS | ~250 MFL |

Same architecture: one server, N clients, WebSocket broadcast, no database. Same dashboard UI. Same commands.

## Screenshot

![dashboard](docs/screenshot.png)

## Features

- Real-time metrics via WebSocket (CPU load, memory, disk, inodes)
- Centralized dashboard (multi-machine, 2-column grid)
- Zero-config install (single static binary)
- Stale client detection and pruning
- HTTP POST fallback for clients behind firewalls
- IBM Plex Mono + scanline overlay UI

## Quick Start

### 1. Download

```bash
curl -fsSL https://raw.githubusercontent.com/javimosch/machin-tinystats/master/scripts/install.sh | bash
```

### 2. Start Server

```bash
tinystats server --port 9094
```

Open → http://localhost:9094

### 3. Connect Machines

```bash
tinystats client --name my-machine --server http://YOUR_SERVER_IP:9094
```

Done. Metrics appear instantly.

## Commands

```bash
tinystats server --port <port>                    # start the dashboard server
tinystats client --name <name> --server <url>     # connect a machine
tinystats -v                                      # show version
tinystats help                                    # usage
```

## Build from Source

Requires [Machin](https://github.com/javimosch/machin) installed (`go install` or `make install` from the machin repo):

```bash
./build.sh
```

This encodes the MFL source (`framework/machweb.src` + `framework/ws.src` + `src/*.src`) to a single `.mfl` and compiles it to a native binary.

## Architecture

```
[ client ] --->\
[ client ] ----->  [ server ] ---> Web UI (WebSocket)
[ client ] --->/
```

- Clients collect metrics every 5s via `free`, `df`, `df -i`, `uptime`
- Clients POST JSON to `/api/report` (HTTP) — the server broadcasts to dashboards
- Dashboards connect via WebSocket at `/ws` and receive the full state on every update
- A single hub goroutine owns all state (dashboards map + clients map) — race-free by design
- No database, no persistence — just what's happening right now

## How it works

The server uses Machin's `machweb` framework (HTTP server) + `ws` framework (WebSocket RFC 6455 implementation). Both are pure MFL — no external libraries. The WebSocket codec parses and builds frames with byte-level operations (`byte_at`, `bytes_concat`, XOR unmasking).

The client uses `http_request()` (Machin's built-in HTTP client) to POST metrics as JSON. No WebSocket client needed — simple HTTP POST, which also works behind firewalls that block WebSocket upgrades.

## Philosophy

Same as MiniStats: simplicity over features, speed over completeness, usability over configurability. If you need long-term metrics, alerts, and analytics → use Prometheus + Grafana. If you just want to see what's happening now → use TinyStats.

## Why Machin?

Machin compiles MFL to C, then to native code. No runtime, no garbage collector, no bundled interpreter. The binary is just C compiled with `cc -O2`. That's why it's 71 KB instead of 99 MB — there's nothing in the binary except the actual program logic and the libc calls it needs.

## Contributing

PRs welcome. Keep it simple.

## License

MIT
