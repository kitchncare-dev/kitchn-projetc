# ---------------------------------------------------------------------------
# Pont Telegram -> GitHub (service Cloud Run "telegram-bridge"), projet dev uniquement.
# Code : ops/telegram-bridge. Image déployée par le workflow deploy-bridge.
#
# Les secrets sont créés ici VIDES (une valeur provisoire « A_REMPLACER ») :
# les vraies valeurs sont ajoutées à la main avec « gcloud secrets versions add »
# (voir ops/telegram-bridge/README.md). Elles n'apparaissent donc jamais dans l'état Terraform.
# ---------------------------------------------------------------------------

locals {
  secrets = {
    TELEGRAM_BOT_TOKEN      = "telegram-bot-token"
    TELEGRAM_WEBHOOK_SECRET = "telegram-webhook-secret"
    TELEGRAM_OWNER_ID       = "telegram-owner-id"
    GITHUB_TOKEN            = "telegram-bridge-github-token"
  }
}

# Identité du bridge : ne peut que lire ses 4 secrets
resource "google_service_account" "bridge" {
  project      = var.project_id
  account_id   = "sa-telegram-bridge"
  display_name = "Runtime Cloud Run - telegram-bridge"
}

resource "google_secret_manager_secret" "bridge" {
  for_each  = local.secrets
  project   = var.project_id
  secret_id = each.value

  replication {
    auto {}
  }
}

# Version provisoire, pour que Cloud Run puisse démarrer avant que tu saisisses les vraies valeurs.
# Terraform ne la modifie plus ensuite (ignore_changes).
resource "google_secret_manager_secret_version" "placeholder" {
  for_each    = google_secret_manager_secret.bridge
  secret      = each.value.id
  secret_data = each.key == "TELEGRAM_OWNER_ID" ? "0" : "A_REMPLACER"

  lifecycle {
    ignore_changes = [secret_data, enabled]
  }
}

resource "google_secret_manager_secret_iam_member" "bridge_reads" {
  for_each  = google_secret_manager_secret.bridge
  project   = var.project_id
  secret_id = each.value.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.bridge.email}"
}

resource "google_cloud_run_v2_service" "bridge" {
  project             = var.project_id
  name                = "telegram-bridge"
  location            = var.region
  deletion_protection = false

  template {
    service_account = google_service_account.bridge.email

    scaling {
      min_instance_count = 0
      max_instance_count = 1
    }

    containers {
      # Image provisoire : le workflow deploy-bridge la remplace
      image = "us-docker.pkg.dev/cloudrun/container/hello"
      ports { container_port = 8080 }

      env {
        name  = "GITHUB_REPO"
        value = var.github_repo
      }

      dynamic "env" {
        for_each = local.secrets
        content {
          name = env.key
          value_source {
            secret_key_ref {
              secret  = google_secret_manager_secret.bridge[env.key].secret_id
              version = "latest"
            }
          }
        }
      }
    }
  }

  # Terraform ne doit pas écraser l'image déployée par le workflow
  lifecycle {
    ignore_changes = [
      template[0].containers[0].image,
      client,
      client_version,
    ]
  }

  depends_on = [
    google_secret_manager_secret_iam_member.bridge_reads,
    google_secret_manager_secret_version.placeholder,
  ]
}

# Telegram doit pouvoir appeler le webhook sans compte Google.
# La protection est faite par le bridge : jeton secret du webhook + identifiant du propriétaire.
resource "google_cloud_run_v2_service_iam_member" "bridge_public" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.bridge.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Le compte de déploiement GitHub peut déployer le bridge avec son identité
resource "google_service_account_iam_member" "deploy_acts_as_bridge" {
  service_account_id = google_service_account.bridge.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${var.deploy_sa_email}"
}
