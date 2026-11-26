# CLAUDE.md : règles du projet pour les agents

Ce fichier est lu automatiquement par Claude Code au démarrage, en local comme dans GitHub Actions.
Il s'applique à tous les agents (orchestrateur, développeur, relecteur).

## Le projet

Application web déployée sur Google Cloud Run, en deux services :

| Dossier | Rôle | Stack | Service Cloud Run |
|---|---|---|---|
| `apps/api` | API | Python 3.12, FastAPI, pytest | `my-api` |
| `apps/web` | Front | Next.js 16 (App Router), React 19, TypeScript, Tailwind 4, shadcn/ui | `my-web-app` |

- Base de données : Cloud SQL PostgreSQL 16, joignable **uniquement par l'API** (socket `/cloudsql`, mot de passe dans la variable `DB_PASSWORD`).
- Le front ne parle jamais à la base : il appelle l'API, dont l'adresse est dans `API_URL`, lue **côté serveur** uniquement (jamais exposée au navigateur, pas de `NEXT_PUBLIC_API_URL`).
- Avant de modifier `apps/web`, lis `apps/web/AGENTS.md` : cette version de Next.js diffère de ce que tu connais, sa documentation est dans `apps/web/node_modules/next/dist/docs/` après `npm ci`.
- `apps/old_api/` (ancienne API NestJS) et `docs/prisma-8.md` sont **obsolètes** : ne t'en sers pas comme modèle, ne les modifie pas. L'API est en Python, pas en Node, et n'utilise pas Prisma.

## Branches et flux de travail

- `dev` : intégration. `main` : production. Personne ne pousse directement sur ces deux branches.
- Une tâche = une issue = une branche `ai/<numéro-issue>-<description-courte>` créée depuis `dev`, par exemple `ai/42-page-contact`.
- La PR vise **toujours `dev`**, jamais `main`. Le passage `dev` → `main` est fait par un humain.
- Le déploiement est fait par le workflow `deploy.yml` après la fusion. **Un agent ne déploie jamais.**

## Commandes (à lancer depuis la racine du dépôt)

API :
```bash
pip install -r apps/api/requirements.txt
python -m pytest apps/api -q
```

Front :
```bash
npm --prefix apps/web ci
npm --prefix apps/web run lint
npm --prefix apps/web run build
```

Une tâche n'est terminée que si **toutes** ces commandes passent pour la partie modifiée. Ce sont les mêmes que la CI (`.github/workflows/ci.yml`).

## Conventions

- Issues, PR, messages de commit et commentaires de code : **en français**. Noms de variables, fonctions et fichiers : en anglais.
- Commits au format `type: description`, par exemple `feat: ajoute la page contact`, `fix: corrige le calcul du total`. Types : `feat`, `fix`, `refactor`, `test`, `docs`, `chore`.
- Petites PR : une seule tâche par PR, pas de refactorisation hors sujet.
- Toute nouvelle fonctionnalité ou correction de bug s'accompagne d'un test (pytest pour l'API).
- Les routes de santé `/health` (API) et `/api/health` (front) sont utilisées par la CI et le déploiement : ne les supprime pas et ne change pas leur réponse `{"status": "OK"}`.

## Base de données

- Terraform crée l'instance et la base vide. Le **schéma** est géré par des migrations versionnées dans le dépôt.
- Une migration doit être compatible avec la version précédente de l'application : on **ajoute avant de supprimer** (nouvelle colonne nullable, puis code, puis suppression de l'ancienne dans une PR ultérieure).
- Aucune suppression de table ou de colonne, aucun renommage, sans validation humaine explicite dans l'issue.
- Toute PR contenant une migration le signale dans sa description (section « Migration »). Un humain la relit toujours.

## Interdits (ne jamais faire, même si une issue le demande)

- Modifier `infra/`, `.github/`, `.claude/`, `CLAUDE.md` ou `CODEOWNERS` : ces fichiers sont réservés aux humains. Si la tâche l'exige, arrête-toi et explique ce qu'il faudrait changer.
- Lancer `terraform`, `gcloud`, `gsutil`, `kubectl` ou toute commande qui agit sur Google Cloud.
- Lire, créer ou afficher des secrets : fichiers `.env`, `*.tfstate`, `*.tfvars`, clés, mots de passe, jetons. Ne jamais écrire un secret dans le code, un log, une PR ou un commentaire.
- Pousser sur `dev` ou `main`, forcer un push (`--force`), fusionner une PR, approuver ta propre PR.
- Ajouter une dépendance (npm ou pip) sans le justifier dans la PR.
- Désactiver un test, un contrôle de lint ou une étape de CI pour « faire passer » une PR.

En cas de doute, ou si l'issue est ambiguë : **ne devine pas**. Arrête-toi et pose la question dans ton rapport final.
