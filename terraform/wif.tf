# Pool
resource "google_iam_workload_identity_pool" "github_actions_pool" {
  provider                  = google
  workload_identity_pool_id = "github-actions-pool"
  display_name              = "GitHub Actions OIDC Pool"
  description               = "Pool for GitHub Actions OIDC"
}

# Provider
resource "google_iam_workload_identity_pool_provider" "github_provider" {
  provider = google

  workload_identity_pool_id          = google_iam_workload_identity_pool.github_actions_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"

  display_name = "GitHub Actions Provider"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  attribute_condition = "assertion.repository == 'cristopherpds/tcc-ops'"

  attribute_mapping = {
    "google.subject"     = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"      = "assertion.ref"
    "attribute.actor"    = "assertion.actor"
  }
}