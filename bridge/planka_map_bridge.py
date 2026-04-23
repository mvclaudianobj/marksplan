#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import sys
import unicodedata
import urllib.error
import urllib.parse
import urllib.request
from typing import Any


DEFAULT_TIMEOUT = float(os.getenv("MAP_TIMEOUT_SECONDS", "15"))
DEFAULT_BACKLOG_LIST = os.getenv("PLANKA_MAP_DEFAULT_INBOX_LIST", "BackLogs")


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


def env_bool(name: str, default: bool = False) -> bool:
    value = str(os.getenv(name, "1" if default else "0")).strip().lower()
    return value in {"1", "true", "yes", "on"}


def slugify(value: str) -> str:
    normalized = []
    for char in value.strip().lower():
        if char.isalnum():
            normalized.append(char)
        elif char in {" ", "-", "_", "/", ":", "."}:
            normalized.append("-")
    slug = "".join(normalized)
    while "--" in slug:
        slug = slug.replace("--", "-")
    return slug.strip("-") or "item"


def normalize_token(value: str | None) -> str:
    raw = str(value or "").strip().lower()
    if not raw:
        return ""
    normalized = unicodedata.normalize("NFKD", raw)
    ascii_only = normalized.encode("ascii", "ignore").decode("ascii")
    collapsed = []
    for char in ascii_only:
        if char.isalnum():
            collapsed.append(char)
    return "".join(collapsed)


def parse_csv(value: str | None) -> list[str]:
    if not value:
        return []
    return [item.strip() for item in str(value).split(",") if item.strip()]


def parse_key_value_mapping(value: str | None) -> dict[str, str]:
    if not value:
        return {}

    mapping: dict[str, str] = {}
    separators = [";", "\n", ","]
    chunks = [str(value)]
    for separator in separators:
        next_chunks: list[str] = []
        for chunk in chunks:
            next_chunks.extend(chunk.split(separator))
        chunks = next_chunks

    for raw_item in chunks:
        item = raw_item.strip()
        if not item or "=" not in item:
            continue
        key, mapped_value = item.split("=", 1)
        key = key.strip().strip('"').strip("'")
        mapped_value = mapped_value.strip().strip('"').strip("'")
        if key and mapped_value:
            mapping[key] = mapped_value
    return mapping


def load_project_slug_mapping() -> dict[str, str]:
    mapping: dict[str, str] = {}

    raw_json = str(os.getenv("PLANKA_MAP_PROJECT_SLUG_MAP_JSON", "")).strip()
    if raw_json:
        try:
            parsed = json.loads(raw_json)
        except json.JSONDecodeError as exc:
            raise RuntimeError(f"PLANKA_MAP_PROJECT_SLUG_MAP_JSON inválido: {exc}") from exc
        if not isinstance(parsed, dict):
            raise RuntimeError("PLANKA_MAP_PROJECT_SLUG_MAP_JSON deve ser um objeto JSON {board: slug}")
        for key, value in parsed.items():
            normalized_key = str(key).strip()
            normalized_value = str(value).strip()
            if normalized_key and normalized_value:
                mapping[normalized_key] = normalized_value

    raw_pairs = os.getenv("PLANKA_MAP_PROJECT_SLUG_MAP")
    mapping.update(parse_key_value_mapping(raw_pairs))
    return mapping


def load_module_slug_mapping() -> dict[str, str]:
    mapping: dict[str, str] = {}

    raw_json = str(os.getenv("PLANKA_MAP_MODULE_SLUG_MAP_JSON", "")).strip()
    if raw_json:
        try:
            parsed = json.loads(raw_json)
        except json.JSONDecodeError as exc:
            raise RuntimeError(f"PLANKA_MAP_MODULE_SLUG_MAP_JSON inválido: {exc}") from exc
        if not isinstance(parsed, dict):
            raise RuntimeError("PLANKA_MAP_MODULE_SLUG_MAP_JSON deve ser um objeto JSON {label: module_slug}")
        for key, value in parsed.items():
            normalized_key = str(key).strip()
            normalized_value = str(value).strip()
            if normalized_key and normalized_value:
                mapping[normalized_key] = normalized_value

    raw_pairs = os.getenv("PLANKA_MAP_MODULE_SLUG_MAP")
    mapping.update(parse_key_value_mapping(raw_pairs))
    return mapping


