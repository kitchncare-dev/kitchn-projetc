output "runtime_sa_email" {
  value = google_service_account.runtime.email
}

output "artifact_repo_id" {
  value = google_artifact_registry_repository.images.repository_id
}