#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import re
import sys
import unicodedata
import urllib.error
import urllib.parse
import urllib.request
from typing import Any


DEFAULT_TIMEOUT = 20.0
DEFAULT_BACKLOG_LIST = "BackLogs"
DEFAULT_EXECUTION_BOARD_NAME = "Execução"
DEFAULT_PLANKA_PROJECT_BACKGROUND = "forest"
DEFAULT_LISTS = ["BackLogs", "To Do", "Doing", "Review", "Blocked", "Done"]


def load_dotenv(dotenv_path: str, *, override: bool = True) -> None:
    if not os.path.isfile(dotenv_path):
        return

    with open(dotenv_path, "r", encoding="utf-8") as handle:
        for raw_line in handle:
            line = raw_line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            key = key.strip()
            value = value.strip().strip('"').strip("'")
            if override or key not in os.environ:
                os.environ[key] = value


DOTENV_PATH = os.path.join(os.path.dirname(__file__), ".env")
load_dotenv(DOTENV_PATH, override=True)
DEFAULT_TIMEOUT = float(os.getenv("MAP_TIMEOUT_SECONDS", "20"))
DEFAULT_BACKLOG_LIST = os.getenv("PLANKA_MAP_DEFAULT_INBOX_LIST", "BackLogs")
DEFAULT_EXECUTION_BOARD_NAME = os.getenv("PLANKA_IMPORT_BOARD_NAME", "Execução")
DEFAULT_PLANKA_PROJECT_BACKGROUND = os.getenv("PLANKA_IMPORT_CONTAINER_BACKGROUND", "forest")

def env_bool(name: str, default: bool = False) -> bool:
    value = str(os.getenv(name, "1" if default else "0")).strip().lower()
    return value in {"1", "true", "yes", "on"}


def slugify(value: str) -> str:
    normalized = []
    for char in str(value or "").strip().lower():
        if char.isalnum():
            normalized.append(char)
        elif char in {" ", "-", "_", "/", ":", "."}:
            normalized.append("-")
    slug = "".join(normalized)
    while "--" in slug:
        slug = slug.replace("--", "-")
    return slug.strip("-") or "item"


def normalize_text(value: str | None) -> str:
    raw = str(value or "").strip().lower()
    normalized = unicodedata.normalize("NFKD", raw)
    return normalized.encode("ascii", "ignore").decode("ascii")


def parse_csv(value: str | None) -> list[str]:
    if not value:
        return []
    return [item.strip() for item in str(value).split(",") if item.strip()]


def deep_get(payload: Any, *keys: str) -> Any:
    current = payload
    for key in keys:
        if not isinstance(current, dict):
            return None
        current = current.get(key)
    return current


def extract_items(payload: Any, preferred_keys: list[str] | None = None) -> list[dict[str, Any]]:
    if isinstance(payload, list):
        return [item for item in payload if isinstance(item, dict)]
    if isinstance(payload, dict):
        keys = preferred_keys or ["items", "data", "projects", "tasks", "included", "cards"]
        for key in keys:
            value = payload.get(key)
            if isinstance(value, list):
                return [item for item in value if isinstance(item, dict)]
        if all(isinstance(v, dict) for v in payload.values()):
            return [v for v in payload.values() if isinstance(v, dict)]
    return []


def first_non_empty(*values: Any) -> str:
    for value in values:
        if value is None:
            continue
        text = str(value).strip()
        if text:
            return text
    return ""


