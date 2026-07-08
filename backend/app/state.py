"""Writable application state (orders, seed edits).

The catalog ships as read-only bundled data (seed.json / dogu.db). Mutable
state must live somewhere writable — on serverless the app bundle is read-only,
so writing back to seed.json or keeping orders in a per-invocation memory list
silently loses data. This module keeps mutable state in a configurable writable
directory (DOGU_STATE_DIR), defaulting to the system temp dir so writes never
500. Point DOGU_STATE_DIR at a persistent path/volume for real durability.
"""
import json
import os
import sqlite3
import tempfile
from pathlib import Path


def state_dir() -> Path:
    configured = os.environ.get("DOGU_STATE_DIR")
    path = Path(configured) if configured else Path(tempfile.gettempdir()) / "dogu-state"
    path.mkdir(parents=True, exist_ok=True)
    return path


def _db_path() -> Path:
    return state_dir() / "state.db"


def _conn() -> sqlite3.Connection:
    conn = sqlite3.connect(_db_path())
    conn.row_factory = sqlite3.Row
    conn.execute(
        "CREATE TABLE IF NOT EXISTS orders ("
        "  order_id TEXT PRIMARY KEY,"
        "  created_at TEXT NOT NULL DEFAULT (datetime('now')),"
        "  payload TEXT NOT NULL"
        ")"
    )
    return conn


def add_order(order_id: str, payload: dict) -> None:
    with _conn() as conn:
        conn.execute(
            "INSERT OR REPLACE INTO orders (order_id, payload) VALUES (?, ?)",
            (order_id, json.dumps(payload, ensure_ascii=False)),
        )


def list_orders() -> list[dict]:
    with _conn() as conn:
        rows = conn.execute(
            "SELECT payload FROM orders ORDER BY created_at DESC, rowid DESC"
        ).fetchall()
    return [json.loads(row["payload"]) for row in rows]


def seed_override_path() -> Path:
    return state_dir() / "seed_override.json"
