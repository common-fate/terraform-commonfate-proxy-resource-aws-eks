variable "namespace" {
  description = "Specifies the namespace for the deployment."
  default     = "common-fate"
  type        = string
}

variable "stage" {
  description = "Determines the deployment stage (e.g., 'dev', 'staging', 'prod')."
  default     = "prod"
  type        = string
}

variable "proxy_id" {
  description = "The ID of the Common Fate AWS RDS Proxy e.g prod-us-west-2. The proxy is deployed seperately, it must exist before you register a database using this module."
  type        = string
}

variable "app_url" {
  description = "The app url (e.g., 'https://common-fate.mydomain.com')."
  type        = string

  validation {
    condition     = can(regex("^https://", var.app_url))
    error_message = "The app_url must start with 'https://'."
  }
}

variable "cluster_name" {
  description = "The name of the cluster."
  type        = string
}


variable "name" {
  description = "A human readable name to give the EKS Cluster resource in Common Fate. Defaults to the EKS cluster name."
  type        = string
  default     = ""
}



variable "create_default_rbac_roles" {
  description = "If 'true', will create default admin and read_only k8s rbac roles that allow the default Common Fate impersonate user roles to access the cluster."
  type        = bool
  default     = false
}