class HttpJsonClient:
    def __init__(self, base_url: str, *, timeout: float = DEFAULT_TIMEOUT, user_agent: str = "marks-map-planka-importer/1"):
        self.base_url = base_url.rstrip("/")
        self.timeout = timeout
        self.user_agent = user_agent

    def _request(self, method: str, path: str, *, headers: dict[str, str] | None = None, payload: Any = None) -> Any:
        url = f"{self.base_url}{path}"
        merged_headers = {
            "Accept": "application/json",
            "User-Agent": self.user_agent,
        }
        if payload is not None:
            merged_headers["Content-Type"] = "application/json"
        if headers:
            merged_headers.update(headers)
        body = None
        if payload is not None:
            body = json.dumps(payload).encode("utf-8")
        request = urllib.request.Request(url, data=body, headers=merged_headers, method=method)
        try:
            with urllib.request.urlopen(request, timeout=self.timeout) as response:
                raw_bytes = response.read()
                raw = raw_bytes.decode("utf-8", errors="replace")
                content_type = str(response.headers.get("Content-Type", "")).lower()
                if not raw:
                    return {}
                stripped = raw.lstrip()
                if stripped.startswith("<"):
                    preview = stripped[:200].replace("\n", " ").strip()
                    raise RuntimeError(f"Resposta não-JSON em {url}: conteúdo HTML/XML inesperado ({preview})")
                try:
                    return json.loads(raw)
                except json.JSONDecodeError as exc:
                    preview = stripped[:200].replace("\n", " ").strip()
                    raise RuntimeError(
                        f"Resposta JSON inválida em {url}: {exc.msg}"
                        f" (content-type={content_type or 'desconhecido'}, preview={preview!r})"
                    ) from exc
        except urllib.error.HTTPError as exc:
            content = exc.read().decode("utf-8", errors="replace")
            raise RuntimeError(f"HTTP {exc.code} em {url}: {content}") from exc
        except urllib.error.URLError as exc:
            raise RuntimeError(f"Falha de conexão com {url}: {exc}") from exc


class MapClient(HttpJsonClient):
    def __init__(self, base_url: str, *, timeout: float = DEFAULT_TIMEOUT):
        super().__init__(base_url, timeout=timeout, user_agent="marks-map-reader/1")
        self.session_cookie = str(os.getenv("MAP_SESSION_COOKIE", "")).strip()
        self.api_key = str(os.getenv("MAP_API_KEY", "")).strip()
        self.auth_bearer = str(os.getenv("MAP_AUTH_BEARER", self.api_key)).strip()

    def _headers(self) -> dict[str, str]:
        headers: dict[str, str] = {}
        if self.session_cookie:
            headers["Cookie"] = self.session_cookie
        if self.api_key:
            headers["X-API-Key"] = self.api_key
        if self.auth_bearer:
            headers["Authorization"] = f"Bearer {self.auth_bearer}"
        return headers

    def get(self, path: str) -> Any:
        return self._request("GET", path, headers=self._headers())

    def post(self, path: str, payload: dict[str, Any]) -> Any:
        return self._request("POST", path, headers=self._headers(), payload=payload)

    def list_projects(self) -> list[dict[str, Any]]:
        endpoint = os.getenv("MAP_PROJECTS_ENDPOINT", "/api/map/v1/projects")
        payload = self.get(endpoint)
        return extract_items(payload, ["items", "projects", "data"])

    def get_project_bundle(self, project_slug: str) -> dict[str, Any]:
        export_endpoint_template = os.getenv("MAP_PROJECT_EXPORT_ENDPOINT_TEMPLATE", "/api/map/v1/export/projects/{project_slug}")
        endpoint = export_endpoint_template.format(project_slug=urllib.parse.quote(project_slug, safe=""))
        payload = self.get(endpoint)
        if isinstance(payload, dict):
            return payload
        raise RuntimeError(f"Bundle de export inválido para o projeto {project_slug}: resposta não é objeto JSON")

    def list_tasks(self, project_slug: str) -> list[dict[str, Any]]:
        payload = self.get_project_bundle(project_slug)
        return extract_items(payload.get("tasks"), ["items", "tasks", "data"])


