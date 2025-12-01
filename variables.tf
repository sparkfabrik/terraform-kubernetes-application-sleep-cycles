variable "create_namespace" {
  description = "Create namespace. If false, the namespace must be created before using this module."
  type        = bool
  default     = true
}

variable "namespace" {
  description = "Namespace to create resources."
  type        = string
  default     = "application-sleep-cycles"
}

variable "default_docker_image" {
  description = "Default Docker image parts map (registry, repository, tag) used for all CronJob containers when no feature-specific override is provided. Missing attributes fall back to the module defaults."
  type = object({
    registry   = optional(string, "docker.io")
    repository = optional(string, "alpine/kubectl")
    tag        = optional(string, "1.33.4")
  })
}

variable "default_node_affinity_match_expressions" {
  description = "List of match expressions to use for the node affinity when the node affinity is not specified for the specific feature."
  type = list(object({
    key      = string
    operator = optional(string, "In")
    values   = list(string)
  }))
  default = []
}

variable "default_tolerations" {
  description = "List of tolerations to use when the tolerations are not specified for the specific feature."
  type = list(object({
    key      = string
    operator = string
    value    = optional(string, null)
    effect   = optional(string, null)
  }))
  default = []
}

variable "default_cronjob_timezone" {
  description = "Default timezone to use for the CronJobs."
  type        = string
  default     = "Europe/Rome"
}

variable "k8s_labels" {
  description = "Set of labels to apply to all resources."
  type        = map(string)
  default = {
    managed-by = "terraform"
    scope      = "finops"
  }
}

variable "k8s_additional_labels" {
  description = "Set of additional labels to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "service_account_name" {
  description = "Name of the service account."
  type        = string
  default     = "application-sleep-cycles-sa"
}

variable "cluster_role_name_prefix" {
  description = "Name of the cluster role."
  type        = string
  default     = "custom:application-sleep-cycles:controller"
}

variable "cluster_role_binding_name" {
  description = "Name of the cluster role binding."
  type        = string
  default     = "custom:application-sleep-cycles:controller"
}

variable "protected_namespaces" {
  description = "List of namespaces where the controller should not manage the scale of deployments. Use additional_protected_namespaces to add custom protected namespaces."
  type        = list(string)
  default     = ["kube-node-lease", "kube-public", "kube-system", "gmp-system", "gmp-public"]
}

variable "additional_protected_namespaces" {
  description = "List of additional namespaces where the controller should not manage the scale of deployments."
  type        = list(string)
  default     = []
}

# Working hours feature
variable "working_hours_enabled" {
  description = "Enable working hours feature."
  type        = bool
  default     = true
}

variable "working_hours_all_namespaces" {
  description = "Enable working hours for all resources in all namespaces (except the ones defined in the `protected_namespaces` variable). If set to true, the `working_hours_managed_namespaces`, `working_hours_managed_namespaces_label_selector` and `working_hours_managed_namespaces_all_label_selector` variables will be ignored. The `protected_namespaces` variable will still be used to protect the namespaces where the controller should not manage the scale of resources. The `working_hours_all_namespaces_excluded_resources_label_selector` variable will be used to protect resources running in a non-protected namespace which should not be scaled down/up."
  type        = bool
  default     = false
}

variable "working_hours_all_namespaces_excluded_resources_label_selector" {
  description = "Label selector used to exclude resources (deployments and statefulsets) which should not be scaled down/up when `working_hours_all_namespaces` is set to true. The negation of the label selector will be automatically applied, so using `sparkfabrik.com/always-on=true` will protect the resources with this label (`-l '!sparkfabrik.com/always-on=true'`). Use `null` as label value to consider only the label presence."
  type        = map(string)
  default = {
    "sparkfabrik.com/always-on" : "true"
  }
}