def resolve_project_slug(board_name: str | None, explicit_project_slug: str | None = None) -> str:
    if explicit_project_slug:
        return str(explicit_project_slug).strip()

    resolved_board_name = str(board_name or "").strip() or "Planka Board"
    configured_mapping = load_project_slug_mapping()
    board_slug = slugify(resolved_board_name)

    direct_candidates = [
        resolved_board_name,
        resolved_board_name.lower(),
        board_slug,
    ]

    for candidate in direct_candidates:
        mapped = configured_mapping.get(candidate)
        if mapped:
            return mapped

    normalized_mapping = {
        str(key).strip().lower(): str(value).strip()
        for key, value in configured_mapping.items()
        if str(key).strip() and str(value).strip()
    }
    normalized_candidates = [resolved_board_name.lower(), board_slug.lower()]
    for candidate in normalized_candidates:
        mapped = normalized_mapping.get(candidate)
        if mapped:
            return mapped

    return board_slug


def normalize_status(value: str | None, *, list_name: str | None = None, event_name: str | None = None) -> str:
    raw = str(value or "").strip().lower()
    list_raw = str(list_name or "").strip().lower()
    event_raw = str(event_name or "").strip().lower()

    direct_map = {
        "open": "open",
        "todo": "open",
        "to_do": "open",
        "backlog": "open",
        "backlogs": "open",
        "triage": "open",
        "pending": "open",
        "in_progress": "in_progress",
        "in-progress": "in_progress",
        "doing": "in_progress",
        "working": "in_progress",
        "review": "review",
        "qa": "review",
        "validation": "review",
        "blocked": "blocked",
        "pause": "blocked",
        "paused": "blocked",
        "done": "done",
        "completed": "done",
        "complete": "done",
        "closed": "done",
        "archived": "done",
    }

    if raw in direct_map:
        return direct_map[raw]
    if list_raw in direct_map:
        return direct_map[list_raw]
    if event_raw in {"card.completed", "card.archived", "session.end"}:
        return "done"
    if event_raw in {"card.started", "session.start"}:
        return "in_progress"
    if event_raw in {"card.moved", "card.progress", "session.progress"}:
        return direct_map.get(list_raw, "in_progress")
    return direct_map.get(str(os.getenv("PLANKA_MAP_DEFAULT_TASK_STATUS", "open")).strip().lower(), "open")


def normalize_priority(value: str | None) -> str:
    raw = str(value or "").strip().lower()
    mapping = {
        "low": "low",
        "baixa": "low",
        "minor": "low",
        "medium": "medium",
        "media": "medium",
        "normal": "medium",
        "default": "medium",
        "high": "high",
        "alta": "high",
        "urgent": "urgent",
        "critica": "urgent",
        "critical": "urgent",
        "blocker": "urgent",
    }
    return mapping.get(raw, os.getenv("PLANKA_MAP_DEFAULT_TASK_PRIORITY", "medium"))


def normalize_assignee(value: str | None, *, members: list[str] | None = None) -> str:
    if value:
        return str(value).strip()
    if members:
        return ", ".join(member for member in members if member)
    return os.getenv("PLANKA_MAP_DEFAULT_ASSIGNEE", "markscode")


def extract_modules(args: argparse.Namespace) -> tuple[list[str], str, str]:
    label_names = parse_csv(getattr(args, "label_names", None))
    module_names = parse_csv(getattr(args, "module_names", None))
    explicit_module_name = getattr(args, "module_name", None)
    explicit_module_slug = getattr(args, "module_slug", None)

    modules = label_names or module_names
    if explicit_module_name:
        modules.append(str(explicit_module_name).strip())
    modules = [module for module in modules if module]

    if modules:
        primary_module_name = modules[0]
        primary_module_slug = explicit_module_slug or slugify(primary_module_name)
        return modules, primary_module_name, primary_module_slug

    fallback_module_name = explicit_module_name or os.getenv("PLANKA_MAP_DEFAULT_MODULE", "geral")
    fallback_module_slug = explicit_module_slug or slugify(fallback_module_name)
    return [fallback_module_name], fallback_module_name, fallback_module_slug


