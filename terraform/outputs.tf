output "wif_pool_id" {
  value = google_iam_workload_identity_pool.github_actions_pool.workload_identity_pool_id
}

output "wif_provider_id" {
  value = google_iam_workload_identity_pool_provider.github_provider.workload_identity_pool_provider_id
}

output "github_ci_sa" {
  value = google_service_account.github_ci.email
}