# Changelog

What changed in each skram-tunnel release, for someone running the binary.
Versions follow semver.

## [Unreleased]

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
