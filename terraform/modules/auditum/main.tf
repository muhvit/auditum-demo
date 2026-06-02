locals {
  name = "auditum"

  labels = {
    "app.kubernetes.io/name"       = local.name
    "app.kubernetes.io/instance"   = local.name
    "app.kubernetes.io/managed-by" = "terraform"
    "app.kubernetes.io/part-of"    = "auditum-demo"
  }

  config_data = merge(
    {
      AUDITUM_log_format                     = "json"
      AUDITUM_log_level                      = "info"
      AUDITUM_http_port                      = tostring(var.http_port)
      AUDITUM_grpc_port                      = tostring(var.grpc_port)
      AUDITUM_store_type                     = var.store_type
      AUDITUM_settings_records_updateEnabled = tostring(var.record_update_enabled)
      AUDITUM_settings_records_deleteEnabled = tostring(var.record_delete_enabled)
    },
    var.store_type == "sqlite" ? {
      AUDITUM_store_sqlite_databasePath = var.sqlite_database_path
      } : {
      AUDITUM_store_postgres_host     = var.postgres_host
      AUDITUM_store_postgres_port     = tostring(var.postgres_port)
      AUDITUM_store_postgres_database = var.postgres_database
      AUDITUM_store_postgres_sslmode  = var.postgres_sslmode
    }
  )
}

resource "kubernetes_config_map_v1" "auditum_env" {
  metadata {
    name      = "${local.name}-env"
    namespace = var.namespace
    labels    = local.labels
  }

  data = local.config_data
}

resource "kubernetes_persistent_volume_claim_v1" "auditum_data" {
  count = var.store_type == "sqlite" ? 1 : 0

  # k3d's default local-path storage class uses WaitForFirstConsumer.
  # Terraform must not wait for the claim to bind before creating the pod,
  # or PVC binding and pod scheduling can deadlock each other.
  wait_until_bound = false

  metadata {
    name      = "${local.name}-data"
    namespace = var.namespace
    labels    = local.labels
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = var.sqlite_pvc_size
      }
    }

    storage_class_name = var.sqlite_storage_class_name
  }
}

resource "kubernetes_job_v1" "auditum_migrate" {
  count = var.run_postgres_migration ? 1 : 0

  wait_for_completion = true

  metadata {
    name      = "${local.name}-migrate"
    namespace = var.namespace
    labels    = local.labels
  }

  spec {
    backoff_limit              = 3
    ttl_seconds_after_finished = 300

    template {
      metadata {
        labels = local.labels
      }

      spec {
        restart_policy = "OnFailure"

        security_context {
          fs_group        = 65534
          run_as_group    = 65534
          run_as_non_root = true
          run_as_user     = 65534
        }

        container {
          name  = "auditum-migrate"
          image = "${var.image_repository}:${var.image_tag}"
          args  = ["migrate", "--config", "/opt/auditumio/auditum/auditum.yaml"]

          env_from {
            config_map_ref {
              name = kubernetes_config_map_v1.auditum_env.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = var.postgres_secret_name
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment_v1" "auditum" {
  metadata {
    name      = local.name
    namespace = var.namespace
    labels    = local.labels
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        "app.kubernetes.io/name"     = local.name
        "app.kubernetes.io/instance" = local.name
      }
    }

    template {
      metadata {
        labels = local.labels
      }

      spec {
        security_context {
          fs_group        = 65534
          run_as_group    = 65534
          run_as_non_root = true
          run_as_user     = 65534
        }

        dynamic "volume" {
          for_each = var.store_type == "sqlite" ? [1] : []

          content {
            name = "auditum-data"

            persistent_volume_claim {
              claim_name = kubernetes_persistent_volume_claim_v1.auditum_data[0].metadata[0].name
            }
          }
        }

        container {
          name  = local.name
          image = "${var.image_repository}:${var.image_tag}"
          args  = ["serve", "--config", "/opt/auditumio/auditum/auditum.yaml"]

          port {
            container_port = var.http_port
            name           = "http"
          }

          port {
            container_port = var.grpc_port
            name           = "grpc"
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map_v1.auditum_env.metadata[0].name
            }
          }

          dynamic "env_from" {
            for_each = var.store_type == "postgres" ? [1] : []

            content {
              secret_ref {
                name = var.postgres_secret_name
              }
            }
          }

          dynamic "volume_mount" {
            for_each = var.store_type == "sqlite" ? [1] : []

            content {
              name       = "auditum-data"
              mount_path = "/data"
            }
          }

          resources {
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }

            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
          }

          startup_probe {
            http_get {
              path = "/metrics"
              port = var.http_port
            }

            failure_threshold = 30
            period_seconds    = 5
            timeout_seconds   = 3
          }

          readiness_probe {
            http_get {
              path = "/metrics"
              port = var.http_port
            }

            initial_delay_seconds = 5
            period_seconds        = 10
            timeout_seconds       = 3
            failure_threshold     = 3
          }

          liveness_probe {
            http_get {
              path = "/metrics"
              port = var.http_port
            }

            initial_delay_seconds = 15
            period_seconds        = 20
            timeout_seconds       = 5
            failure_threshold     = 3
          }
        }
      }
    }
  }

  depends_on = [kubernetes_job_v1.auditum_migrate]
}

resource "kubernetes_service_v1" "auditum" {
  metadata {
    name      = local.name
    namespace = var.namespace
    labels    = local.labels
  }

  spec {
    selector = {
      "app.kubernetes.io/name"     = local.name
      "app.kubernetes.io/instance" = local.name
    }

    type = var.service_type

    port {
      name        = "http"
      port        = var.service_port
      target_port = var.http_port
      node_port   = var.service_type == "NodePort" ? var.node_port : null
      protocol    = "TCP"
    }
  }
}
