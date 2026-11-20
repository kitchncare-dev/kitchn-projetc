terraform {
  required_version = ">= 1.6"
  required_providers {
    google = { source = "hashicorp/google", version = "~> 6.0" }
    random = { source = "hashicorp/random", version = "~> 3.6" }
  }
  backend "gcs" {
    bucket = "monapp-dev-tfstate"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = "ID_PROJET_DEV"
  region  = "europe-west9"
}

module "app" {
  source        = "../../modules/app"
  project_id    = "ID_PROJET_DEV"
  region        = "europe-west9"
  env_name      = "dev"
  db_tier       = "db-f1-micro"
  min_instances = 0
  max_instances = 3
}
