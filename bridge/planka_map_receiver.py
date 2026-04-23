#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import subprocess
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path


BRIDGE_SCRIPT = Path(__file__).with_name("planka_map_bridge.py")
ENV_FILE = Path(__file__).with_name(".env")
DEFAULT_HOST = "127.0.0.1"
DEFAULT_PORT = 8941
DEFAULT_SECRET_HEADER = "X-Planka-Bridge-Secret"


def load_dotenv(dotenv_path: Path) -> None:
    if not dotenv_path.is_file():
        return

    for raw_line in dotenv_path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        os.environ[key.strip()] = value.strip().strip('"').strip("'")


def current_settings() -> tuple[str, int, str, str]:
    host = os.getenv("PLANKA_MAP_RECEIVER_HOST", DEFAULT_HOST)
    port = int(os.getenv("PLANKA_MAP_RECEIVER_PORT", str(DEFAULT_PORT)))
    secret_header = os.getenv("PLANKA_MAP_RECEIVER_SECRET_HEADER", DEFAULT_SECRET_HEADER)
    secret = os.getenv("PLANKA_MAP_RECEIVER_SECRET", "").strip()
    return host, port, secret_header, secret


class Handler(BaseHTTPRequestHandler):
    def do_GET(self) -> None:  # noqa: N802
        if self.path != "/health":
            self._json_response(404, {"ok": False, "error": "not_found"})
            return

        load_dotenv(ENV_FILE)
        host, port, secret_header, secret = current_settings()
        self._json_response(200, {
            "ok": True,
            "service": "planka-map-receiver",
            "listening": f"http://{host}:{port}/planka/events",
            "health": "pass",
            "auth": {
                "secret_header": secret_header,
                "secret_configured": bool(secret),
            },
        })

    def do_POST(self) -> None:  # noqa: N802
        if self.path != "/planka/events":
            self._json_response(404, {"ok": False, "error": "not_found"})
            return

        load_dotenv(ENV_FILE)
        _, _, secret_header, secret = current_settings()
        if secret:
            provided_secret = str(self.headers.get(secret_header, "")).strip()
            if provided_secret != secret:
                self._json_response(401, {
                    "ok": False,
                    "error": "unauthorized",
                    "detail": f"header {secret_header} inválido ou ausente",
                })
                return

        content_length = int(self.headers.get("Content-Length", "0"))
        raw_body = self.rfile.read(content_length) if content_length > 0 else b"{}"
        try:
            payload = json.loads(raw_body.decode("utf-8"))
        except json.JSONDecodeError:
            self._json_response(400, {"ok": False, "error": "invalid_json"})
            return

        event_name = str(payload.get("event_name") or payload.get("event") or "").strip()
        if not event_name:
            self._json_response(400, {"ok": False, "error": "event_name_required"})
            return

        command = [
            sys.executable,
            str(BRIDGE_SCRIPT),
        ]

        option_map = {
            "host": "--host",
            "actor": "--actor",
        }

        for key, option in option_map.items():
            value = payload.get(key)
            if value is None or value == "":
                continue
            command.extend([option, str(value)])

        command.extend([
            "from-event",
            "--event-name",
            event_name,
        ])

        option_map = {
            "board_name": "--board-name",
            "list_name": "--list-name",
            "card_title": "--card-title",
            "project_slug": "--project-slug",
            "project_name": "--project-name",
            "module_slug": "--module-slug",
            "module_name": "--module-name",
            "module_names": "--module-names",
            "label_names": "--label-names",
            "member_names": "--member-names",
            "title": "--title",
            "description": "--description",
            "status": "--status",
            "priority": "--priority",
            "assignee": "--assignee",
            "task_id": "--task-id",
            "task_status": "--task-status",
            "host_state": "--host-state",
            "host_state_note": "--host-state-note",
            "percent": "--percent",
            "message": "--message",
            "note": "--note",
        }

        for key, option in option_map.items():
            value = payload.get(key)
            if value is None or value == "":
                continue
            command.extend([option, str(value)])

        process = subprocess.run(command, capture_output=True, text=True, check=False)
        if process.returncode != 0:
            self._json_response(502, {
                "ok": False,
                "error": "bridge_execution_failed",
                "stderr": process.stderr.strip(),
                "stdout": process.stdout.strip(),
            })
            return

        try:
            result = json.loads(process.stdout or "{}")
        except json.JSONDecodeError:
            result = {"ok": True, "raw": process.stdout.strip()}
        self._json_response(200, result)

    def log_message(self, format: str, *args) -> None:  # noqa: A003
        return

    def _json_response(self, status: int, payload: dict) -> None:
        body = json.dumps(payload, ensure_ascii=False, indent=2).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


def main() -> int:
    load_dotenv(ENV_FILE)
    host, port, secret_header, secret = current_settings()
    server = HTTPServer((host, port), Handler)
    print(json.dumps({
        "ok": True,
        "listening": f"http://{host}:{port}/planka/events",
        "health": f"http://{host}:{port}/health",
        "secret_header": secret_header,
        "secret_configured": bool(secret),
    }, ensure_ascii=False))
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
