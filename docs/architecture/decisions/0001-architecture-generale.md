# 0001 : Architecture générale

- **Date** : 2026-11
- **Statut** : acceptée

## Contexte
Application web développée en grande partie par des agents IA, par une équipe d'une personne, avec des coûts faibles et sans serveur à administrer.

## Décision
- **Cloud Run** pour l'API et le front (deux services `my-api` et `my-web-app`) : pas de serveur à gérer, facturation à l'usage.
- **FastAPI** (Python 3.12) pour l'API : simple, typé, tests faciles avec pytest.
- **Next.js 16** pour le front, appels à l'API uniquement côté serveur (`API_URL` jamais exposée au navigateur).
- **Cloud SQL PostgreSQL 16**, joignable seulement par l'API.
- **Deux projets Google Cloud** séparés (dev et prod), infrastructure en **Terraform** appliquée à la main.
- **GitHub Actions** pour la CI, le déploiement et les agents ; authentification vers Google Cloud par **Workload Identity Federation** (aucune clé).
- Les agents n'ont **aucun accès** à Google Cloud ; la production exige une approbation humaine.

## Conséquences
- Le déploiement passe toujours par `deploy.yml`, jamais par un agent.
- Kubernetes et les runners auto-hébergés ne sont envisagés que si un besoin réel apparaît.

## Modèle pour les décisions suivantes
Copier ce fichier sous `000N-<titre>.md` avec les rubriques Contexte, Décision, Conséquences.
