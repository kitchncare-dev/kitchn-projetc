output "runtime_sa_email" {
  value = google_service_account.runtime.email
}

output "web_runtime_sa_email" {
  value = google_service_account.web_runtime.email
}

output "artifact_repo_id" {
  value = google_artifact_registry_repository.images.repository_id
}

output "api_url" {
  value = google_cloud_run_v2_service.my_api.uri
}

output "web_url" {
  value = google_cloud_run_v2_service.my_web_app.uri
}
