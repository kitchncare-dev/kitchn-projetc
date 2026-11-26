# Base de connaissance du projet

Ce dossier décrit le projet dans son ensemble : ce qu'on construit, pour qui, quelles fonctionnalités existent ou sont prévues, et comment elles dépendent les unes des autres.
Les agents IA le lisent avant de planifier ou de coder, pour qu'en développant une fonctionnalité A ils prévoient ce dont la fonctionnalité B aura besoin (données, routes, écrans), **sans développer B à l'avance**.

## Sommaire

| Dossier / fichier | Contenu | Qui le modifie |
|---|---|---|
| `produit/vision.md` | Problème résolu, public cible, proposition de valeur | **Humain uniquement** |
| `produit/personas.md` | Utilisateurs types et leurs besoins | **Humain uniquement** |
| `produit/glossaire.md` | Termes métier et leur nom dans le code | **Humain uniquement** |
| `fonctionnalites/carte.md` | Liste de toutes les fonctionnalités, statut, dépendances, ordre | Humain, agents (statut) |
| `fonctionnalites/_modele.md` | Modèle à copier pour chaque fiche de fonctionnalité | Humain |
| `fonctionnalites/<code>-<nom>.md` | Une fiche par fonctionnalité | Humain, agents |
| `architecture/modele-donnees.md` | Tables et relations, actuelles et prévues | Humain, agents |
| `architecture/api.md` | Conventions des routes de l'API | Humain, agents |
| `architecture/decisions/` | Un fichier par décision importante (ADR) | Humain, agents (sur proposition) |

## Règles de mise à jour

1. **`produit/` est réservé à l'humain.** Les agents n'ont pas le droit d'y écrire (bloqué dans `.claude/settings.json`). S'ils constatent une incohérence, ils la signalent dans la PR.
2. **Une PR qui change le comportement met à jour la doc dans la même PR** : fiche de la fonctionnalité (statut, routes, données), `carte.md` (statut), `modele-donnees.md` si le schéma change, `api.md` si une convention change.
3. Le relecteur vérifie que la doc est à jour et cohérente avec le code.
4. Les fiches suivent **toujours** le modèle `fonctionnalites/_modele.md`.
5. Une information n'est écrite qu'à un seul endroit : les autres fichiers y font référence par un lien.
6. Statuts possibles d'une fonctionnalité : `prévue`, `en cours`, `faite`, `abandonnée`.

## Ordre de lecture pour un agent

1. Ce fichier.
2. `fonctionnalites/carte.md`.
3. La fiche de la fonctionnalité concernée par l'issue, puis celles des fonctionnalités qui **dépendent** d'elle (colonne « Utilisée par »).
4. `architecture/modele-donnees.md` et `architecture/api.md` si la tâche touche la base ou l'API.
5. `produit/glossaire.md` pour nommer correctement les choses dans le code.
