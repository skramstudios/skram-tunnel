# Skram Tunnel

Shares a local app and the identity provider in front of it on one public URL,
so a reviewer on a phone can get past the login page.

Any tunnel can put `localhost:3000` on the internet. Login is what breaks: the
OIDC issuer, the redirect URIs, the cookies and the URLs baked into the app's
bundle all still say `localhost`. `skram-tunnel` puts a rewriting Traefik proxy
between the tunnel and your stack, collapses the app, its IdP and its APIs onto
the one public origin, gates it behind an access code that is new on every
start, and can walk the whole login to prove it works before you share it.

```bash
skram-tunnel 3000                          # share a bare port
skram-tunnel http://localhost:44324 \
    --oidc zitadel --idp http://localhost:48080
skram-tunnel myapp                         # a target named in tunnel.targets
skram-tunnel 3000 --provider cloudflared   # pick the transport
skram-tunnel status
skram-tunnel verify                        # walk the login, report every hop
skram-tunnel stop
skram-tunnel doctor                        # validate config + prerequisites

skram-tunnel 3000 --json                   # one object on stdout: public_url, access_code, owner, ...
skram-tunnel myapp --replace               # take over a tunnel someone else owns
skram-tunnel mcp                           # serve start/status/stop/verify over MCP
skram-tunnel agent install-rules           # write the agent-rules section for each target's repos
```

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/skramstudios/skram-tunnel/main/install.sh | sh
```

Downloads the latest release for your machine (macOS or Linux, amd64 or
arm64), verifies it against `checksums.txt`, and installs to `~/.local/bin`.
`VERSION=v0.2.0` pins a release and `BIN_DIR` changes the directory.

Docker is the one hard prerequisite: Traefik always runs as a container.

## Providers

The transport — what gives the proxy a public origin — is a provider. Pick one
with `--provider`, per target, or once for the machine in `tunnel.provider`.

| Provider | Needs | Hostname | Notes |
| --- | --- | --- | --- |
| `ngrok` (default) | an authtoken (`NGROK_AUTHTOKEN` or `ngrok config add-authtoken`) | random; `domain:` pins a reserved one | the free tier shows visitors an interstitial and has a monthly quota |
| `cloudflared` | nothing | random on every start (Quick Tunnel) | no account, quota or interstitial; the URL is held back until its DNS record is public |
| `cloudflared` + `domain:` | a named tunnel's token (`TUNNEL_TOKEN` or `token_file`) | the domain | in the Cloudflare dashboard, map the hostname to the service `http://traefik:80` |
| `tailscale` | Tailscale running on this machine, Funnel enabled for the tailnet | `<machine>.<tailnet>.ts.net` | public, via Funnel |
| `tailscale:serve` | Tailscale running on this machine | `<machine>.<tailnet>.ts.net` | tailnet only: for reviewers who should not be on a public URL at all |
| `--public-url` | an origin that already routes to this machine's tunnel port | yours | no transport is started: a WireGuard address, a reverse proxy, a tunnel you run by hand |

ngrok and cloudflared run as containers beside Traefik. Tailscale is driven
through the host's own `tailscale` CLI, and only the one port it uses is turned
off again on `stop`; other Serve and Funnel handlers are left alone.

`--native` (the stack is already built for the public origin, so nothing is
rewritten) needs a hostname that survives a restart: a `domain:`, the
`tailscale` provider, or a `--public-url`. A Quick Tunnel is refused, with the
reason.

## Configuration

`skram-tunnel` reads `~/.config/skram/config.yaml` (or the file named by
`--config`), the same file Skram and Skram Vault read, and decodes only its
top-level `tunnel:` key. Every other key, known or not, is ignored.

