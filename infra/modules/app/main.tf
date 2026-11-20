# Dépôt d'images Docker
resource "google_artifact_registry_repository" "images" {
  project       = var.project_id
  location      = var.region
  repository_id = "app"
  format        = "DOCKER"
}

# Identité de l'application
resource "google_service_account" "runtime" {
  project      = var.project_id
  account_id   = "sa-app-runtime"
  display_name = "Runtime Cloud Run"
}

resource "google_project_iam_member" "runtime_sql" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.runtime.email}"
}

# Base de données PostgreSQL
resource "google_sql_database_instance" "db" {
  project             = var.project_id
  name                = "monapp-${var.env_name}-db"
  region              = var.region
  database_version    = "POSTGRES_16"
  deletion_protection = var.env_name == "prod"

  settings {
    tier = var.db_tier
    backup_configuration { enabled = true }
  }
}

resource "google_sql_database" "app" {
  project  = var.project_id
  name     = "app"
  instance = google_sql_database_instance.db.name
}

resource "random_password" "db" {
  length  = 32
  special = false
}

resource "google_sql_user" "app" {
  project  = var.project_id
  name     = "app"
  instance = google_sql_database_instance.db.name
  password = random_password.db.result
}

# Secret : mot de passe de la base
resource "google_secret_manager_secret" "db_password" {
  project   = var.project_id
  secret_id = "db-password"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db.result
}

resource "google_secret_manager_secret_iam_member" "runtime_reads_db" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.db_password.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.runtime.email}"
}

# Service Cloud Run
resource "google_cloud_run_v2_service" "app" {
  project             = var.project_id
  name                = "monapp"
  location            = var.region
  deletion_protection = var.env_name == "prod"

  template {
    service_account = google_service_account.runtime.email

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.db.connection_name]
      }
    }

    containers {
      # Image provisoire : le CI la remplacera à chaque déploiement
      image = "us-docker.pkg.dev/cloudrun/container/hello"

      ports { container_port = 8080 }

      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }

      env {
        name  = "ENV"
        value = var.env_name
      }
      env {
        name  = "DB_HOST"
        value = "/cloudsql/${google_sql_database_instance.db.connection_name}"
      }
      env {
        name = "DB_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.db_password.secret_id
            version = "latest"
          }
        }
      }
    }
  }

  # Important : Terraform ne doit pas écraser l'image déployée par le CI
  lifecycle {
    ignore_changes = [
      template[0].containers[0].image,
      client,
      client_version,
    ]
  }

  depends_on = [google_secret_manager_secret_iam_member.runtime_reads_db]
}

# Accès public (à restreindre en dev si tu veux le garder privé)
resource "google_cloud_run_v2_service_iam_member" "public" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.app.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
