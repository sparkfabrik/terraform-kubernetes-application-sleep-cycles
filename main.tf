# Get list of namespaces with a given label, where the controller should manage
# the scale of deployments.
data "kubernetes_resources" "managed_namespaces_by_labels" {
  kind           = "Namespace"
  api_version    = "v1"
  label_selector = join(",", [for k, v in var.working_hours_managed_namespaces_label_selector : v != null ? "${k}=${v}" : k])
}

# The namespace in which we want to deploy the cronjob is created only if the
# `create_namespace` variable is set to true.
# Otherwise, the namespace must be created before using this module.
resource "kubernetes_namespace_v1" "this" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name = var.namespace
    labels = merge(
      local.k8s_full_labels,
      { name = var.namespace },
    )
  }
}

data "kubernetes_namespace_v1" "this" {
  count = var.create_namespace ? 0 : 1

  metadata {
    name = var.namespace
  }
}

# The service account used by the cronjob to interact with the Kubernetes API.
resource "kubernetes_service_account_v1" "this" {
  metadata {
    name      = var.service_account_name
    namespace = local.cronjob_namespace
    labels    = local.k8s_full_labels
  }
}

resource "kubernetes_secret_v1" "this" {
  metadata {
    # This is the prefix, used by the server, to generate a unique name ONLY IF the name field has not been provided. This value will also be combined with a unique suffix.
    generate_name = "${var.service_account_name}-"
    namespace     = local.cronjob_namespace
    labels        = local.k8s_full_labels

    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account_v1.this.metadata[0].name
    }
  }

  type                           = "kubernetes.io/service-account-token"
  wait_for_service_account_token = true
}

# Service account permissions.
resource "kubernetes_cluster_role_v1" "cluster_scoped" {
  metadata {
    name   = "${var.cluster_role_name_prefix}-cluster-scoped"
    labels = local.k8s_full_labels
  }

  # Additional RBAC permissions for the node drain feature.
  dynamic "rule" {
    for_each = local.final_rbac_cluster_scoped

    content {
      api_groups = rule.value.api_groups
      resources  = rule.value.resources
      verbs      = rule.value.verbs
    }
  }
}

resource "kubernetes_cluster_role_binding_v1" "cluster_scoped" {
  metadata {
    name   = var.cluster_role_binding_name
    labels = local.k8s_full_labels
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.cluster_scoped.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.this.metadata[0].name
    namespace = local.cronjob_namespace
  }
}

resource "kubernetes_config_map_v1" "app_env" {
  metadata {
    name      = "${var.working_hours_configmap_name_prefix}-env"
    namespace = local.cronjob_namespace
    labels    = local.k8s_full_labels
  }

  data = {
    "NAMESPACES" : join(",", local.managed_namespaces),
    "PROTECTED_NAMESPACES" : join(",", local.protected_namespaces),
    "NAMESPACES_LABEL_SELECTOR" : join(",", [for k, v in var.working_hours_managed_namespaces_label_selector : v != null ? "${k}=${v}" : k]),
    "NAMESPACES_ALL_LABEL_SELECTOR" : join(",", [for k, v in var.working_hours_managed_namespaces_all_label_selector : v != null ? "${k}=${v}" : k]),
    "DEPLOYMENTS_LABEL_SELECTOR" : join(",", [for k, v in var.working_hours_deployments_label_selector : v != null ? "${k}=${v}" : k]),
    "STATEFULSETS_LABEL_SELECTOR" : join(",", [for k, v in var.working_hours_statefulsets_label_selector : v != null ? "${k}=${v}" : k]),
    "RUN_ON_ALL_NAMESPACES" : var.working_hours_all_namespaces ? "1" : "0",
    "RUN_ON_ALL_NAMESPACES_EXCLUDED_RESOURCES_LABEL_SELECTOR" : join(",", [for k, v in var.working_hours_all_namespaces_excluded_resources_label_selector : v != null ? "!${k}=${v}" : "!${k}"]),
  }
}

resource "kubernetes_config_map_v1" "app" {
  metadata {
    name      = "${var.working_hours_configmap_name_prefix}-app"
    namespace = local.cronjob_namespace
    labels    = local.k8s_full_labels
  }

  binary_data = {
    "working-hours.sh" = filebase64("${path.module}/files/working-hours.sh"),
  }
}

# We use `kubernetes_manifest` instead of `kubernetes_cron_job_v1` because the cron job resource does not support env and volume mounts.
resource "kubernetes_manifest" "scale_down" {
  manifest = yamldecode(
    templatefile(
      "${path.module}/files/k8s-base-cronjob.yaml.tftpl",
      {
        name               = "${var.working_hours_resource_prefix}-scale-down"
        namespace          = local.cronjob_namespace
        labels             = local.k8s_full_labels
        suspend            = var.working_hours_suspend
        schedule           = var.working_hours_scale_down_schedule
        timezone           = local.working_hours_cronjob_timezone
        image              = local.working_hours_docker_image
        config_map_app     = kubernetes_config_map_v1.app.metadata[0].name
        config_map_app_env = kubernetes_config_map_v1.app_env.metadata[0].name
        service_account    = kubernetes_service_account_v1.this.metadata[0].name

        # Static configuration
        script_name    = "working-hours.sh"
        request_cpu    = "100m"
        request_memory = "128Mi"

        # This is the scale down script, so we want to scale down the replicas to 0.
        additional_env = {
          "GO_TO_REPLICAS" : "0"
        }
      }
    )
  )
}

