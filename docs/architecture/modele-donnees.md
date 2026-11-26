# Modèle de données

Base : Cloud SQL PostgreSQL 16, base `app`, utilisateur `app`, joignable **uniquement par l'API**.
Le schéma est géré par des migrations versionnées (Alembic, à mettre en place quand l'API utilisera la base). Terraform ne crée **aucune** table.

## Tables actuelles
Aucune pour l'instant.

## Tables prévues
<À compléter au fil des fiches de fonctionnalités. Pour chaque table :>

### `<nom_table>` (prévue pour F<XX>)
| Colonne | Type | Contraintes | Utilisée par |
|---|---|---|---|
| `id` | `uuid` | clé primaire | |
| `created_at` | `timestamptz` | non nul, défaut `now()` | |

## Règles
- Noms de tables et colonnes en anglais, en `snake_case`, tables au pluriel (`recipes`).
- Toute table a `id`, `created_at`, `updated_at`.
- Migrations compatibles avec la version précédente : on ajoute avant de supprimer.
- Aucune suppression ni aucun renommage sans validation humaine écrite dans l'issue.