```yaml
tunnel:
  provider: cloudflared            # default for every target; ngrok if unset

  cloudflared:
    token_file: ~/.config/skram/cloudflared.token   # named tunnels only
  tailscale:
    https_port: 8443               # 443 by default; Funnel allows 443, 8443, 10000
  ngrok:
    api_port: 4040

  targets:
    myapp:
      app: http://localhost:44324
      idp: http://localhost:48080
      oidc: zitadel
      upstreams:
        data: http://localhost:43134
    staging:
      app: "3000"
      provider: tailscale:serve    # overrides tunnel.provider
    pinned:
      app: "3000"
      provider: ngrok
      domain: my-name.ngrok-free.dev
    vpn:
      app: "3000"
      public_url: https://preview.internal.example.com
```

Flags win over the target, the target over `tunnel.provider`. A transport
chosen on the command line replaces the target's whole choice, so
`skram-tunnel vpn --provider cloudflared` drops the configured `public_url`.

Secrets stay out of this file: tokens come from the environment, from the
provider's own config, or from a `token_file`.

`SKRAM_TUNNEL_PROJECT` overrides the compose project name (default
`skram-tunnel`), and every container name with it (`<project>-traefik`,
`<project>-ngrok`, `<project>-cloudflared`), so a second, isolated tunnel
stack can run beside the default one without colliding on containers or
networks.

## For agents

Every command takes `--json`: one object on stdout and nothing else there
(`start`'s progress, compose output and banner move to stderr, and the QR
code is skipped). `status --json` names who owns the running tunnel;
`stop` and `verify` follow the same shape.

There is one tunnel at a time. `start` refuses to take over a tunnel
someone else owns — the refusal names the owner (actor, workspace,
session, target, since when) and exits non-zero. `--replace` is the
explicit takeover: it also revokes that owner's shared link, since the
access code is new on every start. Restarting or reconfiguring your own
tunnel needs no `--replace`.

```bash
skram-tunnel mcp
```

Runs an MCP server on stdio with four tools, built on the same reports as
`--json`: `tunnel_start` (`replace: true` is `--replace`), `tunnel_status`,
`tunnel_stop`, `tunnel_verify`. Its instructions list the configured
targets. Register it once, for every project, at Claude Code's user
scope:

```bash
claude mcp add --scope user skram-tunnel -- skram-tunnel mcp
```

`skram-tunnel doctor` reports whether that registration exists and matches.

### Agent rules for a checkout

A target's `repos:` list names entries in the top-level `repos:` block
(the same block skram and skram-vault read); a checkout of one of those
repos gets that target written into its agent rules.

```yaml
repos:
  my-app:
    remote: my-org/my-app            # owner/name or any git URL
    paths: [~/Dev/my-app]            # checkouts on this machine (~ and globs)

tunnel:
  targets:
    myapp:
      app: http://localhost:44324
      repos: [my-app]
```

```bash
skram-tunnel agent install-rules            # every checkout a target names
skram-tunnel agent install-rules --here     # only the checkout you're standing in
skram-tunnel agent install-rules --repos my-app,other-repo
skram-tunnel agent install-rules --check    # report drift, write nothing, exit 1 on any
```

Writes machine-local files only, never anything you would commit: a
"## Sharing a local app (skram-tunnel)" section in `AGENTS.local.md` (the
start/status/verify/stop loop, the one-owner rule, and a table of that
checkout's targets), the `@AGENTS.local.md` line in `CLAUDE.local.md`, and
both listed in `.git/info/exclude`. `AGENTS.local.md` may already carry a
section written by skram or skram-vault; each tool only ever reads or
replaces its own section, so all three can run in either order.

## When you do not need this

If every reviewer device can already resolve and reach the stack's real
hostnames — a full VPN with DNS, say — nothing needs rewriting and a plain
tunnel or no tunnel will do. The tool earns its place when the stack believes
it is `localhost` and the reviewer reaches it by another name.

## Relationship to Skram

Extracted from `skram tunnel` so the tunnel has its own release train and
semver. The two share a file contract and no code: `skram-tunnel` and `skram
dashboard` each write `~/.local/share/skram/dashboard-state.json` and stop the
other on start.
