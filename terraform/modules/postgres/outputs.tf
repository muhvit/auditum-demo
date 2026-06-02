output "service_name" {
  value = kubernetes_service_v1.postgres.metadata[0].name
}

output "secret_name" {
  value = kubernetes_secret_v1.postgres_auth.metadata[0].name
}
