data "google_project" "this" {
  project_id = var.project_id
}

# Le "guichet" qui accepte les jetons GitHub
resource "google_iam_workload_identity_pool" "github" {
  project                   = var.project_id
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Actions"
}

resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub OIDC"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
  }

  # Seul ton dépôt est accepté, aucun autre dépôt GitHub
  attribute_condition = "assertion.repository == \"${var.github_repo}\""

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Le compte de service de déploiement
resource "google_service_account" "deploy" {
  project      = var.project_id
  account_id   = "sa-deploy-${var.env_name}"
  display_name = "Déploiement GitHub Actions (${var.env_name})"
}

# Qui peut l'endosser : uniquement un job de TON dépôt
# qui tourne dans l'environnement GitHub du même nom (dev ou prod)
resource "google_service_account_iam_member" "github_impersonation" {
  service_account_id = google_service_account.deploy.name
  role               = "roles/iam.workloadIdentityUser"
    member             = "principal://iam.googleapis.com/projects/${data.google_project.this.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.github.workload_identity_pool_id}/subject/repo:${var.github_subject_repo}:environment:${var.env_name}"
}

# Ce que ce compte a le droit de faire : le strict minimum
resource "google_project_iam_member" "deploy_run" {
  project = var.project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${google_service_account.deploy.email}"
}

resource "google_service_account_iam_member" "act_as_runtime" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${var.runtime_sa_email}"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.deploy.email}"
}

resource "google_artifact_registry_repository_iam_member" "push" {
  project    = var.project_id
  location   = var.region
  repository = var.artifact_repo_id
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.deploy.email}"
}
