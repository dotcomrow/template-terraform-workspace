provider "google" {
  project = var.project
  region  = var.region
  credentials = file(var.credentials_file) 
}

resource "google_project" "project" {
  name       = "${var.project_name}"
  project_id = "${var.project_name}"
  org_id     = "${var.gcp_org_id}"
}

resource "google_project_service" "project_service" {
  count = length(var.apis)

  disable_dependent_services = true
  project = google_project.project.project_id
  service = var.apis[count.index]
}