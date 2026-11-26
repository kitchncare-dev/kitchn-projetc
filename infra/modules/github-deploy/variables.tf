variable "project_id"           { type = string }
variable "region"               { type = string }
variable "env_name"             { type = string }
variable "github_repo"          { type = string }
variable "runtime_sa_email"     { type = string }
variable "web_runtime_sa_email" { type = string }
variable "artifact_repo_id"     { type = string }
variable "github_subject_repo" {
  type        = string
  description = "Partie du sub OIDC entre 'repo:' et ':environment:', ex. org@ID/repo@ID"
}
