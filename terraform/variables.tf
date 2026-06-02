variable "kubeconfig_path" {
  description = "Path to the kubeconfig file Terraform should use."
  type        = string
}

variable "kubeconfig_context" {
  description = "Kubernetes context name Terraform should use."
  type        = string
}

variable "namespace" {
  description = "Namespace to deploy the demo into."
  type        = string
  default     = "auditum-demo"
}

variable "auditum_image_repository" {
  description = "Auditum image repository."
  type        = string
  default     = "auditumio/auditum"
}

variable "auditum_image_tag" {
  description = "Auditum image tag."
  type        = string
  default     = "0.3.0"
}

variable "http_port" {
  description = "Auditum HTTP port."
  type        = number
  default     = 8080
}

variable "grpc_port" {
  description = "Auditum gRPC port."
  type        = number
  default     = 9090
}

variable "service_port" {
  description = "Service port that exposes the Auditum HTTP API."
  type        = number
  default     = 8080
}

variable "service_type" {
  description = "Kubernetes service type for Auditum."
  type        = string
  default     = "ClusterIP"

  validation {
    condition     = contains(["ClusterIP", "NodePort"], var.service_type)
    error_message = "service_type must be ClusterIP or NodePort."
  }
}

variable "node_port" {
  description = "NodePort value to use when service_type is NodePort."
  type        = number
  default     = 30080
}

variable "store_type" {
  description = "Auditum backing store type."
  type        = string
  default     = "sqlite"

  validation {
    condition     = contains(["sqlite", "postgres"], var.store_type)
    error_message = "store_type must be sqlite or postgres."
  }
}

variable "sqlite_database_path" {
  description = "Path to the SQLite database inside the Auditum container."
  type        = string
  default     = "/data/auditum.db"
}

variable "sqlite_pvc_size" {
  description = "Requested PVC size for SQLite persistence."
  type        = string
  default     = "1Gi"
}

variable "sqlite_storage_class_name" {
  description = "Optional storage class for the SQLite PVC."
  type        = string
  default     = null
  nullable    = true
}

variable "create_postgres" {
  description = "Whether to deploy PostgreSQL in-cluster."
  type        = bool
  default     = false
}

variable "postgres_host" {
  description = "Existing PostgreSQL hostname when create_postgres is false."
  type        = string
  default     = null
  nullable    = true
}

variable "postgres_port" {
  description = "PostgreSQL port."
  type        = number
  default     = 5432
}

variable "postgres_database" {
  description = "PostgreSQL database name."
  type        = string
  default     = "auditum_db"
}

variable "postgres_username" {
  description = "PostgreSQL username."
  type        = string
  default     = "auditum_user"
}

variable "postgres_password" {
  description = "Optional PostgreSQL password. If omitted and create_postgres is true, one is generated."
  type        = string
  default     = null
  nullable    = true
  sensitive   = true
}

variable "postgres_secret_name" {
  description = "Existing secret name containing Auditum PostgreSQL credentials when create_postgres is false."
  type        = string
  default     = null
  nullable    = true
}

variable "postgres_sslmode" {
  description = "Auditum PostgreSQL SSL mode."
  type        = string
  default     = "disable"
}

variable "postgres_image" {
  description = "PostgreSQL image."
  type        = string
  default     = "postgres:14-alpine"
}

variable "postgres_storage_size" {
  description = "Requested PVC size for PostgreSQL."
  type        = string
  default     = "5Gi"
}

variable "postgres_storage_class_name" {
  description = "Optional storage class for the PostgreSQL PVC."
  type        = string
  default     = null
  nullable    = true
}

variable "record_update_enabled" {
  description = "Whether Auditum update-record support is enabled."
  type        = bool
  default     = false
}

variable "record_delete_enabled" {
  description = "Whether Auditum delete-record support is enabled."
  type        = bool
  default     = false
}
