locals {
  lookup_codes_ol_svc_name = "lookup-codes-ol-svc"
}

data "external" "lookup-codes-ol-svc-image-sha" {
  program = ["${path.module}/scripts/get-image-sha.sh","${local.lookup_codes_ol_svc_name}","${var.common_project_id}"]
}

resource "google_cloud_run_v2_service" "lookup-codes-ol-svc" {
  name     = local.lookup_codes_ol_svc_name
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
      image = "gcr.io/${var.common_project_id}/${local.lookup_codes_ol_svc_name}@${data.external.lookup-codes-ol-svc-image-sha.result["sha"]}"

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
        value = "${google_cloud_run_v2_service.lookup-codes-data-svc.uri}/${var.project_id}"
      }

      env {
        name = "AUDIENCE"
        value = var.audience
      }

      env {
        name = "REGION"
        value = var.region
      }

      env {
        name = "CONFIG_SECURITY_GROUP"
        value = var.config_security_group
      }

      env {
        name = "CONTEXT_ROOT"
        value = local.lookup_codes_ol_svc_name
      }

      volume_mounts {
        name = "a-volume"
        mount_path = "/secrets"
      }
    }
  }

  depends_on = [ google_project_iam_member.artifact_permissions, google_project_iam_member.registry_permissions, google_project_iam_member.secret_manager_grant ]
}

resource "cloudflare_workers_kv" "entry-lookup_codes" {
  account_id   = var.cloudflare_account_id
  namespace_id = var.cloudflare_worker_namespace_id
  key          =  "${google_cloud_run_v2_service.lookup-codes-ol-svc.name}"
  value        = "${google_cloud_run_v2_service.lookup-codes-ol-svc.uri}/${local.lookup_codes_ol_svc_name}"
}

resource "google_cloud_run_service_iam_policy" "noauth-lookup_codes" {
  location    = google_cloud_run_v2_service.lookup-codes-ol-svc.location
  project     = google_cloud_run_v2_service.lookup-codes-ol-svc.project
  service     = google_cloud_run_v2_service.lookup-codes-ol-svc.name

  policy_data = data.google_iam_policy.noauth.policy_data
}