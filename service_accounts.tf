resource "google_service_account" "service_account" {
  account_id   = "${var.project_name}-cicd"
  project      = "${var.project_name}"
  display_name = "${var.project_name} GitHub Actions Service Account"
}

resource "google_project_iam_binding" "service_account_iam" {
  project = "${var.project_name}"
  role    = "roles/editor"
  members = [
    "serviceAccount:${google_service_account.service_account.email}"
  ]
}