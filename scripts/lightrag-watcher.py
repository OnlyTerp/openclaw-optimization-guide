#!/usr/bin/env python3
"""Auto-ingest ~/.openclaw/workspace/ .md files into LightRAG on change.

Watches the workspace directory recursively. When a .md file is created or
modified, waits DEBOUNCE_SECONDS for further changes, then POSTs the content
to the LightRAG HTTP API for knowledge-graph ingestion.
"""
import logging
import os
import sys
import threading
import time
from pathlib import Path

try:
    import requests
    from watchdog.events import FileSystemEventHandler
    from watchdog.observers import Observer
except ImportError:
    sys.exit("Missing deps — run: pip install watchdog requests")

WATCH_DIR = Path.home() / ".openclaw" / "workspace"
LIGHTRAG_URL = "http://127.0.0.1:9621/documents/text"
DEBOUNCE_SECONDS = float(os.environ.get("WATCHER_DEBOUNCE", "5"))
LOG_FILE = Path.home() / ".lightrag" / "watcher.log"

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s watcher %(levelname)s: %(message)s",
    handlers=[logging.FileHandler(LOG_FILE), logging.StreamHandler()],
)
log = logging.getLogger(__name__)


class DebounceHandler(FileSystemEventHandler):
    def __init__(self):
        self._pending: dict[str, threading.Timer] = {}

    def on_modified(self, event):
        if not event.is_directory and event.src_path.endswith(".md"):
            self._schedule(event.src_path)

    def on_created(self, event):
        if not event.is_directory and event.src_path.endswith(".md"):
            self._schedule(event.src_path)

    def _schedule(self, path: str):
        if path in self._pending:
            self._pending[path].cancel()
        t = threading.Timer(DEBOUNCE_SECONDS, self._ingest, args=[path])
        t.daemon = True
        self._pending[path] = t
        t.start()

    def _ingest(self, path: str):
        self._pending.pop(path, None)
        try:
            text = Path(path).read_text(encoding="utf-8", errors="replace")
        except OSError as e:
            log.warning("read error %s: %s", path, e)
            return
        try:
            resp = requests.post(
                LIGHTRAG_URL,
                json={"text": text, "description": path},
                timeout=30,
            )
            resp.raise_for_status()
            log.info("ingested %s (%d chars)", path, len(text))
        except Exception as e:
            log.warning("ingest failed %s: %s", path, e)


if __name__ == "__main__":
    LOG_FILE.parent.mkdir(parents=True, exist_ok=True)
    WATCH_DIR.mkdir(parents=True, exist_ok=True)
    log.info("watching %s → %s", WATCH_DIR, LIGHTRAG_URL)
    handler = DebounceHandler()
    observer = Observer()
    observer.schedule(handler, str(WATCH_DIR), recursive=True)
    observer.start()
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        pass
    finally:
        observer.stop()
        observer.join()
