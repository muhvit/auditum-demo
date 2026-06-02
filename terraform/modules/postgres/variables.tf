variable "namespace" {
  type = string
}

variable "image" {
  type = string
}

variable "database" {
  type = string
}

variable "username" {
  type = string
}

variable "password" {
  type      = string
  sensitive = true
}

variable "storage_size" {
  type = string
}

variable "storage_class_name" {
  type     = string
  default  = null
  nullable = true
}