def collect_bootstrap_modules(payload: Any) -> list[dict[str, str]]:
    modules: list[dict[str, str]] = []

    def visit(node: Any) -> None:
        if isinstance(node, dict):
            slug = str(node.get("slug") or node.get("module_slug") or "").strip()
            name = str(node.get("name") or node.get("module_name") or node.get("title") or "").strip()
            if slug or name:
                modules.append({
                    "slug": slug or slugify(name),
                    "name": name or slug,
                })
            for key in ("modules", "items", "data", "project", "projects", "result"):
                if key in node:
                    visit(node[key])
        elif isinstance(node, list):
            for item in node:
                visit(item)

    visit(payload)

    deduped: list[dict[str, str]] = []
    seen: set[tuple[str, str]] = set()
    for module in modules:
        key = (module["slug"], module["name"])
        if key in seen:
            continue
        seen.add(key)
        deduped.append(module)
    return deduped


def match_module_candidate(candidates: list[str], available_modules: list[dict[str, str]]) -> dict[str, str] | None:
    if not candidates or not available_modules:
        return None

    indexes: dict[str, dict[str, str]] = {}
    for module in available_modules:
        slug = str(module.get("slug") or "").strip()
        name = str(module.get("name") or "").strip()
        possible_keys = {
            slug,
            name,
            slugify(name),
            normalize_token(slug),
            normalize_token(name),
            normalize_token(slugify(name)),
        }
        for key in possible_keys:
            if key:
                indexes[key] = module

    for candidate in candidates:
        keys = [
            str(candidate).strip(),
            slugify(candidate),
            normalize_token(candidate),
            normalize_token(slugify(candidate)),
        ]
        for key in keys:
            module = indexes.get(key)
            if module:
                return module
    return None


class MapClient:
    def __init__(self, base_url: str, *, timeout: float = DEFAULT_TIMEOUT):
        self.base_url = base_url.rstrip("/")
        self.timeout = timeout
        self.session_cookie = str(os.getenv("MAP_SESSION_COOKIE", "")).strip()
        self.api_key = str(os.getenv("MAP_API_KEY", "")).strip()
        self.auth_bearer = str(os.getenv("MAP_AUTH_BEARER", self.api_key)).strip()

    def _headers(self) -> dict[str, str]:
        headers = {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "User-Agent": "marks-planka-map-bridge/phase1",
        }
        if self.session_cookie:
            headers["Cookie"] = self.session_cookie
        if self.api_key:
            headers["X-API-Key"] = self.api_key
        if self.auth_bearer:
            headers["Authorization"] = f"Bearer {self.auth_bearer}"
        return headers

    def post(self, path: str, payload: dict[str, Any], *, dry_run: bool = False) -> dict[str, Any]:
        url = f"{self.base_url}{path}"
        if dry_run:
            return {"dry_run": True, "url": url, "payload": payload}

        body = json.dumps(payload).encode("utf-8")
        request = urllib.request.Request(url, data=body, headers=self._headers(), method="POST")
        try:
            with urllib.request.urlopen(request, timeout=self.timeout) as response:
                raw = response.read().decode("utf-8")
                return json.loads(raw) if raw else {"ok": True}
        except urllib.error.HTTPError as exc:
            content = exc.read().decode("utf-8", errors="replace")
            raise RuntimeError(f"HTTP {exc.code} em {url}: {content}") from exc
        except urllib.error.URLError as exc:
            raise RuntimeError(f"Falha de conexão com {url}: {exc}") from exc

    def bootstrap(self, project_slug: str, *, module_slug: str | None = None, host: str | None = None, include_tasks: bool = False, dry_run: bool = False) -> dict[str, Any]:
        payload = {
            "project_slug": project_slug,
            "module_slug": module_slug,
            "host": host or os.getenv("PLANKA_MAP_HOST", "planka"),
            "include_tasks": include_tasks,
        }
        return self.post("/api/map/v1/integration/bootstrap", payload, dry_run=dry_run)


