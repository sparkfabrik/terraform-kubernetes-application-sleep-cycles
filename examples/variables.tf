variable "additional_protected_namespaces" {
  type        = list(string)
  description = "List of additional namespaces where the application sleep cycles should not manage the scale of deployments."
}

variable "working_hours_managed_namespaces" {
  type        = list(string)
  description = "List of the namespaces where the application sleep cycles should manage the scale of deployments."
}

variable "node_drain_enabled" {
  description = "Enable node drain feature."
  type        = bool
}

variable "remove_terminating_pods_enabled" {
  description = "Enable remove terminating pods feature."
  type        = bool
}
