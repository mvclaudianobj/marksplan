#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="$BASE_DIR/planka_map_receiver.pid"
LOG_FILE="$BASE_DIR/planka_map_receiver.log"
PYTHON_BIN="${PYTHON_BIN:-python3}"

is_running() {
  if [[ -f "$PID_FILE" ]]; then
    local pid
    pid="$(<"$PID_FILE")"
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
      return 0
    fi
  fi
  return 1
}

start() {
  if is_running; then
    echo "receiver já está em execução (pid $(<"$PID_FILE"))"
    return 0
  fi

  mkdir -p "$BASE_DIR"
  nohup "$PYTHON_BIN" "$BASE_DIR/planka_map_receiver.py" >> "$LOG_FILE" 2>&1 &
  echo $! > "$PID_FILE"
  sleep 1

  if is_running; then
    echo "receiver iniciado com sucesso (pid $(<"$PID_FILE"))"
    echo "log: $LOG_FILE"
    return 0
  fi

  echo "falha ao iniciar receiver; verifique $LOG_FILE" >&2
  return 1
}

stop() {
  if ! is_running; then
    echo "receiver não está em execução"
    rm -f "$PID_FILE"
    return 0
  fi

  local pid
  pid="$(<"$PID_FILE")"
  kill "$pid" 2>/dev/null || true
  sleep 1

  if kill -0 "$pid" 2>/dev/null; then
    echo "processo ainda ativo; enviando SIGKILL para $pid"
    kill -9 "$pid" 2>/dev/null || true
  fi

  rm -f "$PID_FILE"
  echo "receiver parado"
}

status() {
  if is_running; then
    echo "receiver em execução (pid $(<"$PID_FILE"))"
  else
    echo "receiver parado"
  fi
}

health() {
  "$PYTHON_BIN" - <<'PY'
import json
import os
import urllib.request

host = os.getenv("PLANKA_MAP_RECEIVER_HOST", "127.0.0.1")
port = os.getenv("PLANKA_MAP_RECEIVER_PORT", "8941")
url = f"http://{host}:{port}/health"
with urllib.request.urlopen(url, timeout=5) as response:
    print(json.dumps(json.loads(response.read().decode("utf-8")), ensure_ascii=False, indent=2))
PY
}

logs() {
  if [[ -f "$LOG_FILE" ]]; then
    python3 - <<PY
from pathlib import Path
log = Path(r"$LOG_FILE")
lines = log.read_text(encoding="utf-8", errors="replace").splitlines()
for line in lines[-50:]:
    print(line)
PY
  else
    echo "log ainda não existe: $LOG_FILE"
  fi
}

case "${1:-status}" in
  start) start ;;
  stop) stop ;;
  restart) stop; start ;;
  status) status ;;
  health) health ;;
  logs) logs ;;
  *)
    echo "uso: $0 {start|stop|restart|status|health|logs}" >&2
    exit 1
    ;;
esac
