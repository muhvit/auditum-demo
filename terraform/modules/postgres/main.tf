locals {
  name = "auditum-postgres"

  labels = {
    "app.kubernetes.io/name"       = local.name
    "app.kubernetes.io/instance"   = local.name
    "app.kubernetes.io/managed-by" = "terraform"
    "app.kubernetes.io/part-of"    = "auditum-demo"
  }
}

resource "kubernetes_secret_v1" "postgres_auth" {
  metadata {
    name      = "${local.name}-auth"
    namespace = var.namespace
    labels    = local.labels
  }

  data = {
    POSTGRES_DB                     = var.database
    POSTGRES_USER                   = var.username
    POSTGRES_PASSWORD               = var.password
    AUDITUM_store_postgres_username = var.username
    AUDITUM_store_postgres_password = var.password
  }

  type = "Opaque"
}

resource "kubernetes_persistent_volume_claim_v1" "postgres_data" {
  # Some local storage classes bind only after a pod is scheduled.
  # Avoid waiting on the claim before the consuming pod exists.
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
        storage = var.storage_size
      }
    }

    storage_class_name = var.storage_class_name
  }
}

resource "kubernetes_deployment_v1" "postgres" {
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
        volume {
          name = "postgres-data"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.postgres_data.metadata[0].name
          }
        }

        container {
          name  = "postgres"
          image = var.image

          port {
            container_port = 5432
            name           = "postgres"
          }

          env_from {
            secret_ref {
              name = kubernetes_secret_v1.postgres_auth.metadata[0].name
            }
          }

          env {
            name  = "PGDATA"
            value = "/var/lib/postgresql/data/pgdata"
          }

          volume_mount {
            name       = "postgres-data"
            mount_path = "/var/lib/postgresql/data"
          }

          resources {
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }

            requests = {
              cpu    = "100m"
              memory = "256Mi"
            }
          }

          readiness_probe {
            exec {
              command = ["pg_isready", "-U", var.username, "-d", var.database]
            }

            initial_delay_seconds = 5
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 6
          }

          liveness_probe {
            exec {
              command = ["pg_isready", "-U", var.username, "-d", var.database]
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
}

resource "kubernetes_service_v1" "postgres" {
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

    port {
      name        = "postgres"
      port        = 5432
      target_port = 5432
      protocol    = "TCP"
    }
  }
}
