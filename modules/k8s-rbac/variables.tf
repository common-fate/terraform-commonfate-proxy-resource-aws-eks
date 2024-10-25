variable "cluster_name" {
  description = "The name of the cluster."
  type        = string
}

variable "create_default_rbac_roles" {
  description = "If 'true', will create default admin and read_only k8s rbac roles that allow the default Common Fate impersonate user roles to access the cluster."
  type        = bool
  default     = false
}
