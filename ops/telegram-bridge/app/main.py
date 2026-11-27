"""Pont Telegram -> GitHub.

Reçoit les messages du bot Telegram (webhook) et les transforme en actions sur les issues GitHub :
- un message texte crée une issue (sans label) et propose un bouton « Lancer l'agent » ;
- le bouton pose le label « ai-dev », ce qui lance le workflow agent-dev ;
- /r <n°> <texte>, ou une réponse à une notification qui contient « #<n°> », ajoute un commentaire.

Sécurité :
- Telegram signe chaque appel avec un jeton secret (en-tête X-Telegram-Bot-Api-Secret-Token) ;
- seul l'identifiant Telegram du propriétaire est accepté, tout le reste est ignoré ;
- le jeton GitHub n'a que les droits « Issues » sur ce dépôt ;
- les secrets viennent de Secret Manager (variables d'environnement Cloud Run), jamais du code.
"""

import hmac
import logging
import os
import re

import httpx
from fastapi import FastAPI, Header, HTTPException, Request

logging.basicConfig(level=logging.INFO)
log = logging.getLogger("telegram-bridge")

AGENT_LABEL = "ai-dev"
MAX_TITLE_LENGTH = 120
HELP_TEXT = (
    "Envoie-moi une tâche en un message :\n"
    "• 1re ligne : le titre de l'issue\n"
    "• lignes suivantes : objectif, comportement attendu, critères d'acceptation\n\n"
    "Je crée l'issue, puis tu cliques sur « 🚀 Lancer l'agent ».\n\n"
    "Autres commandes :\n"
    "• /r <n°> <texte> : répondre dans l'issue n° (par exemple aux questions de l'orchestrateur)\n"
    "• répondre à une de mes notifications : ajoute ton texte en commentaire de l'issue concernée\n"
    "• /aide : ce message"
)

app = FastAPI(title="telegram-bridge", version="1.0.0")


# ---------------------------------------------------------------------------
# Configuration (lue à chaque appel pour simplifier les tests)
# ---------------------------------------------------------------------------
def setting(name: str) -> str:
    return os.environ.get(name, "").strip()


def owner_id() -> int | None:
    """Identifiant Telegram du propriétaire ; None (mode mise en service) s'il vaut 0 ou est absent."""
    value = setting("TELEGRAM_OWNER_ID")
    return int(value) if value.isdigit() and int(value) > 0 else None


# ---------------------------------------------------------------------------
# Appels sortants (remplacés par des faux dans les tests)
# ---------------------------------------------------------------------------
def telegram(method: str, payload: dict) -> dict:
    token = setting("TELEGRAM_BOT_TOKEN")
    response = httpx.post(f"https://api.telegram.org/bot{token}/{method}", json=payload, timeout=10)
    if response.status_code != 200:
        log.error("Telegram %s : HTTP %s", method, response.status_code)
    return response.json() if response.content else {}


def github(method: str, path: str, payload: dict | None = None) -> httpx.Response:
    repo = setting("GITHUB_REPO")
    response = httpx.request(
        method,
        f"https://api.github.com/repos/{repo}{path}",
        json=payload,
        headers={
            "Authorization": f"Bearer {setting('GITHUB_TOKEN')}",
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
        },
        timeout=15,
    )
    if response.status_code >= 400 and response.status_code != 404:
        log.error("GitHub %s %s : HTTP %s", method, path, response.status_code)
    return response


def send(chat_id: int, text: str, buttons: list[list[dict]] | None = None) -> None:
    payload: dict = {"chat_id": chat_id, "text": text[:4000], "disable_web_page_preview": True}
    if buttons:
        payload["reply_markup"] = {"inline_keyboard": buttons}
    telegram("sendMessage", payload)


# ---------------------------------------------------------------------------
# Actions sur GitHub
# ---------------------------------------------------------------------------
def build_issue(text: str) -> tuple[str, str]:
    """Première ligne = titre, le reste = description."""
    lines = text.strip().splitlines()
    title = lines[0].strip()[:MAX_TITLE_LENGTH] or "Tâche envoyée depuis Telegram"
    details = "\n".join(lines[1:]).strip() or "_Aucun détail fourni : l'orchestrateur posera ses questions._"
    body = (
        "## Description\n\n"
        f"{details}\n\n"
        "---\n"
        "_Issue créée depuis Telegram. Les rubriques manquantes (objectif, comportement attendu, "
        "critères d'acceptation) peuvent être complétées sur GitHub avant le lancement._"
    )
    return title, body


