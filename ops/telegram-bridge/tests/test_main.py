import sys
from pathlib import Path

# Ajoute ops/telegram-bridge dans le chemin de recherche Python
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import pytest
from fastapi.testclient import TestClient

from app import main

OWNER = 1111
SECRET = "test-webhook-secret"


class FakeResponse:
    def __init__(self, status_code: int, data: dict | None = None):
        self.status_code = status_code
        self._data = data or {}

    def json(self):
        return self._data


@pytest.fixture
def calls(monkeypatch):
    """Remplace Telegram et GitHub par des faux qui enregistrent les appels."""
    recorded = {"telegram": [], "github": []}

    def fake_telegram(method, payload):
        recorded["telegram"].append((method, payload))
        return {}

    def fake_github(method, path, payload=None):
        recorded["github"].append((method, path, payload))
        if method == "POST" and path == "/issues":
            return FakeResponse(201, {"number": 42, "html_url": "https://github.com/o/r/issues/42"})
        if method == "POST" and path.endswith("/comments"):
            return FakeResponse(201)
        if method == "POST" and path.endswith("/labels"):
            return FakeResponse(200)
        return FakeResponse(404)

    monkeypatch.setattr(main, "telegram", fake_telegram)
    monkeypatch.setattr(main, "github", fake_github)
    monkeypatch.setenv("TELEGRAM_WEBHOOK_SECRET", SECRET)
    monkeypatch.setenv("TELEGRAM_OWNER_ID", str(OWNER))
    return recorded


client = TestClient(main.app)


def post(update, secret=SECRET):
    return client.post("/webhook", json=update, headers={"X-Telegram-Bot-Api-Secret-Token": secret})


def message(text, user=OWNER, reply_to=None):
    msg = {"chat": {"id": user}, "from": {"id": user}, "text": text}
    if reply_to:
        msg["reply_to_message"] = {"text": reply_to}
    return {"message": msg}


def sent_texts(calls):
    return [p["text"] for m, p in calls["telegram"] if m == "sendMessage"]


def test_health():
    assert client.get("/health").json() == {"status": "OK"}


def test_wrong_secret_is_rejected(calls):
    assert post(message("bonjour"), secret="mauvais").status_code == 403
    assert calls["github"] == []


def test_stranger_is_ignored(calls):
    assert post(message("supprime tout", user=9999)).status_code == 200
    assert calls["github"] == []
    assert calls["telegram"] == []


def test_message_creates_issue_without_label(calls):
    post(message("Route /items\nLister les éléments\nCritère : 200"))
    method, path, payload = calls["github"][0]
    assert (method, path) == ("POST", "/issues")
    assert payload["title"] == "Route /items"
    assert "Lister les éléments" in payload["body"]
    assert "labels" not in payload
    send_payload = [p for m, p in calls["telegram"] if m == "sendMessage"][0]
    button = send_payload["reply_markup"]["inline_keyboard"][0][0]
    assert button["callback_data"] == "launch:42"


def test_launch_button_sets_label(calls):
    post({"callback_query": {"id": "cb1", "from": {"id": OWNER}, "data": "launch:42",
                             "message": {"chat": {"id": OWNER}}}})
    assert ("DELETE", "/issues/42/labels/ai-dev", None) in calls["github"]
    assert ("POST", "/issues/42/labels", {"labels": ["ai-dev"]}) in calls["github"]
    assert any("Agent lancé sur #42" in t for t in sent_texts(calls))


def test_launch_button_from_stranger_is_ignored(calls):
    post({"callback_query": {"id": "cb1", "from": {"id": 9999}, "data": "launch:42",
                             "message": {"chat": {"id": 9999}}}})
    assert calls["github"] == []


def test_reply_command_comments_issue(calls):
    post(message("/r 7 Oui, en français"))
    method, path, payload = calls["github"][0]
    assert (method, path) == ("POST", "/issues/7/comments")
    assert payload["body"].startswith("Oui, en français")


def test_reply_to_notification_comments_issue(calls):
    post(message("Utilise le vouvoiement", reply_to="❓ #12 : l'orchestrateur a des questions"))
    method, path, _ = calls["github"][0]
    assert (method, path) == ("POST", "/issues/12/comments")


def test_unconfigured_owner_only_gives_id(calls, monkeypatch):
    monkeypatch.setenv("TELEGRAM_OWNER_ID", "")
    post(message("bonjour", user=5555))
    assert calls["github"] == []
    assert "5555" in sent_texts(calls)[0]
