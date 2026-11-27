#!/usr/bin/env bash
# Contrôle puis publie le travail d'un agent (sans IA) :
#   1. vérifie le nom de la branche, l'absence de fichiers non commités et de fichiers protégés ;
#   2. cherche des secrets dans les commits de l'agent (Gitleaks) ;
#   3. pousse la branche et ouvre la PR vers dev (ou réutilise celle qui existe déjà).
#
# Utilisé par agent-dev.yml et agent-publish.yml. Les workflows en font une COPIE avant que
# l'agent ne touche au dépôt : une modification de ce fichier par un agent n'aurait aucun effet.
#
# Variables attendues :
#   REPO          dépôt (propriétaire/nom)
#   ISSUE_NUMBER  numéro de l'issue
#   RESULT_FILE   fichier JSON rendu par l'orchestrateur (pr_title, pr_body)
#   PUSH_TOKEN    jeton utilisé pour pousser et ouvrir la PR
#   USING_APP     "true" si PUSH_TOKEN vient de l'application GitHub des agents
# Écrit « url=<lien de la PR> » dans $GITHUB_OUTPUT.

set -euo pipefail

BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "Branche : $BRANCH"

case "$BRANCH" in
  "ai/${ISSUE_NUMBER}-"*) ;;
  *) echo "::error::La branche doit s'appeler ai/${ISSUE_NUMBER}-<description>, reçu : $BRANCH"; exit 1 ;;
esac

if [ -n "$(git status --porcelain)" ]; then
  echo "::error::Des fichiers ne sont pas commités :"; git status --short; exit 1
fi

git fetch -q origin dev
CHANGED=$(git diff --name-only origin/dev...HEAD)
if [ -z "$CHANGED" ]; then
  echo "::error::Aucun changement par rapport à dev."; exit 1
fi
echo "Fichiers modifiés :"; echo "$CHANGED"

# Fichiers réservés aux humains, secrets et fichiers générés : on refuse de pousser
FORBIDDEN=$(echo "$CHANGED" | grep -E \
  '^(infra/|ops/|\.github/|\.claude/|docs/produit/)|(^|/)CLAUDE\.md$|(^|/)CODEOWNERS$|(^|/)\.env|\.tfstate|\.tfvars|__pycache__/|\.pyc$|(^|/)\.pytest_cache/|(^|/)node_modules/|(^|/)\.next/|(^|/)\.agent-context/' \
  || true)
if [ -n "$FORBIDDEN" ]; then
  echo "::error::Fichiers interdits dans les commits de l'agent :"; echo "$FORBIDDEN"; exit 1
fi

# Filet générique : aucun fichier suivi ne doit correspondre au .gitignore de la branche
# (les agents complètent le .gitignore quand une nouvelle technologie génère d'autres fichiers)
IGNORED=$(git ls-files -ci --exclude-standard)
if [ -n "$IGNORED" ]; then
  echo "::error::Fichiers commités alors qu'ils sont ignorés par .gitignore (fichiers générés ?) :"; echo "$IGNORED"; exit 1
fi

echo "Recherche de secrets dans les commits de l'agent…"
docker run --rm --user "$(id -u):$(id -g)" -v "$PWD:/repo" -w /repo \
  ghcr.io/gitleaks/gitleaks:latest \
  git --redact --no-banner --log-opts="origin/dev..HEAD" /repo

# Pousser (en ignorant l'en-tête d'authentification laissé par actions/checkout)
git -c "http.https://github.com/.extraheader=" \
  push "https://x-access-token:${PUSH_TOKEN}@github.com/${REPO}.git" "HEAD:refs/heads/${BRANCH}"

export GH_TOKEN="$PUSH_TOKEN"

URL=$(gh pr list --repo "$REPO" --head "$BRANCH" --state open --json url --jq '.[0].url // empty')
if [ -n "$URL" ]; then
  echo "PR déjà ouverte : $URL (mise à jour par le push)"
else
  TITLE=$(jq -r '.pr_title // empty' "$RESULT_FILE" 2>/dev/null || true)
  [ -z "$TITLE" ] && TITLE="Issue #${ISSUE_NUMBER}"
  BODY=$(jq -r '.pr_body // empty' "$RESULT_FILE" 2>/dev/null || true)
  if ! echo "$BODY" | grep -q "Closes #${ISSUE_NUMBER}"; then
    BODY=$(printf 'Closes #%s\n\n%s' "$ISSUE_NUMBER" "$BODY")
  fi
  NOTE="_PR ouverte automatiquement par le workflow des agents._"
  if [ "${USING_APP:-false}" != "true" ]; then
    NOTE="$NOTE"$'\n\n'"⚠️ Ouverte avec le jeton par défaut : la CI et la relecture IA ne se lancent pas toutes seules. Pour les lancer, ferme puis rouvre cette PR."
  fi
  printf '%s\n\n---\n%s\n' "$BODY" "$NOTE" > "${RUNNER_TEMP:-/tmp}/pr-body.md"

  URL=$(gh pr create --repo "$REPO" --base dev --head "$BRANCH" \
    --title "$TITLE" --body-file "${RUNNER_TEMP:-/tmp}/pr-body.md")
  echo "PR ouverte : $URL"
fi

echo "url=$URL" >> "${GITHUB_OUTPUT:-/dev/null}"
