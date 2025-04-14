provider "kubernetes" {
  config_path = "./kind-kubeconfig.yaml"
}

module "application_sleep_cycles" {
  source = "../../"

  additional_protected_namespaces = [
    "local-path-storage"
  ]

  default_node_affinity_match_expressions = [
    {
      key      = "scope"
      operator = "In"
      values = [
        "control-plane",
      ]
    }
  ]

  working_hours_managed_namespaces_label_selector = {
    "sparkfabrik.com/application-sleep-cycles" : "enabled"
  }

  node_drain_enabled              = true
  remove_terminating_pods_enabled = true

  node_drain_nodes_label_selector = [
    {
      "scope" : "worker"
      "name" : "worker1"
    },
    {
      "scope" : "worker"
      "name" : "worker2"
    }
  ]

  working_hours_all_namespaces = true
  working_hours_all_namespaces_excluded_resources_label_selector = {
    "always_on" : null,
  }
}