class PlankaClient(HttpJsonClient):
    def __init__(self, base_url: str, *, timeout: float = DEFAULT_TIMEOUT):
        super().__init__(base_url, timeout=timeout, user_agent="marks-planka-writer/1")
        self.email_or_username = str(os.getenv("PLANKA_EMAIL", os.getenv("PLANKA_USERNAME", ""))).strip()
        self.password = str(os.getenv("PLANKA_PASSWORD", "")).strip()
        self.token = str(os.getenv("PLANKA_TOKEN", "")).strip()

    def authenticate(self) -> None:
        if self.token:
            return
        if not self.email_or_username or not self.password:
            raise RuntimeError("Credenciais do Planka ausentes: defina PLANKA_TOKEN ou PLANKA_EMAIL/PLANKA_PASSWORD")
        payload = {
            "emailOrUsername": self.email_or_username,
            "password": self.password,
        }
        result = self._request("POST", "/api/access-tokens", payload=payload)
        token = ""
        if isinstance(result, dict):
            item = result.get("item")
            if isinstance(item, str):
                token = first_non_empty(item, result.get("token"))
            elif isinstance(item, dict):
                token = first_non_empty(item.get("token"), result.get("token"))
        if not token:
            raise RuntimeError("Falha ao autenticar no Planka: token não retornado")
        self.token = token

    def _auth_headers(self) -> dict[str, str]:
        self.authenticate()
        return {"Authorization": f"Bearer {self.token}"}

    def get(self, path: str) -> Any:
        return self._request("GET", path, headers=self._auth_headers())

    def post(self, path: str, payload: dict[str, Any]) -> Any:
        return self._request("POST", path, headers=self._auth_headers(), payload=payload)

    def patch(self, path: str, payload: dict[str, Any]) -> Any:
        return self._request("PATCH", path, headers=self._auth_headers(), payload=payload)

    def list_projects(self) -> list[dict[str, Any]]:
        payload = self.get("/api/projects")
        return extract_items(payload, ["items", "data", "projects"])

    def list_boards(self, project_id: int) -> list[dict[str, Any]]:
        payload = self.get("/api/projects")
        boards: list[dict[str, Any]] = []
        included = payload.get("included") if isinstance(payload, dict) else None
        if isinstance(included, dict):
            included_boards = included.get("boards")
            if isinstance(included_boards, list):
                return [board for board in included_boards if isinstance(board, dict) and str(board.get("projectId")) == str(project_id)]

        projects = extract_items(payload, ["items", "data", "projects"])
        for item in projects:
            item_project_id = first_non_empty(item.get("projectId"), item.get("id"))
            if str(item_project_id) != str(project_id):
                continue
            nested_boards = item.get("boards")
            if isinstance(nested_boards, list):
                return [board for board in nested_boards if isinstance(board, dict)]
        return boards

    def list_lists(self, board_id: int) -> list[dict[str, Any]]:
        payload = self.get(f"/api/boards/{board_id}")
        return self._board_included_items(payload, "lists")

    def list_labels(self, board_id: int) -> list[dict[str, Any]]:
        payload = self.get(f"/api/boards/{board_id}")
        return self._board_included_items(payload, "labels")

    def list_cards(self, board_id: int) -> list[dict[str, Any]]:
        payload = self.get(f"/api/boards/{board_id}")
        return self._board_included_items(payload, "cards")

    def list_card_labels(self, board_id: int) -> list[dict[str, Any]]:
        payload = self.get(f"/api/boards/{board_id}")
        return self._board_included_items(payload, "cardLabels")

    def _board_included_items(self, payload: Any, collection: str) -> list[dict[str, Any]]:
        included = payload.get("included") if isinstance(payload, dict) else None
        if isinstance(included, dict):
            items = included.get(collection)
            if isinstance(items, list):
                return [item for item in items if isinstance(item, dict)]
        return []

    def create_project(self, name: str, background: str) -> dict[str, Any]:
        payload = self.post("/api/projects", {"type": "private", "name": name, "background": background})
        return deep_get(payload, "item") or payload

    def create_board(self, project_id: int, name: str, position: int = 65535) -> dict[str, Any]:
        payload = self.post(f"/api/projects/{project_id}/boards", {"name": name, "position": position})
        return deep_get(payload, "item") or payload

    def create_list(self, board_id: int, name: str, position: int) -> dict[str, Any]:
        payload = self.post(f"/api/boards/{board_id}/lists", {"type": "active", "name": name, "position": position})
        return deep_get(payload, "item") or payload

    def create_label(self, board_id: int, name: str, color: str, position: int) -> dict[str, Any]:
        payload = self.post(f"/api/boards/{board_id}/labels", {"name": name, "color": color, "position": position})
        return deep_get(payload, "item") or payload

    def create_card(self, list_id: int, name: str, description: str, position: int) -> dict[str, Any]:
        payload = self.post(
            f"/api/lists/{list_id}/cards",
            {"type": "story", "name": name, "description": description, "position": position},
        )
        return deep_get(payload, "item") or payload

    def attach_label_to_card(self, card_id: int, label_id: int) -> Any:
        return self.post(f"/api/cards/{card_id}/card-labels", {"labelId": label_id})


