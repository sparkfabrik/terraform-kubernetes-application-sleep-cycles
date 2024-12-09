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

variable "managed_namespaces" {
  description = "List of namespaces where the controller should manage the scale of deployments. The namespaces defined here will be merged with the namespaces fetched by the `managed_namespaces_label_selector` variable."
  type        = list(string)
  default     = []
}

variable "managed_namespaces_label_selector" {
  description = "Label selector for the namespaces where the controller should manage the scale of deployments. The namespaces fetched by this selector will be merged with the `managed_namespaces` variable. **WARNING:** remember that if the labels specified here are added to new namespaces, the module will send the Terraform state into drift, as the list of namespaces is retrieved dynamically. You must then re-apply your Terraform configuration to fix the drift.."
  type        = map(string)
  default = {
    "sparkfabrik.com/application-sleep-cycles" : "enabled"
  }
}

# @TODO: at next breaking rename this to managed_namespaces_all_label_selector_for_working_hours
variable "managed_namespaces_all_label_selector" {
  description = "Label selector for all resources in the namespaces where the controller should manage the scale of deployments. The namespace must have `managed_namespaces_label_selector` set."
  type        = map(string)
  default = {
    "sparkfabrik.com/application-availability" : "working-hours"
  }
}

#aggiungere variabili per protected namespaces
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

# @TODO: at next breaking rename this to deployments_label_selector_for_working_hours
variable "deployments_label_selector" {
  description = "Label selector for the Deployments to be scaled during working-hours."
  type        = map(string)
  default = {
    "sparkfabrik.com/application-availability" : "working-hours"
  }
}

# @TODO: at next breaking rename this to statefulsets_label_selector_for_working_hours
variable "statefulsets_label_selector" {
  description = "Label selector for the Statefulsets to be scaled during working-hours."
  type        = map(string)
  default = {
    "sparkfabrik.com/application-availability" : "working-hours"
  }
}

variable "configmap_name_prefix" {
  description = "Name prefix for the Config Maps."
  type        = string
  default     = "application-sleep-cycles-config"
}

variable "cronjob_timezone" {
  description = "Timezone to use for the cron jobs."
  type        = string
  default     = "Europe/Rome"
}

variable "working_hours_resource_prefix" {
  description = "Prefix for the working hours resources."
  type        = string
  default     = "application-sleep-cycles-working-hours"
}

variable "working_hours_docker_image" {
  description = "Docker image to use for the working hours CronJobs."
  type        = string
  default     = "bitnami/kubectl:1.29"
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
