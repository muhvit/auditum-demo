variable "namespace" {
  type = string
}

variable "image_repository" {
  type = string
}

variable "image_tag" {
  type = string
}

variable "http_port" {
  type = number
}

variable "grpc_port" {
  type = number
}

variable "service_port" {
  type = number
}

variable "service_type" {
  type = string
}

variable "node_port" {
  type = number
}

variable "store_type" {
  type = string
}

variable "sqlite_database_path" {
  type = string
}

variable "sqlite_pvc_size" {
  type = string
}

variable "sqlite_storage_class_name" {
  type     = string
  default  = null
  nullable = true
}

variable "postgres_host" {
  type     = string
  default  = null
  nullable = true
}

variable "postgres_port" {
  type = number
}

variable "postgres_database" {
  type = string
}

variable "postgres_sslmode" {
  type = string
}

variable "postgres_secret_name" {
  type     = string
  default  = null
  nullable = true
}

variable "run_postgres_migration" {
  type = bool
}

variable "record_update_enabled" {
  type = bool
}

variable "record_delete_enabled" {
  type = bool
}