def resolve_module_binding(client: MapClient, args: argparse.Namespace, project_slug: str, raw_modules: list[str], fallback_module_name: str, fallback_module_slug: str) -> dict[str, Any]:
    explicit_module_slug = str(getattr(args, "module_slug", "") or "").strip()
    explicit_module_name = str(getattr(args, "module_name", "") or "").strip()
    module_mapping = load_module_slug_mapping()

    candidate_names = [item for item in raw_modules if item]
    if fallback_module_name and fallback_module_name not in candidate_names:
        candidate_names.append(fallback_module_name)

    if explicit_module_name and explicit_module_name not in candidate_names:
        candidate_names.insert(0, explicit_module_name)

    if explicit_module_slug:
        return {
            "module_slug": explicit_module_slug,
            "module_name": explicit_module_name or candidate_names[0] if candidate_names else explicit_module_slug,
            "module_labels": raw_modules or [explicit_module_name or explicit_module_slug],
            "resolution": {
                "strategy": "explicit_module_slug",
                "matched": True,
                "bootstrap_used": False,
                "available_modules": [],
            },
        }

    normalized_mapping = {
        str(key).strip(): str(value).strip()
        for key, value in module_mapping.items()
        if str(key).strip() and str(value).strip()
    }
    bootstrap_used = False
    available_modules: list[dict[str, str]] = []
    bootstrap_error: str | None = None

    try:
        bootstrap_response = client.bootstrap(project_slug, host=args.host, include_tasks=False, dry_run=False)
        available_modules = collect_bootstrap_modules(bootstrap_response)
        bootstrap_used = True
    except Exception as exc:  # noqa: BLE001
        bootstrap_error = str(exc)

    alias_candidates: list[str] = []
    normalized_alias_mapping = {
        normalize_token(key): value
        for key, value in normalized_mapping.items()
    }
    for candidate in candidate_names:
        mapped_slug = normalized_mapping.get(candidate) or normalized_mapping.get(slugify(candidate)) or normalized_alias_mapping.get(normalize_token(candidate))
        if mapped_slug:
            alias_candidates.append(mapped_slug)

    matched_module = match_module_candidate(alias_candidates + candidate_names, available_modules)
    if matched_module:
        return {
            "module_slug": matched_module["slug"],
            "module_name": matched_module["name"],
            "module_labels": raw_modules or [matched_module["name"]],
            "resolution": {
                "strategy": "bootstrap_match",
                "matched": True,
                "bootstrap_used": bootstrap_used,
                "bootstrap_error": bootstrap_error,
                "available_modules": available_modules,
                "candidates": candidate_names,
                "alias_candidates": alias_candidates,
            },
        }

    default_module = str(os.getenv("PLANKA_MAP_DEFAULT_MODULE", "geral")).strip()
    default_match = match_module_candidate([default_module], available_modules)
    if default_match:
        return {
            "module_slug": default_match["slug"],
            "module_name": default_match["name"],
            "module_labels": raw_modules or [default_match["name"]],
            "resolution": {
                "strategy": "default_module_match",
                "matched": True,
                "bootstrap_used": bootstrap_used,
                "bootstrap_error": bootstrap_error,
                "available_modules": available_modules,
                "candidates": candidate_names,
                "alias_candidates": alias_candidates,
            },
        }

    return {
        "module_slug": fallback_module_slug,
        "module_name": explicit_module_name or fallback_module_name,
        "module_labels": raw_modules or [fallback_module_name],
        "resolution": {
            "strategy": "pragmatic_fallback",
            "matched": False,
            "bootstrap_used": bootstrap_used,
            "bootstrap_error": bootstrap_error,
            "available_modules": available_modules,
            "candidates": candidate_names,
            "alias_candidates": alias_candidates,
        },
    }


