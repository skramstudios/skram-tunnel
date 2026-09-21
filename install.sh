#!/bin/sh
# Install skram-tunnel from its GitHub releases.
#
#   curl -fsSL https://raw.githubusercontent.com/skramstudios/skram-tunnel/main/install.sh | sh
#
# Env:
#   VERSION=v0.2.1          a specific release (default: the latest)
#   BIN_DIR=~/.local/bin    where the binary goes
#   BASE_URL=…              download root (default: the GitHub releases of skramstudios/skram-tunnel)
set -eu

tool=skram-tunnel
repo=skramstudios/skram-tunnel
bin_dir=${BIN_DIR:-$HOME/.local/bin}

die() { echo "install: $*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "$1 is required"; }
need curl; need tar; need uname

case "$(uname -s)" in
    Darwin) os=darwin ;;
    Linux)  os=linux ;;
    *)      die "unsupported OS: $(uname -s) (releases cover macOS and Linux)" ;;
esac
case "$(uname -m)" in
    arm64|aarch64) arch=arm64 ;;
    x86_64|amd64)  arch=amd64 ;;
    *)             die "unsupported architecture: $(uname -m)" ;;
esac

version=${VERSION:-}
if [ -z "$version" ]; then
    # The "latest" redirect names the tag without an API call or a token.
    version=$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/$repo/releases/latest" | sed 's|.*/tag/||')
    case "$version" in v[0-9]*) ;; *) die "could not find the latest release of $repo" ;; esac
fi

base=${BASE_URL:-https://github.com/$repo/releases/download/$version}
archive="${tool}_${version#v}_${os}_${arch}.tar.gz"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

echo "install: $tool $version ($os/$arch)"
curl -fsSL -o "$tmp/$archive" "$base/$archive" || die "download failed: $base/$archive"
curl -fsSL -o "$tmp/checksums.txt" "$base/checksums.txt" || die "download failed: $base/checksums.txt"

want=$(awk -v f="$archive" '$2 == f { print $1 }' "$tmp/checksums.txt")
[ -n "$want" ] || die "checksums.txt does not list $archive"
if command -v sha256sum >/dev/null 2>&1; then got=$(sha256sum "$tmp/$archive" | awk '{ print $1 }')
elif command -v shasum >/dev/null 2>&1; then got=$(shasum -a 256 "$tmp/$archive" | awk '{ print $1 }')
else die "sha256sum or shasum is required"; fi
[ "$want" = "$got" ] || die "checksum mismatch for $archive (want $want, got $got)"

tar -xzf "$tmp/$archive" -C "$tmp" "$tool"
mkdir -p "$bin_dir"
mv "$tmp/$tool" "$bin_dir/$tool"
chmod +x "$bin_dir/$tool"

echo "install: $bin_dir/$tool"
"$bin_dir/$tool" version || true
case ":$PATH:" in *":$bin_dir:"*) ;; *) echo "install: add $bin_dir to your PATH" ;; esac
echo "install: next, share a local port:  $tool 3000 --provider cloudflared"
