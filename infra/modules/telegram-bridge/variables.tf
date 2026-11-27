variable "project_id" { type = string }
variable "region" { type = string }

variable "github_repo" {
  description = "Dépôt GitHub sur lequel le bridge crée les issues (propriétaire/nom)"
  type        = string
}

variable "deploy_sa_email" {
  description = "Compte de service de déploiement GitHub (sa-deploy-dev), autorisé à déployer le bridge"
  type        = string
}
