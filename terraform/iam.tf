# SA para GitHub Actions
resource "google_service_account" "github_ci" {
  account_id   = "github-ci"
  display_name = "GitHub Actions Service Account"
}

# Permiso para impresionate
resource "google_service_account_iam_member" "wif_user" {
  service_account_id = google_service_account.github_ci.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_actions_pool.name}/attribute.repository/cristopherpds/tcc-ops"
}

# Permisos para GKE y Kubernetes
resource "google_project_iam_member" "gke_developer" {
  project = var.project_id
  role    = "roles/container.developer"
  member  = "serviceAccount:${google_service_account.github_ci.email}"
}