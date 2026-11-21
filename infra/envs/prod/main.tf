terraform {
  required_version = ">= 1.6"
  required_providers {
    google = { source = "hashicorp/google", version = "~> 6.0" }
    random = { source = "hashicorp/random", version = "~> 3.6" }
  }
  backend "gcs" {
    bucket = "kitchn-prod-tfstate"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = "kitchn-prod-515310"
  region  = "europe-west9"
}

module "app" {
  source        = "../../modules/app"
  project_id    = "kitchn-prod-515310"
  region        = "europe-west9"
  env_name      = "prod"
  db_tier       = "db-f1-micro"
  min_instances = 1
  max_instances = 3
}
