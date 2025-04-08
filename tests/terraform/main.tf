provider "kubernetes" {
  config_path = "./kind-kubeconfig.yaml"
}

module "application_sleep_cycles" {
  source = "../../"

  managed_namespaces_label_selector = {
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
}