def project_name_from_map(project: dict[str, Any]) -> str:
    return first_non_empty(project.get("name"), project.get("title"), project.get("slug"), "Map Project")


def project_slug_from_map(project: dict[str, Any]) -> str:
    return first_non_empty(project.get("slug"), slugify(project_name_from_map(project)))


def task_id_from_map(task: dict[str, Any]) -> str:
    return first_non_empty(task.get("id"), task.get("taskId"), task.get("uuid"), task.get("slug"))


def task_stable_key_from_map(task: dict[str, Any], *, project_slug: str, module_slug: str) -> str:
    direct_id = task_id_from_map(task)
    if direct_id:
        return f"task-id:{direct_id}"
    title_slug = slugify(task_title_from_map(task))
    return f"fallback:{project_slug}:{module_slug}:{title_slug}"


def task_title_from_map(task: dict[str, Any]) -> str:
    return first_non_empty(task.get("title"), task.get("name"), f"Task {task_id_from_map(task) or 'sem-id'}")


def task_module_from_map(task: dict[str, Any], modules_by_id: dict[str, dict[str, Any]] | None = None) -> tuple[str, str]:
    modules_by_id = modules_by_id or {}
    module_ref = first_non_empty(task.get("module_id"), task.get("moduleId"), deep_get(task, "module", "id"))
    module_payload = modules_by_id.get(str(module_ref)) if module_ref else None
    module_slug = first_non_empty(task.get("module_slug"), deep_get(task, "module", "slug"), task.get("moduleSlug"), deep_get(module_payload, "slug"))
    module_name = first_non_empty(task.get("module_name"), deep_get(task, "module", "name"), task.get("moduleName"), deep_get(module_payload, "name"), module_slug, os.getenv("PLANKA_MAP_DEFAULT_MODULE", "geral"))
    if not module_slug:
        module_slug = slugify(module_name)
    return module_name, module_slug


def build_card_description(task: dict[str, Any], *, project_slug: str, module_slug: str) -> str:
    base_description = first_non_empty(task.get("description"), task.get("notes"), task.get("content"))
    stable_key = task_stable_key_from_map(task, project_slug=project_slug, module_slug=module_slug)
    metadata_lines = [
        "",
        "---",
        f"MapStableKey: {stable_key}",
        f"MapTaskId: {task_id_from_map(task)}",
        f"project_slug: {project_slug}",
        f"module_slug: {module_slug}",
        f"status: {first_non_empty(task.get('status'), 'open')}",
        f"priority: {first_non_empty(task.get('priority'), 'medium')}",
    ]
    return (base_description.rstrip() + "\n" + "\n".join(metadata_lines)).strip()


def match_by_name(items: list[dict[str, Any]], name: str) -> dict[str, Any] | None:
    target = normalize_text(name)
    for item in items:
        candidate = first_non_empty(item.get("name"), item.get("title"))
        if normalize_text(candidate) == target:
            return item
    return None


def match_card_by_map_task_id(cards: list[dict[str, Any]], map_task_id: str) -> dict[str, Any] | None:
    if not map_task_id:
        return None
    pattern = re.compile(rf"MapTaskId:\s*{re.escape(str(map_task_id))}(?:\s|$)", re.IGNORECASE)
    for card in cards:
        description = first_non_empty(card.get("description"), card.get("text"))
        if pattern.search(description):
            return card
    return None


