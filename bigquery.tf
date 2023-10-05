resource "google_bigquery_dataset" "main_dataset" {
  dataset_id                  = "${var.project_name}_dataset"
  description                 = "Dataset for map ${var.project_name} project"
  location                    = "US"
  project                     = var.project_name
}

resource "google_bigquery_table" "sequences" {
  dataset_id = google_bigquery_dataset.main_dataset.dataset_id
  table_id   = "sequences"
  deletion_protection = false
  project                     = var.project_name
  schema = <<EOF
[
  {
    "name": "seq_name",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "sequence name"
  },
  {
    "name": "seq_value",
    "type": "INTEGER",
    "mode": "REQUIRED",
    "description": "sequence value"
  }
]
EOF
}

resource "google_bigquery_table" "<table_name>" {
  dataset_id = google_bigquery_dataset.main_dataset.dataset_id
  table_id   = "<table_name>"
  deletion_protection = false
  project                     = var.project_name
  schema = <<EOF
[
  {
    "name": "id",
    "type": "INTEGER",
    "mode": "REQUIRED",
    "description": "project id used to identify the project"
  }, 
  {
    "name": "LAST_UPDATE_DATETIME",
    "type": "DATETIME",
    "mode": "REQUIRED",
    "description": "Last update datetime of code"
  }
]
EOF
}

resource "google_bigquery_routine" "get_row_id" {
  dataset_id      = google_bigquery_dataset.main_dataset.dataset_id
  routine_id      = "get_row_id"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  project                     = var.project_name
  arguments {
    name = "sequence_name"
    data_type = "{\"typeKind\" :  \"STRING\"}"
  } 
  definition_body = templatefile("${path.module}/templates/get_row_id.template", { dataset = google_bigquery_dataset.main_dataset.dataset_id })
}