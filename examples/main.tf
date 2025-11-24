module "example" {
  source = "github.com/sparkfabrik/terraform-kubernetes-application-sleep-cycles?ref=main"

  additional_protected_namespaces  = var.additional_protected_namespaces
  working_hours_managed_namespaces = var.working_hours_managed_namespaces

  default_docker_image = var.default_docker_image

  working_hours_docker_image           = var.working_hours_docker_image
  node_drain_docker_image              = var.node_drain_docker_image
  remove_terminating_pods_docker_image = var.remove_terminating_pods_docker_image

  node_drain_enabled              = var.node_drain_enabled
  remove_terminating_pods_enabled = var.remove_terminating_pods_enabled
}
