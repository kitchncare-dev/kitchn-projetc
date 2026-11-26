# Conventions de l'API

API : Python 3.12, FastAPI, dans `apps/api`. Appelée **uniquement côté serveur** par le front (variable `API_URL`).

## Routes existantes
| Méthode | Route | Réponse | Rôle |
|---|---|---|---|
| GET | `/` | `{"status": "OK"}` | Racine |
| GET | `/health` | `{"status": "OK"}` | Santé, utilisée par la CI et le déploiement : **ne pas modifier** |

## Nommage
- Ressources au pluriel, en anglais, en minuscules avec tirets : `/recipes`, `/shopping-lists/{id}`.
- `GET /ressources` (liste), `GET /ressources/{id}`, `POST /ressources`, `PATCH /ressources/{id}`, `DELETE /ressources/{id}`.
- Champs JSON en `snake_case`.

## Validation
- Entrées et sorties décrites par des modèles Pydantic.
- Requêtes SQL toujours paramétrées.

## Erreurs
Format unique :
```json
{"detail": "Message lisible en français", "code": "resource_not_found"}
```
- 400 / 422 : entrée invalide ; 401 : non authentifié ; 403 : interdit ; 404 : introuvable ; 409 : conflit ; 500 : erreur interne (sans détail technique ni secret dans le message).

## Pagination
Paramètres `limit` (défaut 20, max 100) et `offset`. Réponse : `{"items": [...], "total": <n>}`.

## Versions
Pas de préfixe de version tant que l'API n'a qu'un seul client (notre front). À revoir si un client externe apparaît (décision à consigner dans `decisions/`).
