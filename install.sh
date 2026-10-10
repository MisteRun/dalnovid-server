#!/usr/bin/env bash
# Dalnovid Server installer for Ubuntu / Debian (systemd).
#
#   curl -fsSL https://raw.githubusercontent.com/MisteRun/dalnovid-server/main/install.sh \
#     | sudo bash -s -- <relay-address> [version]
#
#   relay-address  host (or host:port) clients use to reach hbbr, e.g. relay.example.com
#   version        release tag, default: latest
#
# Re-running upgrades the binaries and keeps keys and the database.
set -euo pipefail

REPO="MisteRun/dalnovid-server"
PREFIX="/opt/dalnovid-server"
DATA="/var/lib/dalnovid-server"
SVC_USER="dalnovid"

die() { echo "error: $*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || die "run as root (sudo)"
[ $# -ge 1 ] || die "usage: install.sh <relay-address> [version]"
RELAY="$1"
VERSION="${2:-latest}"
case "$RELAY" in *:*) ;; *) RELAY="$RELAY:21117" ;; esac

command -v systemctl >/dev/null || die "systemd is required"
for t in curl tar; do command -v "$t" >/dev/null || { apt-get update -qq && apt-get install -y -qq "$t"; }; done

case "$(uname -m)" in
  x86_64|amd64) ARCH=amd64 ;;
  aarch64|arm64) ARCH=arm64 ;;
  *) die "unsupported architecture: $(uname -m)" ;;
esac

PKG="dalnovid-server-linux-$ARCH"
if [ "$VERSION" = latest ]; then
  URL="https://github.com/$REPO/releases/latest/download/$PKG.tar.gz"
else
  URL="https://github.com/$REPO/releases/download/$VERSION/$PKG.tar.gz"
fi

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
echo "==> Downloading $URL"
curl -fsSL "$URL" -o "$TMP/$PKG.tar.gz" || die "download failed"
tar -xzf "$TMP/$PKG.tar.gz" -C "$TMP"

echo "==> Installing to $PREFIX"
id "$SVC_USER" >/dev/null 2>&1 || useradd --system --home-dir "$DATA" --shell /usr/sbin/nologin "$SVC_USER"
install -d -m 0755 "$PREFIX"
install -d -m 0700 -o "$SVC_USER" -g "$SVC_USER" "$DATA"
systemctl stop dalnovid-hbbs dalnovid-hbbr 2>/dev/null || true
install -m 0755 "$TMP/$PKG/hbbs" "$TMP/$PKG/hbbr" "$PREFIX/"
[ -f "$TMP/$PKG/dalnovid-utils" ] && install -m 0755 "$TMP/$PKG/dalnovid-utils" "$PREFIX/"

unit() { # name description exec
  cat > "/etc/systemd/system/$1.service" <<EOF
[Unit]
Description=$2
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=$3
WorkingDirectory=$DATA
User=$SVC_USER
Group=$SVC_USER
LimitNOFILE=1000000
Restart=always
RestartSec=10
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$DATA
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
}
unit dalnovid-hbbr "Dalnovid relay server (hbbr)" "$PREFIX/hbbr"
unit dalnovid-hbbs "Dalnovid ID server (hbbs)" "$PREFIX/hbbs -r $RELAY"

if command -v ufw >/dev/null && ufw status | grep -q "Status: active"; then
  echo "==> Opening ports in ufw"
  ufw allow 21115:21119/tcp >/dev/null
  ufw allow 21116/udp >/dev/null
fi

systemctl daemon-reload
systemctl enable --now dalnovid-hbbr dalnovid-hbbs

echo "==> Waiting for the server key"
for _ in $(seq 1 30); do [ -s "$DATA/id_ed25519.pub" ] && break; sleep 1; done
[ -s "$DATA/id_ed25519.pub" ] || die "hbbs did not create a key; see: journalctl -u dalnovid-hbbs"

cat <<EOF

Dalnovid Server is running.
  ID server : port 21116 (TCP+UDP), relay: $RELAY
  Data      : $DATA   (back up id_ed25519, keep it private)
  Logs      : journalctl -u dalnovid-hbbs -u dalnovid-hbbr

Public key for clients:
$(cat "$DATA/id_ed25519.pub")

If the VPS provider has its own firewall, open TCP 21115-21119 and UDP 21116 there too.
EOF
