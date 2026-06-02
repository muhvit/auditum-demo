output "namespace" {
  description = "Namespace containing the demo resources."
  value       = kubernetes_namespace_v1.auditum_demo.metadata[0].name
}

output "service_name" {
  description = "Auditum service name."
  value       = module.auditum.service_name
}

output "service_type" {
  description = "Auditum service type."
  value       = module.auditum.service_type
}

output "node_port" {
  description = "Auditum NodePort when enabled."
  value       = module.auditum.node_port
}

output "postgres_service_name" {
  description = "PostgreSQL service name when deployed in-cluster."
  value       = local.use_postgres && var.create_postgres ? module.postgres[0].service_name : null
}
