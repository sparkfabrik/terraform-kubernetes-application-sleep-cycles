# Terraform Kubernetes Application Sleep Cycles

This is a Terraform module to install a cron job on a Kubernetes cluster that uses the labels of application instances to perform a scale down to zero during predefined periods, thus reducing resource consumption, and then automatically restores the applications by scaling up at the end of the idle period.

## Tests your scripts

In the `Makefile.test` and in `tests` folder are present some helpers to create a [kind](https://kind.sigs.k8s.io/) cluster, deploy the Terraform module, deploy some test resources and run some tests.

### Deploy test resources

1. Run `make kind-create-cluster` to create a kind cluster.
2. Run `make terraform-cli` and execute, inside the container shell the command `terraform init && terraform apply` to deploy the module inside the kind cluster.
3. Run `make deploy-resources` to deploy some test resources. This command will deploy all the manifests in the `tests/manifests` folder using `kubectl apply -f`.
4. **(OPTIONAL)** Run `make patch-cronjob` to patch the CronJob created by the Terraform module. This command will patch the CronJob using the `control-plane` node as `nodeSelector`.
5. Run `make application-pod-shell` to open a shell inside the application pod. Inside the pod you can test your application script which are mounted in the `/app` folder.

<!-- BEGIN_TF_DOCS -->
## Providers

| Name | Version |
|------|---------|
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.36.0 |

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.26 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_protected_namespaces"></a> [additional\_protected\_namespaces](#input\_additional\_protected\_namespaces) | List of additional namespaces where the controller should not manage the scale of deployments. | `list(string)` | `[]` | no |
| <a name="input_cluster_role_binding_name"></a> [cluster\_role\_binding\_name](#input\_cluster\_role\_binding\_name) | Name of the cluster role binding. | `string` | `"custom:application-sleep-cycles:controller"` | no |
| <a name="input_cluster_role_name_prefix"></a> [cluster\_role\_name\_prefix](#input\_cluster\_role\_name\_prefix) | Name of the cluster role. | `string` | `"custom:application-sleep-cycles:controller"` | no |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | Create namespace. If false, the namespace must be created before using this module. | `bool` | `true` | no |
| <a name="input_default_cronjob_timezone"></a> [default\_cronjob\_timezone](#input\_default\_cronjob\_timezone) | Default timezone to use for the CronJobs. | `string` | `"Europe/Rome"` | no |
| <a name="input_default_docker_image"></a> [default\_docker\_image](#input\_default\_docker\_image) | Docker image to use when the image is not specified for the specific feature. | `string` | `"bitnami/kubectl:1.31"` | no |
| <a name="input_k8s_additional_labels"></a> [k8s\_additional\_labels](#input\_k8s\_additional\_labels) | Set of additional labels to apply to all resources. | `map(string)` | `{}` | no |
| <a name="input_k8s_labels"></a> [k8s\_labels](#input\_k8s\_labels) | Set of labels to apply to all resources. | `map(string)` | <pre>{<br/>  "managed-by": "terraform",<br/>  "scope": "finops"<br/>}</pre> | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace to create resources. | `string` | `"application-sleep-cycles"` | no |
| <a name="input_node_drain_configmap_name_prefix"></a> [node\_drain\_configmap\_name\_prefix](#input\_node\_drain\_configmap\_name\_prefix) | Name prefix for the node drain ConfigMap. | `string` | `"application-sleep-cycles-drain-config"` | no |
| <a name="input_node_drain_cronjob_schedule"></a> [node\_drain\_cronjob\_schedule](#input\_node\_drain\_cronjob\_schedule) | Cron schedule to drain the nodes. Remember that this is relative to the timezone defined in the `node_drain_cronjob_timezone` variable. | `string` | `"30 20-21 * * *"` | no |
| <a name="input_node_drain_cronjob_timezone"></a> [node\_drain\_cronjob\_timezone](#input\_node\_drain\_cronjob\_timezone) | Timezone to use for the node drain CronJob. If not specified, the `default_cronjob_timezone` variable will be used. | `string` | `""` | no |
| <a name="input_node_drain_docker_image"></a> [node\_drain\_docker\_image](#input\_node\_drain\_docker\_image) | Docker image to use for the node drain CronJob. If not specified, the `default_docker_image` variable will be used. | `string` | `""` | no |
| <a name="input_node_drain_enabled"></a> [node\_drain\_enabled](#input\_node\_drain\_enabled) | Enable node drain feature. | `bool` | `false` | no |
| <a name="input_node_drain_nodes_label_selector"></a> [node\_drain\_nodes\_label\_selector](#input\_node\_drain\_nodes\_label\_selector) | List of label selector for the nodes to be drained. | `list(map(string))` | `[]` | no |
| <a name="input_node_drain_resource_prefix"></a> [node\_drain\_resource\_prefix](#input\_node\_drain\_resource\_prefix) | Prefix for the node drain resources. | `string` | `"application-sleep-cycles-drain"` | no |
| <a name="input_node_drain_suspend"></a> [node\_drain\_suspend](#input\_node\_drain\_suspend) | Suspend the node drain CronJob. | `bool` | `false` | no |
| <a name="input_protected_namespaces"></a> [protected\_namespaces](#input\_protected\_namespaces) | List of namespaces where the controller should not manage the scale of deployments. Use additional\_protected\_namespaces to add custom protected namespaces. | `list(string)` | <pre>[<br/>  "kube-node-lease",<br/>  "kube-public",<br/>  "kube-system",<br/>  "gmp-system",<br/>  "gmp-public"<br/>]</pre> | no |
| <a name="input_remove_terminating_pods_configmap_name_prefix"></a> [remove\_terminating\_pods\_configmap\_name\_prefix](#input\_remove\_terminating\_pods\_configmap\_name\_prefix) | Name prefix for the remove terminating pods ConfigMap. | `string` | `"application-sleep-cycles-terminating-pods-config"` | no |
| <a name="input_remove_terminating_pods_cronjob_schedule"></a> [remove\_terminating\_pods\_cronjob\_schedule](#input\_remove\_terminating\_pods\_cronjob\_schedule) | Cron schedule to remove terminating pods. Remember that this is relative to the timezone defined in the `remove_terminating_pods_cronjob_timezone` variable. | `string` | `"0 * * * *"` | no |
| <a name="input_remove_terminating_pods_cronjob_timezone"></a> [remove\_terminating\_pods\_cronjob\_timezone](#input\_remove\_terminating\_pods\_cronjob\_timezone) | Timezone to use for the remove terminating pods CronJob. If not specified, the `default_cronjob_timezone` variable will be used. | `string` | `""` | no |
| <a name="input_remove_terminating_pods_docker_image"></a> [remove\_terminating\_pods\_docker\_image](#input\_remove\_terminating\_pods\_docker\_image) | Docker image to use for the remove terminating pods CronJob. If not specified, the `default_docker_image` variable will be used. | `string` | `""` | no |
| <a name="input_remove_terminating_pods_enabled"></a> [remove\_terminating\_pods\_enabled](#input\_remove\_terminating\_pods\_enabled) | Enable remove terminating pods feature. | `bool` | `false` | no |
| <a name="input_remove_terminating_pods_resource_prefix"></a> [remove\_terminating\_pods\_resource\_prefix](#input\_remove\_terminating\_pods\_resource\_prefix) | Prefix for the remove terminating pods resources. | `string` | `"application-sleep-cycles-terminating-pods"` | no |
| <a name="input_remove_terminating_pods_suspend"></a> [remove\_terminating\_pods\_suspend](#input\_remove\_terminating\_pods\_suspend) | Suspend the remove terminating pods CronJob. | `bool` | `false` | no |
| <a name="input_service_account_name"></a> [service\_account\_name](#input\_service\_account\_name) | Name of the service account. | `string` | `"application-sleep-cycles-sa"` | no |
| <a name="input_working_hours_all_namespaces"></a> [working\_hours\_all\_namespaces](#input\_working\_hours\_all\_namespaces) | Enable working hours for all resources in all namespaces (except the ones defined in the `protected_namespaces` variable). If set to true, the `working_hours_managed_namespaces`, `working_hours_managed_namespaces_label_selector` and `working_hours_managed_namespaces_all_label_selector` variables will be ignored. The `protected_namespaces` variable will still be used to protect the namespaces where the controller should not manage the scale of resources. The `working_hours_all_namespaces_excluded_resources_label_selector` variable will be used to protect resources running in a non-protected namespace which should not be scaled down/up. | `bool` | `false` | no |
| <a name="input_working_hours_all_namespaces_excluded_resources_label_selector"></a> [working\_hours\_all\_namespaces\_excluded\_resources\_label\_selector](#input\_working\_hours\_all\_namespaces\_excluded\_resources\_label\_selector) | Label selector used to exclude resources (deployments and statefulsets) which should not be scaled down/up when `working_hours_all_namespaces` is set to true. The negation of the label selector will be automatically applied, so using `sparkfabrik.com/always-on=true` will protect the resources with this label (`-l '!sparkfabrik.com/always-on=true'`). Use `null` as label value to consider only the label presence. | `map(string)` | <pre>{<br/>  "sparkfabrik.com/always-on": "true"<br/>}</pre> | no |
| <a name="input_working_hours_configmap_name_prefix"></a> [working\_hours\_configmap\_name\_prefix](#input\_working\_hours\_configmap\_name\_prefix) | Name prefix for the Config Maps. | `string` | `"application-sleep-cycles-config"` | no |
| <a name="input_working_hours_cronjob_timezone"></a> [working\_hours\_cronjob\_timezone](#input\_working\_hours\_cronjob\_timezone) | Timezone to use for the cron jobs. If not specified, the `default_cronjob_timezone` variable will be used. | `string` | `""` | no |
| <a name="input_working_hours_deployments_label_selector"></a> [working\_hours\_deployments\_label\_selector](#input\_working\_hours\_deployments\_label\_selector) | Label selector for the Deployments to be scaled during working-hours. | `map(string)` | <pre>{<br/>  "sparkfabrik.com/application-availability": "working-hours"<br/>}</pre> | no |
| <a name="input_working_hours_docker_image"></a> [working\_hours\_docker\_image](#input\_working\_hours\_docker\_image) | Docker image to use for the working hours CronJobs. If not specified, the `default_docker_image` variable will be used. | `string` | `""` | no |
| <a name="input_working_hours_enabled"></a> [working\_hours\_enabled](#input\_working\_hours\_enabled) | Enable working hours feature. | `bool` | `true` | no |
| <a name="input_working_hours_managed_namespaces"></a> [working\_hours\_managed\_namespaces](#input\_working\_hours\_managed\_namespaces) | List of namespaces where the controller should manage the scale of deployments. The namespaces defined here will be merged with the namespaces fetched by the `working_hours_managed_namespaces_label_selector` variable. | `list(string)` | `[]` | no |
| <a name="input_working_hours_managed_namespaces_all_label_selector"></a> [working\_hours\_managed\_namespaces\_all\_label\_selector](#input\_working\_hours\_managed\_namespaces\_all\_label\_selector) | Label selector for all resources in the namespaces where the controller should manage the scale of deployments. The namespace must have `working_hours_managed_namespaces_label_selector` set. | `map(string)` | <pre>{<br/>  "sparkfabrik.com/application-availability": "working-hours"<br/>}</pre> | no |
| <a name="input_working_hours_managed_namespaces_label_selector"></a> [working\_hours\_managed\_namespaces\_label\_selector](#input\_working\_hours\_managed\_namespaces\_label\_selector) | Label selector for the namespaces where the controller should manage the scale of deployments. The namespaces fetched by this selector will be merged with the `working_hours_managed_namespaces` variable. **WARNING:** remember that if the labels specified here are added to new namespaces, the module will send the Terraform state into drift, as the list of namespaces is retrieved dynamically. You must then re-apply your Terraform configuration to fix the drift. | `map(string)` | <pre>{<br/>  "sparkfabrik.com/application-sleep-cycles": "enabled"<br/>}</pre> | no |
| <a name="input_working_hours_resource_prefix"></a> [working\_hours\_resource\_prefix](#input\_working\_hours\_resource\_prefix) | Prefix for the working hours resources. | `string` | `"application-sleep-cycles-working-hours"` | no |
| <a name="input_working_hours_scale_down_schedule"></a> [working\_hours\_scale\_down\_schedule](#input\_working\_hours\_scale\_down\_schedule) | Cron schedule to scale down the Deployments. Remember that this is relative to the timezone defined in the `cronjob_timezone` variable. | `string` | `"0 20 * * *"` | no |
| <a name="input_working_hours_scale_up_schedule"></a> [working\_hours\_scale\_up\_schedule](#input\_working\_hours\_scale\_up\_schedule) | Cron schedule to scale up the Deployments. Remember that this is relative to the timezone defined in the `cronjob_timezone` variable. | `string` | `"30 7 * * 1-5"` | no |
| <a name="input_working_hours_statefulsets_label_selector"></a> [working\_hours\_statefulsets\_label\_selector](#input\_working\_hours\_statefulsets\_label\_selector) | Label selector for the Statefulsets to be scaled during working-hours. | `map(string)` | <pre>{<br/>  "sparkfabrik.com/application-availability": "working-hours"<br/>}</pre> | no |
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
| [kubernetes_config_map_v1.app](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map_v1) | resource |
| [kubernetes_config_map_v1.app_env](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map_v1) | resource |
| [kubernetes_config_map_v1.node_drain_app](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map_v1) | resource |
| [kubernetes_config_map_v1.node_drain_app_env](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map_v1) | resource |
| [kubernetes_config_map_v1.remove_terminating_pods_app](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map_v1) | resource |
| [kubernetes_config_map_v1.remove_terminating_pods_app_env](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map_v1) | resource |
| [kubernetes_manifest.node_drain_cronjob](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.remove_terminating_pods_cronjob](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.scale_down](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.scale_up](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_namespace_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1) | resource |
| [kubernetes_secret_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret_v1) | resource |
| [kubernetes_service_account_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account_v1) | resource |
| [kubernetes_namespace_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/namespace_v1) | data source |
| [kubernetes_resources.managed_namespaces_by_labels](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/resources) | data source |

## Modules

No modules.

<!-- END_TF_DOCS -->
