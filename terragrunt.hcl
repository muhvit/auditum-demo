locals {
  auditum_image_repository = "auditumio/auditum"
  auditum_image_tag        = "0.3.0"
}

remote_state {
  backend = "local"

  config = {
    path = "${get_terragrunt_dir()}/terraform.tfstate"
  }

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

inputs = {
  namespace                = "auditum-demo"
  auditum_image_repository = local.auditum_image_repository
  auditum_image_tag        = local.auditum_image_tag
  http_port                = 8080
  grpc_port                = 9090
  service_port             = 8080
  record_update_enabled    = false
  record_delete_enabled    = false
}
