#!/usr/bin/env bash
#
# dev-preview.sh — start/stop/check a project's dev server as a detached
# background process on a free port, without holding open a terminal.
#
# Usage:
#   dev-preview.sh start [--port N]
#   dev-preview.sh restart [--port N]
#   dev-preview.sh stop
#   dev-preview.sh status

set -euo pipefail

ACTION="${1:-}"
shift || true

PORT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --port)
      PORT="${2:-}"
      shift 2
      ;;
    *)
      echo "dev-preview.sh: unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

if [[ "$ACTION" != "start" && "$ACTION" != "stop" && "$ACTION" != "status" && "$ACTION" != "restart" ]]; then
  echo "dev-preview.sh: usage: dev-preview.sh {start [--port N]|restart [--port N]|stop|status}" >&2
  exit 2
fi

if [[ -n "$PORT" && ! "$PORT" =~ ^[0-9]+$ ]]; then
  echo "dev-preview.sh: --port must be a plain number, got '$PORT'" >&2
  exit 2
fi

# ---- guards ------------------------------------------------------------------

if [[ ! -f package.json ]]; then
  echo "dev-preview.sh: no package.json in $(pwd) — this only works in npm/pnpm/yarn projects." >&2
  exit 1
fi

if ! grep -q '"dev"[[:space:]]*:' package.json; then
  echo "dev-preview.sh: package.json has no \"dev\" script. Nothing to start." >&2
  exit 1
fi

for cmd in lsof shasum; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "dev-preview.sh: '$cmd' not found on PATH." >&2; exit 1; }
done

# ---- identify this project instance -------------------------------------------

ABS_DIR="$(pwd -P)"
HASH="$(printf '%s' "$ABS_DIR" | shasum -a 256 | cut -c1-12)"
STATE_DIR="${TMPDIR:-/tmp}/dev-preview/$HASH"
mkdir -p "$STATE_DIR"
PIDFILE="$STATE_DIR/pid"
PORTFILE="$STATE_DIR/port"
LOGFILE="$STATE_DIR/log"

is_running() {
  [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null
}

do_stop() {
  if is_running; then
    local pid
    pid="$(cat "$PIDFILE")"
    kill "$pid" 2>/dev/null || true
    rm -f "$PIDFILE" "$PORTFILE"
    echo "stopped pid $pid for $ABS_DIR"
  else
    echo "not running for $ABS_DIR — nothing to stop"
    rm -f "$PIDFILE" "$PORTFILE"
  fi
}

do_status() {
  if is_running; then
    echo "running: http://localhost:$(cat "$PORTFILE") (pid $(cat "$PIDFILE"), dir $ABS_DIR)"
  else
    echo "not running for $ABS_DIR"
  fi
}

do_start() {
  if is_running; then
    echo "already running: http://localhost:$(cat "$PORTFILE") (pid $(cat "$PIDFILE"))"
    return 0
  fi

  local pm="npm"
  if [[ -f pnpm-lock.yaml ]]; then
    pm="pnpm"
  elif [[ -f yarn.lock ]]; then
    pm="yarn"
  fi
  command -v "$pm" >/dev/null 2>&1 || { echo "dev-preview.sh: $pm not found on PATH." >&2; exit 1; }

  local start_port="${PORT:-3000}"
  local port_to_use=""
  local p
  for ((p = start_port; p < start_port + 200; p++)); do
    if ! lsof -i ":$p" -sTCP:LISTEN >/dev/null 2>&1; then
      port_to_use="$p"
      break
    fi
  done
  if [[ -z "$port_to_use" ]]; then
    echo "dev-preview.sh: no free port found in range $start_port-$((start_port + 199))." >&2
    exit 1
  fi

  echo "==> starting $pm run dev on port $port_to_use ($ABS_DIR)"
  PORT="$port_to_use" nohup "$pm" run dev >"$LOGFILE" 2>&1 &
  local new_pid=$!
  disown

  echo "$new_pid" > "$PIDFILE"
  echo "$port_to_use" > "$PORTFILE"

  sleep 2
  if ! kill -0 "$new_pid" 2>/dev/null; then
    echo "dev-preview.sh: process exited immediately — last lines of $LOGFILE:" >&2
    tail -n 20 "$LOGFILE" >&2 || true
    rm -f "$PIDFILE" "$PORTFILE"
    exit 1
  fi

  echo
  echo "Preview: http://localhost:$port_to_use"
  echo "Logs:    $LOGFILE"
  echo "Stop:    dev-preview.sh stop   (run from $ABS_DIR)"
}

case "$ACTION" in
  start)
    do_start
    ;;
  stop)
    do_stop
    ;;
  status)
    do_status
    ;;
  restart)
    do_stop
    do_start
    ;;
esac
