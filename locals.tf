locals {
  k8s_full_labels = merge(
    var.k8s_labels,
    var.k8s_additional_labels,
  )

  # Calculate the docker image to use for the features.
  working_hours_docker_image           = var.working_hours_docker_image != "" ? var.working_hours_docker_image : var.default_docker_image
  node_drain_docker_image              = var.node_drain_docker_image != "" ? var.node_drain_docker_image : var.default_docker_image
  remove_terminating_pods_docker_image = var.remove_terminating_pods_docker_image != "" ? var.remove_terminating_pods_docker_image : var.default_docker_image

  # Calculate the CronJob timezone to use for the features.
  working_hours_cronjob_timezone           = var.working_hours_cronjob_timezone != "" ? var.working_hours_cronjob_timezone : var.default_cronjob_timezone
  node_drain_cronjob_timezone              = var.node_drain_cronjob_timezone != "" ? var.node_drain_cronjob_timezone : var.default_cronjob_timezone
  remove_terminating_pods_cronjob_timezone = var.remove_terminating_pods_cronjob_timezone != "" ? var.remove_terminating_pods_cronjob_timezone : var.default_cronjob_timezone

  # Calculate the namespace to use for the CronJobs.
  cronjob_namespace = var.create_namespace ? var.namespace : data.kubernetes_namespace_v1.this[0].metadata[0].name

  managed_namespaces   = distinct(concat(var.working_hours_managed_namespaces, data.kubernetes_resources.managed_namespaces_by_labels.objects[*].metadata.name))
  protected_namespaces = distinct(concat(var.protected_namespaces, var.additional_protected_namespaces))

  # RBAC for application sleep cycles feature.
  rbac_cluster_scoped_application_sleep_cycles = [
    {
      api_groups = [""]
      resources  = ["namespaces"]
      verbs      = ["get", "list"]
    },
    {
      api_groups = ["apps"]
      resources  = ["deployments", "statefulsets"]
      verbs      = ["get", "list"]
    },
    {
      api_groups = ["apps"]
      resources  = ["deployments/scale", "statefulsets/scale"]
      verbs      = ["update", "patch"]
    },
  ]

  # RBAC for node drain feature.
  rbac_cluster_scoped_node_drain = [
    {
      api_groups = [""]
      resources  = ["pods"]
      verbs      = ["get", "list"]
    },
    {
      api_groups = ["apps"]
      resources  = ["deployments", "statefulsets"]
      verbs      = ["get", "list"]
    },
    {
      api_groups = ["apps"]
      resources  = ["daemonsets", "replicasets"]
      verbs      = ["get", "list"]
    },
    {
      api_groups = [""]
      resources  = ["pods/eviction"]
      verbs      = ["create"]
    },
    {
      api_groups = [""]
      resources  = ["nodes"]
      verbs      = ["get", "list", "patch"]
    },
    {
      api_groups = [""]
      resources  = ["nodes/eviction"]
      verbs      = ["create"]
    },
  ]

  # RBAC for remove terminating pods feature.
  rbac_cluster_scoped_remove_terminating_pods = [
    {
      api_groups = [""]
      resources  = ["pods"]
      verbs      = ["get", "list", "delete"]
    },
  ]

  # Create the list of finale RBAC permissions based on the enabled features.
  final_rbac_cluster_scoped = distinct(concat(
    var.working_hours_enabled || var.working_hours_all_namespaces ? local.rbac_cluster_scoped_application_sleep_cycles : [],
    var.node_drain_enabled ? local.rbac_cluster_scoped_node_drain : [],
    var.remove_terminating_pods_enabled ? local.rbac_cluster_scoped_remove_terminating_pods : [],
  ))
}