resource "kubernetes_manifest" "scale_up" {
  manifest = yamldecode(
    templatefile(
      "${path.module}/files/k8s-base-cronjob.yaml.tftpl",
      {
        name               = "${var.working_hours_resource_prefix}-scale-up"
        namespace          = local.cronjob_namespace
        labels             = local.k8s_full_labels
        suspend            = var.working_hours_suspend
        schedule           = var.working_hours_scale_up_schedule
        timezone           = local.working_hours_cronjob_timezone
        image              = local.working_hours_docker_image
        config_map_app     = kubernetes_config_map_v1.app.metadata[0].name
        config_map_app_env = kubernetes_config_map_v1.app_env.metadata[0].name
        service_account    = kubernetes_service_account_v1.this.metadata[0].name

        # Static configuration
        script_name    = "working-hours.sh"
        request_cpu    = "100m"
        request_memory = "128Mi"

        # This is the scale up script, so we want to scale up the replicas to 1.
        additional_env = {
          "GO_TO_REPLICAS" : "1"
        }
      }
    )
  )
}

# Node drain feature specific resources
resource "kubernetes_config_map_v1" "node_drain_app_env" {
  count = var.node_drain_enabled ? 1 : 0

  metadata {
    name      = "${var.node_drain_configmap_name_prefix}-env"
    namespace = local.cronjob_namespace
    labels    = local.k8s_full_labels
  }

  data = {
    NODES_LABEL_SELECTORS = join("|", [for lbls in var.node_drain_nodes_label_selector : join(",", [for k, v in lbls : "${k}=${v}"])]),
  }
}

resource "kubernetes_config_map_v1" "node_drain_app" {
  count = var.node_drain_enabled ? 1 : 0

  metadata {
    name      = "${var.node_drain_configmap_name_prefix}-app"
    namespace = local.cronjob_namespace
    labels    = local.k8s_full_labels
  }

  binary_data = {
    "node-drain.sh" = filebase64("${path.module}/files/node-drain.sh"),
  }
}

resource "kubernetes_manifest" "node_drain_cronjob" {
  count = var.node_drain_enabled ? 1 : 0

  manifest = yamldecode(
    templatefile(
      "${path.module}/files/k8s-base-cronjob.yaml.tftpl",
      {
        name               = "${var.node_drain_resource_prefix}-cronjob"
        namespace          = local.cronjob_namespace
        labels             = local.k8s_full_labels
        suspend            = var.node_drain_suspend
        schedule           = var.node_drain_cronjob_schedule
        timezone           = local.node_drain_cronjob_timezone
        image              = local.node_drain_docker_image
        config_map_app     = kubernetes_config_map_v1.node_drain_app[0].metadata[0].name
        config_map_app_env = kubernetes_config_map_v1.node_drain_app_env[0].metadata[0].name
        service_account    = kubernetes_service_account_v1.this.metadata[0].name

        # Static configuration
        script_name    = "node-drain.sh"
        request_cpu    = "100m"
        request_memory = "128Mi"
        additional_env = null
      }
    )
  )
}

# Remove terminating pods feature specific resources
resource "kubernetes_config_map_v1" "remove_terminating_pods_app_env" {
  count = var.remove_terminating_pods_enabled ? 1 : 0

  metadata {
    name      = "${var.remove_terminating_pods_configmap_name_prefix}-env"
    namespace = local.cronjob_namespace
    labels    = local.k8s_full_labels
  }

  data = {
    "PROTECTED_NAMESPACES" : join(",", local.protected_namespaces),
  }
}

resource "kubernetes_config_map_v1" "remove_terminating_pods_app" {
  count = var.remove_terminating_pods_enabled ? 1 : 0

  metadata {
    name      = "${var.remove_terminating_pods_configmap_name_prefix}-app"
    namespace = local.cronjob_namespace
    labels    = local.k8s_full_labels
  }

  binary_data = {
    "remove-terminating-pods.sh" = filebase64("${path.module}/files/remove-terminating-pods.sh"),
  }
}

resource "kubernetes_manifest" "remove_terminating_pods_cronjob" {
  count = var.remove_terminating_pods_enabled ? 1 : 0

  manifest = yamldecode(
    templatefile(
      "${path.module}/files/k8s-base-cronjob.yaml.tftpl",
      {
        name               = "${var.remove_terminating_pods_resource_prefix}-cronjob"
        namespace          = local.cronjob_namespace
        labels             = local.k8s_full_labels
        suspend            = var.remove_terminating_pods_suspend
        schedule           = var.remove_terminating_pods_cronjob_schedule
        timezone           = local.remove_terminating_pods_cronjob_timezone
        image              = local.remove_terminating_pods_docker_image
        config_map_app     = kubernetes_config_map_v1.remove_terminating_pods_app[0].metadata[0].name
        config_map_app_env = kubernetes_config_map_v1.remove_terminating_pods_app_env[0].metadata[0].name
        service_account    = kubernetes_service_account_v1.this.metadata[0].name

        # Static configuration
        script_name    = "remove-terminating-pods.sh"
        request_cpu    = "100m"
        request_memory = "128Mi"
        additional_env = null
      }
    )
  )
}
