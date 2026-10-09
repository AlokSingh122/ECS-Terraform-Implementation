variable "name" {
  type = string
}

variable "cluster_arn" {
  type = string
}

variable "task_execution_role_arn" {
  type = string
}

variable "capacity_provider_name" {
  type = string
}

variable "frontend_image" {
  type = string
}

variable "backend_image" {
  type = string
}

variable "backend_url" {
  type = string
}