# Terraform Kubernetes Application Sleep Cycles

This is a Terraform module to install a cron job on a Kubernetes cluster that uses the labels of application instances to perform a scale down to zero during predefined periods, thus reducing resource consumption, and then automatically restores the applications by scaling up at the end of the idle period.

<!-- BEGIN_TF_DOCS -->
## Providers

| Name | Version |
|------|---------|
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.26 |

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.26 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_role_name_prefix"></a> [cluster\_role\_name\_prefix](#input\_cluster\_role\_name\_prefix) | Name of the cluster role. | `string` | `"custom:application-sleep-cycles:controller"` | no |
| <a name="input_configmap_name_prefix"></a> [configmap\_name\_prefix](#input\_configmap\_name\_prefix) | Name prefix for the Config Maps. | `string` | `"application-sleep-cycles-config"` | no |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | Create namespace. If false, the namespace must be created before using this module. | `bool` | `true` | no |
| <a name="input_cronjob_timezone"></a> [cronjob\_timezone](#input\_cronjob\_timezone) | Timezone to use for the cron jobs. | `string` | `"Europe/Rome"` | no |
| <a name="input_deployments_label_selector"></a> [deployments\_label\_selector](#input\_deployments\_label\_selector) | Label selector for the Deployments to be scaled. | `map(string)` | <pre>{<br>  "sparkfabrik.com/application-availability": "working-hours"<br>}</pre> | no |
| <a name="input_k8s_additional_labels"></a> [k8s\_additional\_labels](#input\_k8s\_additional\_labels) | Set of additional labels to apply to all resources. | `map(string)` | `{}` | no |
| <a name="input_k8s_labels"></a> [k8s\_labels](#input\_k8s\_labels) | Set of labels to apply to all resources. | `map(string)` | <pre>{<br>  "managed-by": "terraform",<br>  "scope": "finops"<br>}</pre> | no |
| <a name="input_managed_namespaces"></a> [managed\_namespaces](#input\_managed\_namespaces) | List of namespaces where the controller should manage the scale of deployments. The namespaces defined here will be merged with the namespaces fetched by the `managed_namespaces_label_selector` variable. | `list(string)` | `[]` | no |
| <a name="input_managed_namespaces_label_selector"></a> [managed\_namespaces\_label\_selector](#input\_managed\_namespaces\_label\_selector) | Label selector for the namespaces where the controller should manage the scale of deployments. The namespaces fetched by this selector will be merged with the `managed_namespaces` variable. | `map(string)` | <pre>{<br>  "sparkfabrik.com/stage-application-finops": "enabled"<br>}</pre> | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace to create resources. | `string` | `"application-sleep-cycles"` | no |
| <a name="input_role_binding_name"></a> [role\_binding\_name](#input\_role\_binding\_name) | Name of the role binding. | `string` | `"custom:application-sleep-cycles:controller"` | no |
| <a name="input_service_account_name"></a> [service\_account\_name](#input\_service\_account\_name) | Name of the service account. | `string` | `"application-sleep-cycles-sa"` | no |
| <a name="input_working_hours_docker_image"></a> [working\_hours\_docker\_image](#input\_working\_hours\_docker\_image) | Docker image to use for the working hours CronJobs. | `string` | `"bitnami/kubectl:1.29"` | no |
| <a name="input_working_hours_resource_prefix"></a> [working\_hours\_resource\_prefix](#input\_working\_hours\_resource\_prefix) | Prefix for the working hours resources. | `string` | `"application-sleep-cycles-working-hours"` | no |
| <a name="input_working_hours_scale_down_schedule"></a> [working\_hours\_scale\_down\_schedule](#input\_working\_hours\_scale\_down\_schedule) | Cron schedule to scale down the Deployments. Remember that this is relative to the timezone defined in the `cronjob_timezone` variable. | `string` | `"0 20 * * *"` | no |
| <a name="input_working_hours_scale_up_schedule"></a> [working\_hours\_scale\_up\_schedule](#input\_working\_hours\_scale\_up\_schedule) | Cron schedule to scale up the Deployments. Remember that this is relative to the timezone defined in the `cronjob_timezone` variable. | `string` | `"30 7 * * 1-5"` | no |
| <a name="input_working_hours_suspend"></a> [working\_hours\_suspend](#input\_working\_hours\_suspend) | Suspend the CronJob. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_k8s_full_labels"></a> [k8s\_full\_labels](#output\_k8s\_full\_labels) | Full set of labels applied to all resources. |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | Namespace where the descheduler is installed. |

## Resources

| Name | Type |
|------|------|
| [kubernetes_cluster_role_binding_v1.cluster_scoped](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role_binding_v1) | resource |
| [kubernetes_cluster_role_v1.cluster_scoped](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role_v1) | resource |
| [kubernetes_cluster_role_v1.namespace_scoped](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role_v1) | resource |
| [kubernetes_config_map_v1.app](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map_v1) | resource |
| [kubernetes_config_map_v1.app_env](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map_v1) | resource |
| [kubernetes_manifest.scale_down](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.scale_up](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_namespace_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1) | resource |
| [kubernetes_role_binding_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role_binding_v1) | resource |
| [kubernetes_secret_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret_v1) | resource |
| [kubernetes_service_account_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account_v1) | resource |
| [kubernetes_namespace_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/namespace_v1) | data source |

## Modules

No modules.

<!-- END_TF_DOCS -->