def build_mapping_payload(client: MapClient, args: argparse.Namespace) -> dict[str, Any]:
    board_name = args.board_name or args.project_name or args.project_slug or "Planka Board"
    list_name = args.list_name or getattr(args, "list_context", None) or DEFAULT_BACKLOG_LIST
    card_title = args.card_title or args.title or "Nova task Planka"

    project_slug = resolve_project_slug(board_name, args.project_slug)
    modules, primary_module_name, primary_module_slug = extract_modules(args)
    resolved_module = resolve_module_binding(client, args, project_slug, modules, primary_module_name, primary_module_slug)
    list_slug = slugify(list_name)
    members = parse_csv(getattr(args, "member_names", None))

    task = {
        "title": card_title,
        "description": args.description or "",
        "status": normalize_status(args.status, list_name=list_name, event_name=getattr(args, "event_name", None)),
        "priority": normalize_priority(args.priority),
        "assignee": normalize_assignee(args.assignee, members=members),
        "context": {
            "source": "planka",
            "board_name": board_name,
            "list_name": list_name,
            "list_slug": list_slug,
            "entry_list": list_name or DEFAULT_BACKLOG_LIST,
            "entry_is_default_backlog": list_name.strip().lower() == DEFAULT_BACKLOG_LIST.strip().lower(),
            "module_labels": resolved_module["module_labels"],
            "module_resolution": resolved_module["resolution"],
            "member_names": members,
        },
    }

    return {
        "project_slug": project_slug,
        "project_name": args.project_name or board_name,
        "module_slug": resolved_module["module_slug"],
        "module_name": resolved_module["module_name"],
        "module_labels": resolved_module["module_labels"],
        "module_resolution": resolved_module["resolution"],
        "list_name": list_name,
        "list_slug": list_slug,
        "title": card_title,
        "task": task,
    }


def command_bootstrap(client: MapClient, args: argparse.Namespace) -> dict[str, Any]:
    payload = {
        "project_slug": args.project_slug,
        "module_slug": args.module_slug,
        "host": args.host,
        "include_tasks": not args.no_tasks,
    }
    return client.post("/api/map/v1/integration/bootstrap", payload, dry_run=args.dry_run)


def command_upsert(client: MapClient, args: argparse.Namespace) -> dict[str, Any]:
    mapped = build_mapping_payload(client, args)
    payload = {
        "project_slug": mapped["project_slug"],
        "module_slug": mapped["module_slug"],
        "module_name": mapped["module_name"],
        "module_labels": mapped["module_labels"],
        "module_resolution": mapped["module_resolution"],
        "list_context": {
            "name": mapped["list_name"],
            "slug": mapped["list_slug"],
            "role": "backlog_or_status",
        },
        "actor": args.actor,
        "task": mapped["task"],
    }
    return client.post("/api/map/v1/integration/task/upsert", payload, dry_run=args.dry_run)


def resolve_task_ref(args: argparse.Namespace) -> dict[str, Any]:
    ref: dict[str, Any] = {}
    if args.task_id:
        ref["task_id"] = args.task_id
        return ref
    if args.project_slug:
        ref["project_slug"] = args.project_slug
    if args.module_slug:
        ref["module_slug"] = args.module_slug
    if args.title:
        ref["title"] = args.title
    return ref


def command_session_start(client: MapClient, args: argparse.Namespace) -> dict[str, Any]:
    payload = {
        **resolve_task_ref(args),
        "host": args.host,
        "actor": args.actor,
        "task_status": normalize_status(args.task_status, event_name="session.start") if args.task_status else args.task_status,
        "host_state": args.host_state,
        "note": args.note,
    }
    return client.post("/api/map/v1/integration/session/start", payload, dry_run=args.dry_run)


def command_session_progress(client: MapClient, args: argparse.Namespace) -> dict[str, Any]:
    payload: dict[str, Any] = {
        **resolve_task_ref(args),
        "host": args.host,
        "actor": args.actor,
        "event_type": getattr(args, "event_type", "markscode_session_progress"),
        "note": args.note,
    }
    if args.percent is not None or args.message:
        payload["progress"] = {
            "percent": args.percent,
            "message": args.message,
        }
    task_update = {
        k: v
        for k, v in {
            "status": normalize_status(args.task_status, event_name="session.progress") if args.task_status else args.task_status,
            "priority": args.priority,
            "assignee": args.assignee,
        }.items()
        if v
    }
    if task_update:
        payload["task_update"] = task_update
    if args.host_state or args.host_state_note:
        payload["host_state"] = {
            "state": args.host_state or "working",
            "note": args.host_state_note,
        }
    return client.post("/api/map/v1/integration/session/progress", payload, dry_run=args.dry_run)


def command_session_end(client: MapClient, args: argparse.Namespace) -> dict[str, Any]:
    payload = {
        **resolve_task_ref(args),
        "host": args.host,
        "actor": args.actor,
        "task_status": normalize_status(args.task_status, event_name="session.end") if args.task_status else args.task_status,
        "host_state": args.host_state,
        "note": args.note,
    }
    return client.post("/api/map/v1/integration/session/end", payload, dry_run=args.dry_run)


