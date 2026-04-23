#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$BASE_DIR/.env"
ENV_EXAMPLE_FILE="$BASE_DIR/.env.example"
COMPOSE_FILE="$BASE_DIR/docker-compose.yml"
COMPOSE_MARKS3_FILE="$BASE_DIR/docker-compose.marks3.yml"
DEFAULT_PORT="20321"
DEFAULT_BASE_URL="http://127.0.0.1:${DEFAULT_PORT}"
HEALTH_PATH="/api/health"

compose() {
  docker compose -f "$COMPOSE_MARKS3_FILE" "$@"
}

load_env() {
  if [[ -f "$ENV_FILE" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "$ENV_FILE"
    set +a
  fi

  export PLANKA_HOST_PORT="${PLANKA_HOST_PORT:-$DEFAULT_PORT}"
  export BASE_URL="${BASE_URL:-$DEFAULT_BASE_URL}"
  export SECRET_KEY="${SECRET_KEY:-change-this-secret-key}"
  export DATABASE_URL="${DATABASE_URL:-postgresql://postgres@postgres/planka}"
  export POSTGRES_DB="${POSTGRES_DB:-planka}"
  export POSTGRES_HOST_AUTH_METHOD="${POSTGRES_HOST_AUTH_METHOD:-trust}"
}

ensure_requirements() {
  if ! command -v docker >/dev/null 2>&1; then
    echo "docker não encontrado no PATH." >&2
    exit 1
  fi

  if ! docker compose version >/dev/null 2>&1; then
    echo "docker compose plugin não disponível." >&2
    exit 1
  fi

  if [[ ! -f "$COMPOSE_MARKS3_FILE" ]]; then
    echo "docker-compose.marks3.yml não encontrado em $BASE_DIR." >&2
    exit 1
  fi

  if [[ ! -f "$COMPOSE_FILE" ]]; then
    echo "docker-compose.yml upstream não encontrado em $BASE_DIR." >&2
    exit 1
  fi
}

ensure_env() {
  if [[ ! -f "$ENV_FILE" ]]; then
    if [[ -f "$ENV_EXAMPLE_FILE" ]]; then
      cp "$ENV_EXAMPLE_FILE" "$ENV_FILE"
      echo "Arquivo .env criado a partir de .env.example. Revise SECRET_KEY e BASE_URL antes de publicar."
    else
      echo "Arquivo .env ausente e .env.example não encontrado." >&2
      exit 1
    fi
  fi
}

install() {
  ensure_requirements
  ensure_env
  load_env
  compose config >/dev/null
  echo "Wrapper Planka validado. Use '$0 start' para subir os containers."
}

start() {
  ensure_requirements
  ensure_env
  load_env
  compose up -d
  echo "Planka iniciado via docker compose na porta ${PLANKA_HOST_PORT}."
}

stop() {
  ensure_requirements
  load_env
  compose down
  echo "Planka parado."
}

restart() {
  stop
  start
}

status() {
  ensure_requirements
  load_env
  compose ps
}

logs() {
  ensure_requirements
  load_env
  compose logs -f --tail=200
}

health() {
  load_env
  local url="${BASE_URL%/}${HEALTH_PATH}"
  echo "Verificando saúde em: $url"
  curl --fail --silent --show-error "$url"
  echo
}

run_fg() {
  ensure_requirements
  ensure_env
  load_env
  compose up
}

usage() {
  echo "Uso: $0 {install|start|stop|restart|status|logs|health|run}"
}

case "${1:-}" in
  install) install ;;
  start) start ;;
  stop) stop ;;
  restart) restart ;;
  status) status ;;
  logs) logs ;;
  health) health ;;
  run) run_fg ;;
  *)
    usage
    exit 1
    ;;
esac