variable "working_hours_managed_namespaces" {
  description = "List of namespaces where the controller should manage the scale of deployments. The namespaces defined here will be merged with the namespaces fetched by the `working_hours_managed_namespaces_label_selector` variable."
  type        = list(string)
  default     = []
}

variable "working_hours_managed_namespaces_label_selector" {
  description = "Label selector for the namespaces where the controller should manage the scale of deployments. The namespaces fetched by this selector will be merged with the `working_hours_managed_namespaces` variable. **WARNING:** remember that if the labels specified here are added to new namespaces, the module will send the Terraform state into drift, as the list of namespaces is retrieved dynamically. You must then re-apply your Terraform configuration to fix the drift."
  type        = map(string)
  default = {
    "sparkfabrik.com/application-sleep-cycles" : "enabled"
  }
}

variable "working_hours_managed_namespaces_all_label_selector" {
  description = "Label selector for all resources in the namespaces where the controller should manage the scale of deployments. The namespace must have `working_hours_managed_namespaces_label_selector` set."
  type        = map(string)
  default = {
    "sparkfabrik.com/application-availability" : "working-hours"
  }
}

variable "working_hours_deployments_label_selector" {
  description = "Label selector for the Deployments to be scaled during working-hours."
  type        = map(string)
  default = {
    "sparkfabrik.com/application-availability" : "working-hours"
  }
}

variable "working_hours_statefulsets_label_selector" {
  description = "Label selector for the Statefulsets to be scaled during working-hours."
  type        = map(string)
  default = {
    "sparkfabrik.com/application-availability" : "working-hours"
  }
}

variable "working_hours_configmap_name_prefix" {
  description = "Name prefix for the Config Maps."
  type        = string
  default     = "application-sleep-cycles-config"
}

variable "working_hours_cronjob_timezone" {
  description = "Timezone to use for the cron jobs. If not specified, the `default_cronjob_timezone` variable will be used."
  type        = string
  default     = ""
}

variable "working_hours_resource_prefix" {
  description = "Prefix for the working hours resources."
  type        = string
  default     = "application-sleep-cycles-working-hours"
}

variable "working_hours_docker_image" {
  description = "Override map for the working hours CronJob Docker image parts. Any provided key (registry, repository, tag) will override `default_docker_image`."
  type = object({
    registry   = optional(string)
    repository = optional(string)
    tag        = optional(string)
  })
  default = {}
}

variable "working_hours_node_affinity_match_expressions" {
  description = "List of match expressions to use for the node affinity of the working hours CronJobs. If not specified (empty list), the `default_node_affinity_match_expressions` variable will be used."
  type = list(object({
    key      = string
    operator = optional(string, "In")
    values   = list(string)
  }))
  default = []
}

variable "working_hours_tolerations" {
  description = "List of tolerations to use for the working hours CronJobs. If not specified (empty list), the `default_tolerations` variable will be used."
  type = list(object({
    key      = string
    operator = string
    value    = optional(string, null)
    effect   = optional(string, null)
  }))
  default = []
}

variable "working_hours_suspend" {
  description = "Suspend the CronJob."
  type        = bool
  default     = false
}

variable "working_hours_scale_down_schedule" {
  description = "Cron schedule to scale down the Deployments. Remember that this is relative to the timezone defined in the `cronjob_timezone` variable."
  type        = string
  default     = "0 20 * * *"
}

variable "working_hours_scale_up_schedule" {
  description = "Cron schedule to scale up the Deployments. Remember that this is relative to the timezone defined in the `cronjob_timezone` variable."
  type        = string
  default     = "30 7 * * 1-5"
}

# Node drain feature
variable "node_drain_enabled" {
  description = "Enable node drain feature."
  type        = bool
  default     = false
}

variable "node_drain_suspend" {
  description = "Suspend the node drain CronJob."
  type        = bool
  default     = false
}