def command_from_event(client: MapClient, args: argparse.Namespace) -> dict[str, Any]:
    mapped = build_mapping_payload(client, args)
    event_name = (args.event_name or "card.updated").strip().lower()

    if event_name in {"board.bootstrap", "bootstrap"}:
        payload = {
            "project_slug": mapped["project_slug"],
            "module_slug": mapped["module_slug"],
            "module_name": mapped["module_name"],
            "host": args.host,
            "include_tasks": True,
        }
        return client.post("/api/map/v1/integration/bootstrap", payload, dry_run=args.dry_run)

    if event_name in {"card.created", "card.updated", "task.upsert"}:
        payload = {
            "project_slug": mapped["project_slug"],
            "module_slug": mapped["module_slug"],
            "module_name": mapped["module_name"],
            "module_labels": mapped["module_labels"],
            "module_resolution": mapped["module_resolution"],
            "list_context": {
                "name": mapped["list_name"],
                "slug": mapped["list_slug"],
                "role": "backlog_or_status",
            },
            "actor": args.actor,
            "task": mapped["task"],
        }
        return client.post("/api/map/v1/integration/task/upsert", payload, dry_run=args.dry_run)

    if event_name in {"session.start", "card.started"}:
        args.project_slug = mapped["project_slug"]
        args.module_slug = mapped["module_slug"]
        args.module_name = mapped["module_name"]
        args.title = mapped["title"]
        return command_session_start(client, args)

    if event_name in {"session.progress", "card.moved", "card.progress"}:
        args.project_slug = mapped["project_slug"]
        args.module_slug = mapped["module_slug"]
        args.module_name = mapped["module_name"]
        args.title = mapped["title"]
        return command_session_progress(client, args)

    if event_name in {"session.end", "card.completed", "card.archived"}:
        args.project_slug = mapped["project_slug"]
        args.module_slug = mapped["module_slug"]
        args.module_name = mapped["module_name"]
        args.title = mapped["title"]
        return command_session_end(client, args)

    raise RuntimeError(f"Evento não suportado na fase prática atual: {event_name}")


