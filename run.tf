data "google_compute_default_service_account" "default" {
  project = var.project_id

  depends_on = [ google_project_service.project_service ]
}

resource "google_project_iam_member" "registry_permissions" {
  project = var.common_project_id
  role   = "roles/composer.environmentAndStorageObjectViewer"
  member  = "serviceAccount:service-${google_project.project.number}@serverless-robot-prod.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "secret_manager_grant" {
  project = var.common_project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}

resource "google_cloud_run_v2_service" "<name>-data-svc" {
  name     = "<name>-data-svc"
  location = var.region
  ingress = "INGRESS_TRAFFIC_ALL"
  project = var.project_id

  template {
    volumes {
      name = "a-volume"
      secret {
        secret = var.bigquery_secret
        default_mode = 292 # 0444
        items {
          version = "1"
          path = "google.key"
        }
      }
    }
    containers {
      image = "gcr.io/${var.common_project_id}/<name>-data-svc:latest"

      env {
        name = "SECRET_KEY"
        value = var.python_session_secret
      }

      env {
        name = "PROJECT_ID"
        value = var.project_id
      }

      env {
        name = "DATASET_NAME"
        value = "${var.project_name}_dataset"
      }

      volume_mounts {
        name = "a-volume"
        mount_path = "/secrets"
      }
    }
  }
}

resource "google_cloud_run_v2_service" "<name>-ol-svc" {
  name     = "<name>-ol-svc"
  location = var.region
  ingress = "INGRESS_TRAFFIC_ALL"
  project = var.project_id

  template {
    containers {
      image = "gcr.io/${var.common_project_id}/<name>-ol-svc:latest"

      env {
        name = "SECRET_KEY"
        value = var.python_session_secret
      }

      env {
        name = "PROJECT_ID"
        value = var.project_id
      }

      env {
        name = "DATASET_NAME"
        value = "${var.project_name}_dataset"
      }

      env {
        name = "DATA_LAYER_URL"
        value = "${google_cloud_run_v2_service.<name>-data-svc.uri}/${var.project_id}"
      }

      env {
        name = "OL_LAYER_URL"
        value = "${google_cloud_run_v2_service.<name>.uri}/${var.project_id}"
      }

      env {
        name = "AUDIENCE"
        value = var.audience
      }
    }
  }
}

data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  location    = google_cloud_run_v2_service.<name>-ol-svc.location
  project     = google_cloud_run_v2_service.<name>-ol-svc.project
  service     = google_cloud_run_v2_service.<name>-ol-svc.name

  policy_data = data.google_iam_policy.noauth.policy_data
}