def match_card_by_stable_key(cards: list[dict[str, Any]], stable_key: str) -> dict[str, Any] | None:
    if not stable_key:
        return None
    pattern = re.compile(rf"MapStableKey:\s*{re.escape(str(stable_key))}(?:\s|$)", re.IGNORECASE)
    for card in cards:
        description = first_non_empty(card.get("description"), card.get("text"))
        if pattern.search(description):
            return card
    return None


def ensure_project(client: PlankaClient, name: str, background: str, *, dry_run: bool) -> dict[str, Any]:
    projects = client.list_projects()
    existing = match_by_name(projects, name)
    if existing:
        return {"item": existing, "created": False}
    if dry_run:
        return {"item": {"name": name, "background": background, "id": None}, "created": True, "dry_run": True}
    return {"item": client.create_project(name, background), "created": True}


def ensure_board(client: PlankaClient, project_id: int, board_name: str, *, dry_run: bool) -> dict[str, Any]:
    boards = client.list_boards(project_id)
    existing = match_by_name(boards, board_name)
    if existing:
        return {"item": existing, "created": False}
    if dry_run:
        return {"item": {"name": board_name, "projectId": project_id, "id": None}, "created": True, "dry_run": True}
    return {"item": client.create_board(project_id, board_name), "created": True}


def ensure_lists(client: PlankaClient, board_id: int, required_lists: list[str], *, dry_run: bool) -> dict[str, dict[str, Any]]:
    current_lists = client.list_lists(board_id)
    result: dict[str, dict[str, Any]] = {}
    for index, list_name in enumerate(required_lists, start=1):
        existing = match_by_name(current_lists, list_name)
        if existing:
            result[list_name] = {"item": existing, "created": False}
            continue
        if dry_run:
            result[list_name] = {"item": {"id": None, "name": list_name, "boardId": board_id}, "created": True, "dry_run": True}
            continue
        created = client.create_list(board_id, list_name, index * 65535)
        current_lists.append(created)
        result[list_name] = {"item": created, "created": True}
    return result


LABEL_COLORS = ["berry-red", "pumpkin-orange", "lagoon-blue", "pink-tulip", "light-mud", "orange-peel", "bright-moss", "antique-blue"]


def ensure_label(client: PlankaClient, board_id: int, label_name: str, *, dry_run: bool) -> dict[str, Any]:
    labels = client.list_labels(board_id)
    existing = match_by_name(labels, label_name)
    if existing:
        return {"item": existing, "created": False}
    color = LABEL_COLORS[len(labels) % len(LABEL_COLORS)]
    if dry_run:
        return {"item": {"id": None, "name": label_name, "color": color, "boardId": board_id}, "created": True, "dry_run": True}
    return {"item": client.create_label(board_id, label_name, color, (len(labels) + 1) * 65535), "created": True}


def ensure_card(client: PlankaClient, board_id: int, list_id: int, task: dict[str, Any], description: str, *, dry_run: bool) -> dict[str, Any]:
    cards = client.list_cards(board_id)
    stable_key = task_stable_key_from_map(task, project_slug=_extract_metadata_field(description, "project_slug"), module_slug=_extract_metadata_field(description, "module_slug"))
    existing = match_card_by_stable_key(cards, stable_key)
    if existing:
        return {"item": existing, "created": False, "matched_by": "MapStableKey"}
    existing = match_card_by_map_task_id(cards, task_id_from_map(task))
    if existing:
        return {"item": existing, "created": False, "matched_by": "MapTaskId"}
    if dry_run:
        return {
            "item": {"id": None, "name": task_title_from_map(task), "listId": list_id, "description": description},
            "created": True,
            "dry_run": True,
        }
    return {"item": client.create_card(list_id, task_title_from_map(task), description, 65535), "created": True}


def build_cleanup_plan(report: dict[str, Any]) -> dict[str, Any]:
    cleanup_projects = []
    for project in report.get("projects", []):
        planka_project = project.get("planka_project") or {}
        planka_board = project.get("planka_board") or {}
        if planka_project.get("id") or planka_project.get("name"):
            cleanup_projects.append({
                "project_id": planka_project.get("id"),
                "project_name": planka_project.get("name"),
                "board_id": planka_board.get("id"),
                "board_name": planka_board.get("name"),
                "map_project_slug": project.get("map_project_slug"),
            })
    return {
        "mode": "planned-only",
        "requires_explicit_confirmation": True,
        "strategy": "delete imported projects created/matched by this importer after dry-run review and explicit operator confirmation",
        "targets": cleanup_projects,
    }