def create_issue(chat_id: int, text: str) -> None:
    title, body = build_issue(text)
    response = github("POST", "/issues", {"title": title, "body": body})
    if response.status_code != 201:
        send(chat_id, f"⛔ Impossible de créer l'issue (GitHub a répondu {response.status_code}).")
        return
    issue = response.json()
    number, url = issue["number"], issue["html_url"]
    send(
        chat_id,
        f"📝 Issue #{number} créée : {title}\n\nVérifie-la ou complète-la, puis lance l'agent.",
        [[
            {"text": "🚀 Lancer l'agent", "callback_data": f"launch:{number}"},
            {"text": "Voir sur GitHub", "url": url},
        ]],
    )


def launch_agent(chat_id: int, number: int) -> None:
    # Retirer puis remettre le label : GitHub n'envoie l'événement « labeled » qu'à l'ajout
    github("DELETE", f"/issues/{number}/labels/{AGENT_LABEL}")
    response = github("POST", f"/issues/{number}/labels", {"labels": [AGENT_LABEL]})
    if response.status_code != 200:
        send(chat_id, f"⛔ Impossible de lancer l'agent sur #{number} (GitHub a répondu {response.status_code}).")
        return
    send(chat_id, f"🚀 Agent lancé sur #{number}. Je te préviens à la fin.")


def comment_issue(chat_id: int, number: int, text: str) -> None:
    response = github("POST", f"/issues/{number}/comments", {"body": f"{text}\n\n_(envoyé depuis Telegram)_"})
    if response.status_code != 201:
        send(chat_id, f"⛔ Impossible de commenter #{number} (GitHub a répondu {response.status_code}).")
        return
    send(
        chat_id,
        f"💬 Commentaire ajouté sur #{number}.",
        [[{"text": "🔁 Relancer l'agent", "callback_data": f"launch:{number}"}]],
    )


# ---------------------------------------------------------------------------
# Traitement des messages Telegram
# ---------------------------------------------------------------------------
ISSUE_REF = re.compile(r"#(\d+)")
REPLY_COMMAND = re.compile(r"^/r(?:epondre)?(?:@\w+)?\s+#?(\d+)\s+(.+)$", re.DOTALL)


def handle_message(message: dict) -> None:
    chat_id = message["chat"]["id"]
    text = (message.get("text") or "").strip()
    if not text:
        send(chat_id, "Je ne comprends que les messages texte.")
        return

    if text.startswith(("/start", "/aide", "/help")):
        send(chat_id, HELP_TEXT)
        return

    match = REPLY_COMMAND.match(text)
    if match:
        comment_issue(chat_id, int(match.group(1)), match.group(2).strip())
        return

    if text.startswith("/"):
        send(chat_id, "Commande inconnue.\n\n" + HELP_TEXT)
        return

    # Réponse à une de mes notifications : on retrouve le numéro d'issue dans le message d'origine
    replied = (message.get("reply_to_message") or {}).get("text") or ""
    ref = ISSUE_REF.search(replied)
    if ref:
        comment_issue(chat_id, int(ref.group(1)), text)
        return

    create_issue(chat_id, text)


def handle_callback(callback: dict) -> None:
    telegram("answerCallbackQuery", {"callback_query_id": callback["id"]})
    chat_id = callback["message"]["chat"]["id"]
    action, _, value = (callback.get("data") or "").partition(":")
    if action == "launch" and value.isdigit():
        launch_agent(chat_id, int(value))


def sender_id(update: dict) -> int | None:
    for key in ("message", "callback_query"):
        if key in update:
            return (update[key].get("from") or {}).get("id")
    return None


@app.get("/health")
def health() -> dict:
    return {"status": "OK"}


@app.post("/webhook")
async def webhook(
    request: Request,
    x_telegram_bot_api_secret_token: str = Header(default=""),
) -> dict:
    expected = setting("TELEGRAM_WEBHOOK_SECRET")
    if not expected or not hmac.compare_digest(x_telegram_bot_api_secret_token, expected):
        raise HTTPException(status_code=403)

    update = await request.json()
    user = sender_id(update)
    owner = owner_id()

    # Mise en service : tant que le propriétaire n'est pas configuré, on donne seulement son identifiant
    if owner is None:
        if "message" in update:
            send(update["message"]["chat"]["id"], f"Ton identifiant Telegram est : {user}\n"
                 "Enregistre-le dans le secret « telegram-owner-id », puis redéploie le bridge.")
        return {"ok": True}

    if user != owner:
        log.warning("Message ignoré : expéditeur non autorisé")
        return {"ok": True}

    try:
        if "message" in update:
            handle_message(update["message"])
        elif "callback_query" in update:
            handle_callback(update["callback_query"])
    except Exception:  # on répond toujours 200 à Telegram, sinon il renvoie le message en boucle
        log.exception("Erreur pendant le traitement")
        chat = (update.get("message") or (update.get("callback_query") or {}).get("message") or {}).get("chat", {})
        if chat.get("id"):
            send(chat["id"], "⛔ Erreur interne du bridge (voir les journaux Cloud Run).")
    return {"ok": True}
