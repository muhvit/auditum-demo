locals {
  use_postgres              = var.store_type == "postgres"
  generated_postgres_secret = local.use_postgres && var.create_postgres ? module.postgres[0].secret_name : var.postgres_secret_name
  generated_postgres_host   = local.use_postgres && var.create_postgres ? module.postgres[0].service_name : var.postgres_host
}

resource "kubernetes_namespace_v1" "auditum_demo" {
  metadata {
    name = var.namespace

    labels = {
      "app.kubernetes.io/part-of" = "auditum-demo"
    }
  }
}

resource "random_password" "postgres" {
  count = local.use_postgres && var.create_postgres && var.postgres_password == null ? 1 : 0

  length  = 24
  special = false
}

module "postgres" {
  count  = local.use_postgres && var.create_postgres ? 1 : 0
  source = "./modules/postgres"

  namespace          = kubernetes_namespace_v1.auditum_demo.metadata[0].name
  image              = var.postgres_image
  database           = var.postgres_database
  username           = var.postgres_username
  password           = coalesce(var.postgres_password, random_password.postgres[0].result)
  storage_size       = var.postgres_storage_size
  storage_class_name = var.postgres_storage_class_name

  depends_on = [kubernetes_namespace_v1.auditum_demo]
}

module "auditum" {
  source = "./modules/auditum"

  namespace                 = kubernetes_namespace_v1.auditum_demo.metadata[0].name
  image_repository          = var.auditum_image_repository
  image_tag                 = var.auditum_image_tag
  http_port                 = var.http_port
  grpc_port                 = var.grpc_port
  service_port              = var.service_port
  service_type              = var.service_type
  node_port                 = var.node_port
  store_type                = var.store_type
  sqlite_database_path      = var.sqlite_database_path
  sqlite_pvc_size           = var.sqlite_pvc_size
  sqlite_storage_class_name = var.sqlite_storage_class_name
  postgres_host             = local.generated_postgres_host
  postgres_port             = var.postgres_port
  postgres_database         = var.postgres_database
  postgres_sslmode          = var.postgres_sslmode
  postgres_secret_name      = local.generated_postgres_secret
  run_postgres_migration    = local.use_postgres
  record_update_enabled     = var.record_update_enabled
  record_delete_enabled     = var.record_delete_enabled
}