variable "node_drain_docker_image" {
  description = "Override map for the node drain CronJob Docker image parts. Any provided key (registry, repository, tag) will override `default_docker_image`."
  type = object({
    registry   = optional(string)
    repository = optional(string)
    tag        = optional(string)
  })
  default = {}
}

variable "node_drain_node_affinity_match_expressions" {
  description = "List of match expressions to use for the node affinity of the node drain CronJobs. If not specified (empty list), the `default_node_affinity_match_expressions` variable will be used."
  type = list(object({
    key      = string
    operator = optional(string, "In")
    values   = list(string)
  }))
  default = []
}

variable "node_drain_tolerations" {
  description = "List of tolerations to use for the node drain CronJobs. If not specified (empty list), the `default_tolerations` variable will be used."
  type = list(object({
    key      = string
    operator = string
    value    = optional(string, null)
    effect   = optional(string, null)
  }))
  default = []
}

variable "node_drain_resource_prefix" {
  description = "Prefix for the node drain resources."
  type        = string
  default     = "application-sleep-cycles-drain"
}

variable "node_drain_cronjob_schedule" {
  description = "Cron schedule to drain the nodes. Remember that this is relative to the timezone defined in the `node_drain_cronjob_timezone` variable."
  type        = string
  default     = "30 20-21 * * *"
}

variable "node_drain_cronjob_timezone" {
  description = "Timezone to use for the node drain CronJob. If not specified, the `default_cronjob_timezone` variable will be used."
  type        = string
  default     = ""
}

variable "node_drain_configmap_name_prefix" {
  description = "Name prefix for the node drain ConfigMap."
  type        = string
  default     = "application-sleep-cycles-drain-config"
}

variable "node_drain_nodes_label_selector" {
  description = "List of label selector for the nodes to be drained."
  type        = list(map(string))
  default     = []
}

# Remove terminating pods feature
variable "remove_terminating_pods_enabled" {
  description = "Enable remove terminating pods feature."
  type        = bool
  default     = false
}

variable "remove_terminating_pods_suspend" {
  description = "Suspend the remove terminating pods CronJob."
  type        = bool
  default     = false
}

variable "remove_terminating_pods_docker_image" {
  description = "Override map for the remove terminating pods CronJob Docker image parts. Any provided key (registry, repository, tag) will override `default_docker_image`."
  type = object({
    registry   = optional(string)
    repository = optional(string)
    tag        = optional(string)
  })
  default = {}
}

variable "remove_terminating_pods_node_affinity_match_expressions" {
  description = "List of match expressions to use for the node affinity of the remove terminating pods CronJobs. If not specified (empty list), the `default_node_affinity_match_expressions` variable will be used."
  type = list(object({
    key      = string
    operator = optional(string, "In")
    values   = list(string)
  }))
  default = []
}

variable "remove_terminating_pods_tolerations" {
  description = "List of tolerations to use for the remove terminating pods CronJobs. If not specified (empty list), the `default_tolerations` variable will be used."
  type = list(object({
    key      = string
    operator = string
    value    = optional(string, null)
    effect   = optional(string, null)
  }))
  default = []
}

variable "remove_terminating_pods_resource_prefix" {
  description = "Prefix for the remove terminating pods resources."
  type        = string
  default     = "application-sleep-cycles-terminating-pods"
}

variable "remove_terminating_pods_cronjob_schedule" {
  description = "Cron schedule to remove terminating pods. Remember that this is relative to the timezone defined in the `remove_terminating_pods_cronjob_timezone` variable."
  type        = string
  default     = "0 * * * *"
}

variable "remove_terminating_pods_cronjob_timezone" {
  description = "Timezone to use for the remove terminating pods CronJob. If not specified, the `default_cronjob_timezone` variable will be used."
  type        = string
  default     = ""
}

variable "remove_terminating_pods_configmap_name_prefix" {
  description = "Name prefix for the remove terminating pods ConfigMap."
  type        = string
  default     = "application-sleep-cycles-terminating-pods-config"
}
