# Changelog

What changed in each skram-tunnel release, for someone running the binary.
Versions follow semver.

## [Unreleased]

## [0.4.0] — 2026-09-27

- Owned paths: a login that spans several hosts (an app, a login broker, an
  identity provider) completes on one public origin. `--path <name>=<path>`
  (repeatable; `paths` in `tunnel_start`; `upstreams: {name: {url, paths}}`
  in config) serves an extra upstream at those paths unchanged instead of
  under `/__<name>`. Redirects, form bodies and cookie domains are mapped
  between the public origin and whichever upstream owns the path.
- `verify` probes like a phone's browser and tells you what to do next. It
  follows redirects through a login broker to the identity provider, flags a
  redirect or an API call to a host the tunnel doesn't route, and flags an
  owned path the app also serves. Its report gains `warnings` and `next`:
  the exact flags (or `tunnel_start` fields) that fix what it found.
- `skram-tunnel logs [traefik|provider] [--tail N]` and the MCP `tunnel_logs`
  tool print the running stack's logs. `status` also reports the state
  directory and container names.
- MCP `tunnel_start` takes every `start` flag as a field, and its report
  (and `start --json`) gains `share_url`, `routing` and `config`: a
  paste-ready config snippet that reproduces the start.
- `tunnel_start` and `tunnel_status` gain `qr`, the share link as a
  scannable text QR code, and `warnings`, which say when the binary was
  replaced after the MCP server started so you know to reconnect it.
- `--help`, the MCP instructions and the install-rules section describe the
  debug loop and when a link is ready to hand over. The README gains a
  walkthrough for a login that spans several hosts.
- Fixed: an upstream on a hosts-file alias for 127.0.0.1 (e.g.
  `app.localhost`) is reachable through the tunnel, and `start` refuses a
  host that doesn't resolve instead of coming up broken.
- Fixed: Traefik picks up every config rewrite, and no longer logs a
  spurious error at startup.
- Fixed: `verify` gets past ngrok's free-tier browser-warning page, and
  trusts a self-signed local app the way the tunnel itself does.
- Fixed: the MCP server now picks up config edits made after it started.

## [0.3.1] — 2026-09-23

- Fixed: `agent install-rules` and `doctor` missed a repo's linked worktrees
  (a second checkout of the same clone) — no "Sharing a local app" section,
  no `doctor` warning either. Both now cover every linked worktree of a
  checkout a tunnel target names.

## [0.3.0] — 2026-09-22

- One owner per tunnel: `start` refuses to come up over a tunnel someone else
  started, and names them. `--replace` takes it over, which also revokes their
  shared link. Restarting your own tunnel is never refused, and a tunnel whose
  stack has died never blocks anyone.
- `--json` on `start`, `stop`, `status` and `verify`: exactly one JSON object
  on stdout, progress on stderr, and a non-zero exit on a refusal, a failed
  start or a failed verify. `status --json` now puts its fields at the top
  level instead of under `session`.
- `skram-tunnel mcp`: an MCP server on stdio with `tunnel_start`,
  `tunnel_status`, `tunnel_verify` and `tunnel_stop`, returning the same
  reports as `--json`. Register it with
  `claude mcp add --scope user skram-tunnel -- skram-tunnel mcp`; `doctor`
  checks the registration.
- `skram-tunnel agent install-rules` writes a "Sharing a local app" section
  into each checkout a target names (`repos:`), in machine-local files only.
- `SKRAM_TUNNEL_PROJECT` names the compose project (default `skram-tunnel`),
  so a second, isolated tunnel stack can run beside the default one.
- Fixed: `verify` on a Keycloak tunnel now finds the realm's discovery and
  login page instead of reporting 404s.
- Fixed: a tunnel on `--public-url` could come up serving 404 for every
  request when Traefik missed its first config write.

## [0.2.1] — 2026-09-21

- `skram-tunnel --help` opens with the same sentence as the README: shares a
  local app and the identity provider in front of it on one public URL, so a
  reviewer on a phone can get past the login page. The usage guide follows it,
  unchanged.

## [0.2.0] — 2026-09-21

First public release.

- `skram-tunnel`, a single binary for macOS and Linux (amd64 and arm64): shares
  a local app and the identity provider in front of it on one public URL, so a
  reviewer on a phone can get past the login page. A rewriting proxy collapses
  the app, its identity provider and its APIs onto that one origin. Needs
  Docker.
- The URL is gated by an access code that is new on every start, so restarting
  is what revokes a shared link. `skram-tunnel verify` walks the login through
  the tunnel and reports every hop before you hand the link over.
- Pick the transport with `--provider`: `ngrok` (the default), `cloudflared`
  (a Quick Tunnel needs no account), `tailscale` (Funnel) or `tailscale:serve`
  (tailnet only), or `--public-url` for an origin you already route to your
  machine. Set a default in `tunnel.provider`, or per target.
- Identity provider profile: Zitadel (`--oidc zitadel --idp <local url>`).
- `--native` for a stack already built for its public hostname: route only,
  rewrite nothing.
- `install.sh` downloads the latest release for your machine, verifies it
  against `checksums.txt`, and installs to `~/.local/bin` (`VERSION`,
  `BIN_DIR`). No GitHub login is needed.
- `THIRD_PARTY_NOTICES.md`, in the repository and in every release archive.
