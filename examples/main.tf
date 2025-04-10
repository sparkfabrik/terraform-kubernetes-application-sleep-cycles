module "example" {
  source  = "github.com/sparkfabrik/terraform-module-template"
  version = ">= 0.2.0"

  additional_protected_namespaces  = var.additional_protected_namespaces
  working_hours_managed_namespaces = var.managed_namespaces

  node_drain_enabled              = var.node_drain_enabled
  remove_terminating_pods_enabled = var.remove_terminating_pods_enabled
}
