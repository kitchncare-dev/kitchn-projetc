# Dépôt d'images Docker (les images "api" et "web" y sont publiées par le CI)
resource "google_artifact_registry_repository" "images" {
  project       = var.project_id
  location      = var.region
  repository_id = "app"
  format        = "DOCKER"
}

# Identité de l'API (a le droit de joindre Cloud SQL et de lire le mot de passe de la base)
resource "google_service_account" "runtime" {
  project      = var.project_id
  account_id   = "sa-app-runtime"
  display_name = "Runtime Cloud Run"
}

# Identité du front web (aucun droit : il n'accède ni à la base ni aux secrets)
resource "google_service_account" "web_runtime" {
  project      = var.project_id
  account_id   = "sa-web-runtime"
  display_name = "Runtime Cloud Run - web"
}

resource "google_project_iam_member" "runtime_sql" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.runtime.email}"
}


resource "google_sql_database_instance" "db" {
  project             = var.project_id
  name                = "monapp-${var.env_name}-db"
  region              = var.region
  database_version    = "POSTGRES_16"
  deletion_protection = var.env_name == "prod"

  settings {
    edition = "ENTERPRISE"
    tier    = var.db_tier
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

# ---------------------------------------------------------------------------
# Service Cloud Run : API (nom Cloud Run "my-api")
# Attention : un nom de service Cloud Run n'accepte pas "_", seulement
# minuscules, chiffres et tirets. Le nom Terraform (my_api) peut en contenir.
# ---------------------------------------------------------------------------
resource "google_cloud_run_v2_service" "my_api" {
  project             = var.project_id
  name                = "my-api"
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

# ---------------------------------------------------------------------------
# Service Cloud Run : front web (nom Cloud Run "my-web-app")
# ---------------------------------------------------------------------------
resource "google_cloud_run_v2_service" "my_web_app" {
  project             = var.project_id
  name                = "my-web-app"
  location            = var.region
  deletion_protection = var.env_name == "prod"

  template {
    service_account = google_service_account.web_runtime.email

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    containers {
      # Image provisoire : le CI la remplacera à chaque déploiement
      image = "us-docker.pkg.dev/cloudrun/container/hello"

      ports { container_port = 8080 }

      env {
        name  = "ENV"
        value = var.env_name
      }
      # Adresse de l'API, lue par le front côté serveur (process.env.API_URL)
      env {
        name  = "API_URL"
        value = google_cloud_run_v2_service.my_api.uri
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
}

# Accès public aux deux services (à restreindre plus tard si besoin)
resource "google_cloud_run_v2_service_iam_member" "api_public" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.my_api.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_v2_service_iam_member" "web_public" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.my_web_app.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
