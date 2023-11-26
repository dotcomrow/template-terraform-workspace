locals {
  svc_name = "svc"
}

data "external" "svc-image-sha" {
  program = ["${path.module}/scripts/get-image-sha.sh","${local.svc_name}","${var.common_project_id}"]
}

resource "google_cloud_run_v2_service" "svc" {
  name     = local.svc_name
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
      image = "gcr.io/${var.common_project_id}/${local.svc_name}@${data.external.svc-image-sha.result["sha"]}"

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

  depends_on = [ google_project_iam_member.artifact_permissions, google_project_iam_member.registry_permissions, google_project_iam_member.secret_manager_grant ]
}
