#!/bin/sh
# Doctiling self-host installer (macOS / Linux).
#   curl -fsSL https://raw.githubusercontent.com/doctiling/releases/main/install.sh | sh
# Installs the latest GitHub release + a pinned Node runtime under ~/.doctiling,
# generates every secret the app needs, registers autostart, and opens the app.
set -eu

REPO="doctiling/releases"
NODE_VERSION="20.18.1"
DOCTILING_HOME="${DOCTILING_HOME:-$HOME/.doctiling}"
PORT="${DOCTILING_PORT:-3000}"

say() { printf '\033[1;32m[doctiling]\033[0m %s\n' "$1"; }
fail() { printf '\033[1;31m[doctiling]\033[0m %s\n' "$1" >&2; exit 1; }

command -v curl >/dev/null 2>&1 || fail "curl is required"
command -v tar >/dev/null 2>&1 || fail "tar is required"

OS="$(uname -s)"
ARCH="$(uname -m)"
case "$OS" in
  Darwin) NODE_OS="darwin" ;;
  Linux) NODE_OS="linux" ;;
  *) fail "Unsupported OS: $OS (use install.ps1 on Windows)" ;;
esac
case "$ARCH" in
  arm64|aarch64) NODE_ARCH="arm64" ;;
  x86_64) NODE_ARCH="x64" ;;
  *) fail "Unsupported CPU: $ARCH" ;;
esac

mkdir -p "$DOCTILING_HOME/bin" "$DOCTILING_HOME/data" "$DOCTILING_HOME/logs"

# --- Node runtime (self-contained; the user never installs Node) -------------
NODE_DIR="$DOCTILING_HOME/node-v$NODE_VERSION"
if [ ! -x "$NODE_DIR/bin/node" ]; then
  say "Downloading Node $NODE_VERSION ($NODE_OS-$NODE_ARCH)…"
  NODE_TARBALL="node-v$NODE_VERSION-$NODE_OS-$NODE_ARCH.tar.gz"
  curl -fsSL "https://nodejs.org/dist/v$NODE_VERSION/$NODE_TARBALL" -o "$DOCTILING_HOME/$NODE_TARBALL"
  tar -xzf "$DOCTILING_HOME/$NODE_TARBALL" -C "$DOCTILING_HOME"
  mv "$DOCTILING_HOME/node-v$NODE_VERSION-$NODE_OS-$NODE_ARCH" "$NODE_DIR"
  rm "$DOCTILING_HOME/$NODE_TARBALL"
fi
NODE="$NODE_DIR/bin/node"

# --- App release --------------------------------------------------------------
# DOCTILING_TARBALL=/path/to/doctiling-standalone.tar.gz installs a local
# build (no GitHub, air-gapped OK); otherwise the latest release is fetched.
if [ -n "${DOCTILING_TARBALL:-}" ]; then
  [ -f "$DOCTILING_TARBALL" ] || fail "DOCTILING_TARBALL not found: $DOCTILING_TARBALL"
  TAG="local-$(date +%Y%m%d%H%M%S)"
  APP_DIR="$DOCTILING_HOME/app-$TAG"
  say "Installing local tarball ($TAG)…"
  mkdir -p "$APP_DIR"
  tar -xzf "$DOCTILING_TARBALL" -C "$APP_DIR"
else
  say "Fetching latest release…"
  TAG=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" | grep -m1 '"tag_name"' | cut -d '"' -f4)
  [ -n "$TAG" ] || fail "Could not resolve the latest release tag"
  APP_DIR="$DOCTILING_HOME/app-$TAG"
  if [ ! -d "$APP_DIR" ]; then
    say "Downloading Doctiling $TAG…"
    curl -fsSL "https://github.com/$REPO/releases/download/$TAG/doctiling-standalone.tar.gz" \
      -o "$DOCTILING_HOME/doctiling-standalone.tar.gz"
    mkdir -p "$APP_DIR"
    tar -xzf "$DOCTILING_HOME/doctiling-standalone.tar.gz" -C "$APP_DIR"
    rm "$DOCTILING_HOME/doctiling-standalone.tar.gz"
  fi
fi
ln -sfn "$APP_DIR" "$DOCTILING_HOME/current"

# --- .env: generate every key the app needs ----------------------------------
sh "$DOCTILING_HOME/current/scripts/self-host/setup-env.sh" "$NODE" "$DOCTILING_HOME/current" "$DOCTILING_HOME" "$PORT"

# --- CLI ----------------------------------------------------------------------
cp "$DOCTILING_HOME/current/scripts/self-host/doctiling" "$DOCTILING_HOME/bin/doctiling" 2>/dev/null || true
chmod +x "$DOCTILING_HOME/bin/doctiling" 2>/dev/null || true

# --- Autostart ----------------------------------------------------------------
# DOCTILING_NO_SERVICE=1 skips autostart registration (tests, manual control).
if [ -n "${DOCTILING_NO_SERVICE:-}" ]; then
  say "Skipping service registration (DOCTILING_NO_SERVICE)."
  "$DOCTILING_HOME/bin/doctiling" start
elif [ "$NODE_OS" = "darwin" ]; then
  PLIST="$HOME/Library/LaunchAgents/app.doctiling.plist"
  mkdir -p "$HOME/Library/LaunchAgents"
  cat > "$PLIST" <<PLISTEOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>app.doctiling</string>
  <key>ProgramArguments</key><array>
    <string>$DOCTILING_HOME/bin/doctiling</string><string>run</string>
  </array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>StandardOutPath</key><string>$DOCTILING_HOME/logs/doctiling.log</string>
  <key>StandardErrorPath</key><string>$DOCTILING_HOME/logs/doctiling.log</string>
</dict></plist>
PLISTEOF
  launchctl unload "$PLIST" 2>/dev/null || true
  launchctl load "$PLIST"
  say "Registered launchd service (app.doctiling)."
else
  say "Linux: start with '$DOCTILING_HOME/bin/doctiling start' (systemd unit not installed automatically)."
  "$DOCTILING_HOME/bin/doctiling" start || true
fi

say "Waiting for the app on http://127.0.0.1:$PORT …"
i=0
until curl -fsS -o /dev/null "http://127.0.0.1:$PORT" 2>/dev/null; do
  i=$((i+1)); [ $i -gt 60 ] && fail "The app did not come up; check $DOCTILING_HOME/logs/doctiling.log"
  sleep 1
done

case "${LANG:-}" in es*) APP_LOCALE="es" ;; *) APP_LOCALE="en" ;; esac
APP_URL="http://127.0.0.1:$PORT/$APP_LOCALE/signin"
say "Done. Open $APP_URL — install it as an app from your browser."
say "CLI: $DOCTILING_HOME/bin/doctiling start|stop|status|update|logs (add $DOCTILING_HOME/bin to PATH)."
if [ "$NODE_OS" = "darwin" ]; then open "$APP_URL" 2>/dev/null || true; fi
command -v xdg-open >/dev/null 2>&1 && xdg-open "$APP_URL" 2>/dev/null || true
