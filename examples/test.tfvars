additional_protected_namespaces = [
  "my-protected-namespace-01",
  "my-protected-namespace-02",
]

working_hours_managed_namespaces = [
  "my-awesome-namespace-01",
  "my-awesome-namespace-02",
  "my-awesome-namespace-03",
]

node_drain_enabled              = false
remove_terminating_pods_enabled = true

default_docker_image = {
  registry   = "registry.k8s.io"
  repository = "kubectl"
  tag        = "v1.31.0"
}

working_hours_docker_image = {
  repository = "kubectl"
  tag        = "v1.31.1"
}

node_drain_docker_image = {
  registry   = "mirror.local"
  repository = "custom/kubectl"
  tag        = "v1.31.0"
}

remove_terminating_pods_docker_image = {
  registry   = "registry.k8s.io"
  repository = "kubectl"
  tag        = "v1.31.0"
}
