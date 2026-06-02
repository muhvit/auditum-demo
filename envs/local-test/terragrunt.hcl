include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../terraform"
}

inputs = {
  kubeconfig_path    = get_env("AUDITUM_LOCAL_TEST_KUBECONFIG", "~/.kube/config")
  kubeconfig_context = get_env("AUDITUM_LOCAL_TEST_KUBECONTEXT", "microk8s")

  # The shared VM target prefers a simple persistent database.
  service_type                = "NodePort"
  node_port                   = 30080
  store_type                  = "postgres"
  create_postgres             = true
  postgres_storage_size       = "5Gi"
  postgres_storage_class_name = "microk8s-hostpath"
}
