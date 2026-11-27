terraform {
  required_version = ">= 1.6"
  required_providers {
    google = { source = "hashicorp/google", version = "~> 6.0" }
    random = { source = "hashicorp/random", version = "~> 3.6" }
  }
  backend "gcs" {
    bucket = "kitchn-dev-tfstate"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = "kitchn-dev-515310"
  region  = "europe-west9"
}

module "app" {
  source        = "../../modules/app"
  project_id    = "kitchn-dev-515310"
  region        = "europe-west9"
  env_name      = "dev"
  db_tier       = "db-f1-micro"
  min_instances = 0
  max_instances = 3
}

module "github_deploy" {
  source           = "../../modules/github-deploy"
  project_id       = "kitchn-dev-515310"
  region           = "europe-west9"
  env_name         = "dev"
  github_repo      = "kitchncare-dev/kitchn-projetc"
  github_subject_repo = "kitchncare-dev@359126054/kitchn-projetc@1465363100"
  runtime_sa_email = module.app.runtime_sa_email
  web_runtime_sa_email = module.app.web_runtime_sa_email
  artifact_repo_id = module.app.artifact_repo_id
}

# Pont Telegram -> GitHub (dev uniquement), voir ops/telegram-bridge/README.md
module "telegram_bridge" {
  source          = "../../modules/telegram-bridge"
  project_id      = "kitchn-dev-515310"
  region          = "europe-west9"
  github_repo     = "kitchncare-dev/kitchn-projetc"
  deploy_sa_email = module.github_deploy.deploy_service_account
}

output "wif_provider" {
  value = module.github_deploy.workload_identity_provider
}
output "deploy_sa" {
  value = module.github_deploy.deploy_service_account
}
output "api_url" {
  value = module.app.api_url
}
output "web_url" {
  value = module.app.web_url
}
output "telegram_bridge_url" {
  value = module.telegram_bridge.bridge_url
}