def _extract_metadata_field(description: str, field_name: str) -> str:
    pattern = re.compile(rf"^{re.escape(field_name)}:\s*(.+)$", re.IGNORECASE | re.MULTILINE)
    match = pattern.search(str(description or ""))
    return match.group(1).strip() if match else ""


def card_has_label(card_labels: list[dict[str, Any]], card_id: Any, label_id: Any) -> bool:
    for item in card_labels:
        if str(item.get("cardId")) == str(card_id) and str(item.get("labelId")) == str(label_id):
            return True
    return False


def import_project(map_client: MapClient, planka_client: PlankaClient, map_project: dict[str, Any], args: argparse.Namespace, report: dict[str, Any]) -> None:
    map_project_name = project_name_from_map(map_project)
    map_project_slug = project_slug_from_map(map_project)

    project = ensure_project(planka_client, map_project_name, args.planka_project_background, dry_run=args.dry_run)
    project_item = project["item"]
    project_id = project_item.get("id")

    if args.dry_run and project_id is None:
        board = {"item": {"name": args.planka_project_board_name, "projectId": None, "id": None}, "created": True, "dry_run": True}
    else:
        board = ensure_board(planka_client, project_id, args.planka_project_board_name, dry_run=args.dry_run)
    board_item = board["item"]
    board_id = board_item.get("id")

    required_lists = [args.backlog_list]
    if args.create_minimal_lists:
        for list_name in DEFAULT_LISTS:
            if list_name not in required_lists:
                required_lists.append(list_name)
    if args.dry_run and board_id is None:
        lists = {
            list_name: {"item": {"id": None, "name": list_name, "boardId": None}, "created": True, "dry_run": True}
            for list_name in required_lists
        }
    else:
        lists = ensure_lists(planka_client, board_id, required_lists, dry_run=args.dry_run)
    backlog = lists[args.backlog_list]["item"]
    board_card_labels = [] if args.dry_run or board_id is None else planka_client.list_card_labels(board_id)

    project_bundle = map_client.get_project_bundle(map_project_slug)
    tasks = extract_items(project_bundle.get("tasks"), ["items", "tasks", "data"])
    modules = extract_items(project_bundle.get("modules"), ["items", "modules", "data"])
    modules_by_id = {
        str(first_non_empty(module.get("id"), module.get("moduleId"), module.get("slug"))): module
        for module in modules
        if first_non_empty(module.get("id"), module.get("moduleId"), module.get("slug"))
    }
    imported_tasks: list[dict[str, Any]] = []
    for task in tasks:
        map_task_id = task_id_from_map(task)
        module_name, module_slug = task_module_from_map(task, modules_by_id)
        description = build_card_description(task, project_slug=map_project_slug, module_slug=module_slug)
        if args.dry_run and board_id is None:
            label = {"item": {"id": None, "name": module_name, "boardId": None}, "created": True, "dry_run": True}
            card = {
                "item": {"id": None, "name": task_title_from_map(task), "listId": backlog.get("id"), "description": description},
                "created": True,
                "dry_run": True,
            }
        else:
            label = ensure_label(planka_client, board_id, module_name, dry_run=args.dry_run)
            card = ensure_card(planka_client, board_id, backlog.get("id"), task, description, dry_run=args.dry_run)

        card_item = card["item"]
        if not args.dry_run and card_item.get("id") and label["item"].get("id") and not card_has_label(board_card_labels, card_item.get("id"), label["item"].get("id")):
            try:
                planka_client.attach_label_to_card(card_item["id"], label["item"]["id"])
                board_card_labels.append({"cardId": card_item["id"], "labelId": label["item"]["id"]})
            except Exception as exc:  # noqa: BLE001
                imported_tasks.append({
                    "map_task_id": map_task_id,
                    "card_id": card_item.get("id"),
                    "label_id": label["item"].get("id"),
                    "status": "partial",
                    "warning": str(exc),
                })
                continue

        imported_tasks.append({
            "map_task_id": map_task_id,
            "task_title": task_title_from_map(task),
            "module_name": module_name,
            "card_id": card_item.get("id"),
            "label_id": label["item"].get("id"),
            "created": card.get("created", False),
            "label_created": label.get("created", False),
            "idempotency": card.get("matched_by", "created"),
        })

    report.setdefault("projects", []).append({
        "map_project_slug": map_project_slug,
        "map_project_name": map_project_name,
        "planka_project": {
            "id": project_item.get("id"),
            "name": project_item.get("name"),
            "created": project.get("created", False),
        },
        "planka_board": {
            "id": board_item.get("id"),
            "name": board_item.get("name"),
            "created": board.get("created", False),
        },
        "lists": {name: {"id": meta["item"].get("id"), "created": meta.get("created", False)} for name, meta in lists.items()},
        "tasks": imported_tasks,
    })


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Importador pragmático Map -> MarksPlan/Planka")
    parser.add_argument("--map-url", default=os.getenv("MAP_URL", "http://127.0.0.1:20320"), help="Base URL do Map")
    parser.add_argument("--planka-url", default=os.getenv("PLANKA_URL", "http://127.0.0.1:20321"), help="Base URL do Planka")
    parser.add_argument("--planka-project-board-name", default=os.getenv("PLANKA_IMPORT_BOARD_NAME", DEFAULT_EXECUTION_BOARD_NAME), help="Nome fixo do board padrão criado dentro de cada project importado")
    parser.add_argument("--planka-project-background", default=os.getenv("PLANKA_IMPORT_CONTAINER_BACKGROUND", DEFAULT_PLANKA_PROJECT_BACKGROUND), help="Background do project container criado no Planka")
    parser.add_argument("--backlog-list", default=os.getenv("PLANKA_MAP_DEFAULT_INBOX_LIST", DEFAULT_BACKLOG_LIST), help="Nome da lista canônica de entrada")
    parser.add_argument("--project-slugs", help="CSV opcional para importar apenas alguns projetos do Map")
    parser.add_argument("--create-minimal-lists", action="store_true", default=env_bool("PLANKA_IMPORT_CREATE_MINIMAL_LISTS", True), help="Cria listas canônicas mínimas além de BackLogs")
    parser.add_argument("--plan-cleanup", action="store_true", help="Apenas inclui no relatório um plano seguro de limpeza do conteúdo importado; não executa remoções")
    parser.add_argument("--dry-run", action="store_true", help="Não escreve no Planka; apenas simula")
    return parser


