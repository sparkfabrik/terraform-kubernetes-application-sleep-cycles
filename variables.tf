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
  description = "Docker image to use when the image is not specified for the specific feature."
  type        = string
  default     = "bitnami/kubectl:1.31"
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

# @TODO: at next breaking rename this to working_hours_managed_namespaces
variable "managed_namespaces" {
  description = "List of namespaces where the controller should manage the scale of deployments. The namespaces defined here will be merged with the namespaces fetched by the `managed_namespaces_label_selector` variable."
  type        = list(string)
  default     = []
}

# @TODO: at next breaking rename this to working_hours_managed_namespaces_label_selector
variable "managed_namespaces_label_selector" {
  description = "Label selector for the namespaces where the controller should manage the scale of deployments. The namespaces fetched by this selector will be merged with the `managed_namespaces` variable. **WARNING:** remember that if the labels specified here are added to new namespaces, the module will send the Terraform state into drift, as the list of namespaces is retrieved dynamically. You must then re-apply your Terraform configuration to fix the drift."
  type        = map(string)
  default = {
    "sparkfabrik.com/application-sleep-cycles" : "enabled"
  }
}

# @TODO: at next breaking rename this to working_hours_managed_namespaces_all_label_selector
variable "managed_namespaces_all_label_selector" {
  description = "Label selector for all resources in the namespaces where the controller should manage the scale of deployments. The namespace must have `managed_namespaces_label_selector` set."
  type        = map(string)
  default = {
    "sparkfabrik.com/application-availability" : "working-hours"
  }
}

# @TODO: at next breaking rename this to working_hours_deployments_label_selector
variable "deployments_label_selector" {
  description = "Label selector for the Deployments to be scaled during working-hours."
  type        = map(string)
  default = {
    "sparkfabrik.com/application-availability" : "working-hours"
  }
}

# @TODO: at next breaking rename this to working_hours_statefulsets_label_selector
variable "statefulsets_label_selector" {
  description = "Label selector for the Statefulsets to be scaled during working-hours."
  type        = map(string)
  default = {
    "sparkfabrik.com/application-availability" : "working-hours"
  }
}

# @TODO: at next breaking rename this to working_hours_configmap_name_prefix
variable "configmap_name_prefix" {
  description = "Name prefix for the Config Maps."
  type        = string
  default     = "application-sleep-cycles-config"
}

# @TODO: at next breaking rename this to working_hours_cronjob_timezone
variable "cronjob_timezone" {
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
  description = "Docker image to use for the working hours CronJobs. If not specified, the `default_docker_image` variable will be used."
  type        = string
  default     = ""
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
  description = "Docker image to use for the node drain CronJob. If not specified, the `default_docker_image` variable will be used."
  type        = string
  default     = ""
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
  description = "Docker image to use for the remove terminating pods CronJob. If not specified, the `default_docker_image` variable will be used."
  type        = string
  default     = ""
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
