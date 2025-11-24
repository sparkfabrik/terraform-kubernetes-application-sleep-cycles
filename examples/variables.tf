variable "additional_protected_namespaces" {
  type        = list(string)
  description = "List of additional namespaces where the application sleep cycles should not manage the scale of deployments."
}

variable "working_hours_managed_namespaces" {
  type        = list(string)
  description = "List of the namespaces where the application sleep cycles should manage the scale of deployments."
}

variable "default_docker_image" {
  description = "Default Docker image parts map (registry, repository, tag)."
  type = object({
    registry   = optional(string)
    repository = optional(string)
    tag        = optional(string)
  })
}

variable "working_hours_docker_image" {
  description = "Docker image parts override for working hours (registry, repository, tag)."
  type = object({
    registry   = optional(string)
    repository = optional(string)
    tag        = optional(string)
  })
  default = {}
}

variable "node_drain_docker_image" {
  description = "Docker image parts override for node drain (registry, repository, tag)."
  type = object({
    registry   = optional(string)
    repository = optional(string)
    tag        = optional(string)
  })
  default = {}
}

variable "remove_terminating_pods_docker_image" {
  description = "Docker image parts override for remove terminating pods (registry, repository, tag)."
  type = object({
    registry   = optional(string)
    repository = optional(string)
    tag        = optional(string)
  })
  default = {}
}

variable "node_drain_enabled" {
  description = "Enable node drain feature."
  type        = bool
}

variable "remove_terminating_pods_enabled" {
  description = "Enable remove terminating pods feature."
  type        = bool
}