def main() -> int:
    bridge_dir = os.path.dirname(os.path.abspath(__file__))
    load_dotenv(os.path.join(bridge_dir, ".env"), override=True)
    parser = build_parser()
    args = parser.parse_args()

    map_client = MapClient(args.map_url)
    planka_client = PlankaClient(args.planka_url)

    try:
        all_projects = map_client.list_projects()
        filter_slugs = set(parse_csv(args.project_slugs))
        selected_projects = [
            project for project in all_projects
            if not filter_slugs or project_slug_from_map(project) in filter_slugs
        ]

        report: dict[str, Any] = {
            "ok": True,
            "dry_run": args.dry_run,
            "map_url": args.map_url,
            "planka_url": args.planka_url,
            "model": {
                "map_project_to_planka_project": True,
                "default_board_name": args.planka_project_board_name,
                "labels_represent_modules": True,
                "tasks_become_cards": True,
                "status_lists": DEFAULT_LISTS,
                "default_entry_list": args.backlog_list,
            },
            "selected_project_count": len(selected_projects),
            "projects": [],
        }

        for project in selected_projects:
            import_project(map_client, planka_client, project, args, report)

        if args.plan_cleanup:
            report["cleanup_plan"] = build_cleanup_plan(report)

    except Exception as exc:  # noqa: BLE001
        print(json.dumps({"ok": False, "error": str(exc)}, ensure_ascii=False, indent=2), file=sys.stderr)
        return 1

    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
