#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/build/Build/Products/Debug/ClipStack.app"
BIN="$APP/Contents/MacOS/ClipStack"
LOG="/tmp/clipstack-dev.log"

echo "==> Building ClipStack..."
cd "$ROOT"
xcodebuild -scheme ClipStack -configuration Debug -derivedDataPath build build | tail -5

echo "==> Stopping previous instance..."
pkill -x ClipStack 2>/dev/null || true
sleep 0.3

echo "==> Starting ClipStack (logs -> $LOG)"
: > "$LOG"
"$BIN" >>"$LOG" 2>&1 &
PID=$!
echo "PID: $PID"

sleep 1
if ! kill -0 "$PID" 2>/dev/null; then
  echo "!! Process exited early. Last logs:"
  tail -50 "$LOG"
  exit 1
fi

echo "==> Streaming logs (Ctrl+C to stop tail, app keeps running)"
echo "    Tip: filter with   grep ClipStack $LOG"
tail -f "$LOG"
