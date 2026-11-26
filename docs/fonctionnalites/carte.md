# Carte des fonctionnalités

Liste de **toutes** les fonctionnalités, faites, en cours ou prévues, dans l'ordre de réalisation.
Chaque ligne renvoie à sa fiche (modèle : `_modele.md`).

| Code | Fonctionnalité | Statut | Dépend de | Utilisée par | Fiche |
|---|---|---|---|---|---|
| F00 | Socle technique (routes de santé, déploiement) | faite | — | toutes | — |
| F01 | <à définir par le propriétaire> | prévue | F00 | | `F01-<nom>.md` |

## Règles
- Le **code** (F01, F02…) ne change jamais, même si la fonctionnalité est renommée.
- « Dépend de » : ce qui doit exister avant. « Utilisée par » : ce qui s'appuiera sur cette fonctionnalité plus tard.
- Quand un agent termine une fonctionnalité, il passe son statut à `faite` dans la même PR.
