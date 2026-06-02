locals {
  dev_no_proxy_suffix = "localhost,127.0.0.1,::1,host.docker.internal,kubernetes.docker.internal"
  dev_no_proxy        = get_env("NO_PROXY", "") != "" ? "${get_env("NO_PROXY", "")},${local.dev_no_proxy_suffix}" : local.dev_no_proxy_suffix
}

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../terraform"

  extra_arguments "k3d_local_api_access" {
    commands = ["init", "validate", "plan", "apply", "destroy", "refresh", "import", "output"]

    env_vars = {
      HTTP_PROXY  = ""
      HTTPS_PROXY = ""
      http_proxy  = ""
      https_proxy = ""
      NO_PROXY    = local.dev_no_proxy
      no_proxy    = local.dev_no_proxy
    }
  }
}

inputs = {
  kubeconfig_path    = get_env("AUDITUM_DEV_KUBECONFIG", "~/.kube/config")
  kubeconfig_context = get_env("AUDITUM_DEV_KUBECONTEXT", "k3d-auditum-dev")

  # The dev target keeps the stack intentionally lightweight.
  service_type              = "ClusterIP"
  node_port                 = 30080
  store_type                = "sqlite"
  sqlite_database_path      = "/data/auditum.db"
  sqlite_pvc_size           = "1Gi"
  sqlite_storage_class_name = "local-path"

  create_postgres = false
}