def command_resolve_project(_client: MapClient, args: argparse.Namespace) -> dict[str, Any]:
    board_name = args.board_name or args.project_name or args.project_slug or "Planka Board"
    project_slug = resolve_project_slug(board_name, args.project_slug)
    return {
        "ok": True,
        "board_name": board_name,
        "project_slug": project_slug,
        "mapping": load_project_slug_mapping(),
        "fallback_slug": slugify(board_name),
        "used_explicit_project_slug": bool(args.project_slug),
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Bridge prática entre Planka e Map")
    parser.add_argument("--map-url", default=os.getenv("MAP_URL", "http://127.0.0.1:20320"), help="Base URL do Map")
    parser.add_argument("--actor", default=os.getenv("PLANKA_MAP_ACTOR", "markscode"), help="Ator lógico da integração")
    parser.add_argument("--host", default=os.getenv("PLANKA_MAP_HOST", "planka"), help="Host lógico usado nas sessões")
    parser.add_argument("--dry-run", action="store_true", help="Não envia HTTP; apenas mostra o payload")

    subparsers = parser.add_subparsers(dest="command", required=True)

    def add_common_runtime_options(target: argparse.ArgumentParser) -> None:
        target.add_argument("--dry-run", action="store_true", help="Não envia HTTP; apenas mostra o payload")

    bootstrap = subparsers.add_parser("bootstrap", help="Chama bootstrap do Map")
    add_common_runtime_options(bootstrap)
    bootstrap.add_argument("--project-slug", required=True)
    bootstrap.add_argument("--module-slug")
    bootstrap.add_argument("--no-tasks", action="store_true")

    upsert = subparsers.add_parser("upsert", help="Cria/atualiza task no Map")
    add_common_runtime_options(upsert)
    for target in (upsert,):
        target.add_argument("--board-name")
        target.add_argument("--list-name")
        target.add_argument("--card-title")
        target.add_argument("--project-slug")
        target.add_argument("--project-name")
        target.add_argument("--module-slug")
        target.add_argument("--module-name")
        target.add_argument("--module-names", help="Lista CSV opcional de módulos já resolvidos")
        target.add_argument("--label-names", help="Lista CSV de labels do card; fonte principal dos módulos")
        target.add_argument("--member-names", help="Lista CSV opcional de responsáveis vindos do MarksPlan")
        target.add_argument("--title")
        target.add_argument("--description")
        target.add_argument("--status")
        target.add_argument("--priority")
        target.add_argument("--assignee")

    session_start = subparsers.add_parser("session-start", help="Inicia sessão operacional no Map")
    add_common_runtime_options(session_start)
    session_start.add_argument("--task-id", type=int)
    session_start.add_argument("--project-slug")
    session_start.add_argument("--module-slug")
    session_start.add_argument("--title")
    session_start.add_argument("--task-status", default="in_progress")
    session_start.add_argument("--host-state", default="working")
    session_start.add_argument("--note")

    session_progress = subparsers.add_parser("session-progress", help="Registra progresso de sessão no Map")
    add_common_runtime_options(session_progress)
    session_progress.add_argument("--task-id", type=int)
    session_progress.add_argument("--project-slug")
    session_progress.add_argument("--module-slug")
    session_progress.add_argument("--title")
    session_progress.add_argument("--event-type", default="markscode_session_progress")
    session_progress.add_argument("--percent", type=int)
    session_progress.add_argument("--message")
    session_progress.add_argument("--task-status")
    session_progress.add_argument("--priority")
    session_progress.add_argument("--assignee")
    session_progress.add_argument("--host-state")
    session_progress.add_argument("--host-state-note")
    session_progress.add_argument("--note")

    session_end = subparsers.add_parser("session-end", help="Encerra sessão operacional no Map")
    add_common_runtime_options(session_end)
    session_end.add_argument("--task-id", type=int)
    session_end.add_argument("--project-slug")
    session_end.add_argument("--module-slug")
    session_end.add_argument("--title")
    session_end.add_argument("--task-status", default="done")
    session_end.add_argument("--host-state", default="idle")
    session_end.add_argument("--note")

    event = subparsers.add_parser("from-event", help="Transforma evento pragmático do Planka em chamada Map")
    add_common_runtime_options(event)
    event.add_argument("--event-name", required=True)
    event.add_argument("--board-name")
    event.add_argument("--list-name")
    event.add_argument("--card-title")
    event.add_argument("--project-slug")
    event.add_argument("--project-name")
    event.add_argument("--module-slug")
    event.add_argument("--module-name")
    event.add_argument("--module-names", help="Lista CSV opcional de módulos já resolvidos")
    event.add_argument("--label-names", help="Lista CSV de labels do card; fonte principal dos módulos")
    event.add_argument("--member-names", help="Lista CSV opcional de responsáveis vindos do MarksPlan")
    event.add_argument("--title")
    event.add_argument("--description")
    event.add_argument("--status")
    event.add_argument("--priority")
    event.add_argument("--assignee")
    event.add_argument("--task-id", type=int)
    event.add_argument("--task-status")
    event.add_argument("--event-type", default="markscode_session_progress")
    event.add_argument("--host-state")
    event.add_argument("--host-state-note")
    event.add_argument("--percent", type=int)
    event.add_argument("--message")
    event.add_argument("--note")

    resolve_project = subparsers.add_parser("resolve-project", help="Resolve board_name -> project_slug sem chamar o Map")
    add_common_runtime_options(resolve_project)
    resolve_project.add_argument("--board-name")
    resolve_project.add_argument("--project-name")
    resolve_project.add_argument("--project-slug")

    return parser


def main() -> int:
    bridge_dir = os.path.dirname(os.path.abspath(__file__))
    load_dotenv(os.path.join(bridge_dir, ".env"), override=True)
    parser = build_parser()
    args = parser.parse_args()

    client = MapClient(args.map_url)
    handlers = {
        "bootstrap": command_bootstrap,
        "upsert": command_upsert,
        "session-start": command_session_start,
        "session-progress": command_session_progress,
        "session-end": command_session_end,
        "from-event": command_from_event,
        "resolve-project": command_resolve_project,
    }

    try:
        result = handlers[args.command](client, args)
    except Exception as exc:  # noqa: BLE001
        print(json.dumps({"ok": False, "error": str(exc)}, ensure_ascii=False, indent=2), file=sys.stderr)
        return 1

    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
