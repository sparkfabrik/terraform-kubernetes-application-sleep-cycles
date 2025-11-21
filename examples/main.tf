module "example" {
  source = "../"

  additional_protected_namespaces  = var.additional_protected_namespaces
  working_hours_managed_namespaces = var.working_hours_managed_namespaces

  default_docker_image_components = var.default_docker_image_components

  working_hours_docker_image_components           = var.working_hours_docker_image_components
  node_drain_docker_image_components              = var.node_drain_docker_image_components
  remove_terminating_pods_docker_image_components = var.remove_terminating_pods_docker_image_components

  node_drain_enabled              = var.node_drain_enabled
  remove_terminating_pods_enabled = var.remove_terminating_pods_enabled
}
