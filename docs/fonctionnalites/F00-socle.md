# F00 : Socle technique

- **Statut** : faite
- **Issue(s)** : #28 (route `/version`)
- **Dépend de** : Aucune
- **Utilisée par / prévue pour** : toutes les fonctionnalités (routes de santé, déploiement, version de l'API)

## Objectif
Fournir le socle technique : une API et un front déployables sur Cloud Run, avec des routes de santé utilisées par la CI et le déploiement, et une route indiquant la version de l'API.

## Règles métier
- `/health` renvoie toujours `{"status": "OK"}` : elle ne change pas.
- `/version` renvoie `{"version": "<VERSION>"}` ; la valeur vient de la constante `VERSION` de `apps/api/app/main.py`, aussi utilisée par `FastAPI(version=...)`.

## Données concernées
Aucune.

## Routes API
| Méthode | Route | Rôle | Statut |
|---|---|---|---|
| GET | `/` | Racine | faite |
| GET | `/health` | Santé (CI, déploiement) | faite |
| GET | `/version` | Version de l'API | faite |

## Écrans
| Écran | Route du front | États gérés (chargement, vide, erreur, succès) |
|---|---|---|
| Santé du front | `/api/health` | sans objet |

## Critères d'acceptation
- [x] `GET /health` renvoie 200 et `{"status": "OK"}`.
- [x] `GET /version` renvoie 200 et `{"version": "1.0.0"}` (test pytest).

## Ce qu'il faut prévoir pour les fonctionnalités liées
Aucun.
