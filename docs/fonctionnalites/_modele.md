# F<XX> : <Nom de la fonctionnalité>

> Copier ce fichier sous le nom `F<XX>-<nom-court>.md` et remplir toutes les rubriques.
> Une rubrique sans objet contient « Aucun », jamais vide.

- **Statut** : prévue | en cours | faite | abandonnée
- **Issue(s)** : #<numéro>
- **Dépend de** : F<YY>, …
- **Utilisée par / prévue pour** : F<ZZ>, … (ce que ces fonctionnalités attendront de celle-ci)

## Objectif
<Ce que l'utilisateur peut faire grâce à cette fonctionnalité, en 2 ou 3 phrases.>

## Règles métier
- <Règle 1, précise et vérifiable>

## Données concernées
<Tables et colonnes lues ou écrites. Renvoyer vers `../architecture/modele-donnees.md`.>

## Routes API
| Méthode | Route | Rôle | Statut |
|---|---|---|---|
| GET | `/exemple` | <rôle> | prévue |

## Écrans
| Écran | Route du front | États gérés (chargement, vide, erreur, succès) |
|---|---|---|
| <nom> | `/exemple` | <oui / à faire> |

## Critères d'acceptation
- [ ] <Critère vérifiable par un test ou une manipulation>

## Ce qu'il faut prévoir pour les fonctionnalités liées
<Par exemple : « F03 aura besoin d'un champ `owner_id` : le créer maintenant, nullable ». Ne pas développer F03.>
