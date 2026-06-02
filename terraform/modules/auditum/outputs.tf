output "service_name" {
  value = kubernetes_service_v1.auditum.metadata[0].name
}

output "service_type" {
  value = kubernetes_service_v1.auditum.spec[0].type
}

output "node_port" {
  value = var.service_type == "NodePort" ? var.node_port : null
}
