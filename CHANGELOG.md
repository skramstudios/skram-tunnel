# Changelog

What changed in each skram-tunnel release, for someone running the binary.
Versions follow semver.

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
