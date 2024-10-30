
locals {
  k8s_full_labels = merge(
    var.k8s_labels,
    var.k8s_additional_labels,
  )

  final_namespace = var.create_namespace ? resource.kubernetes_namespace_v1.this[0].metadata[0].name : data.kubernetes_namespace_v1.this[0].metadata[0].name
}

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

resource "kubernetes_service_account_v1" "this" {
  metadata {
    name      = var.service_account_name
    namespace = local.final_namespace
    labels    = local.k8s_full_labels
  }
}

resource "kubernetes_secret_v1" "this" {
  metadata {
    generate_name = "${var.service_account_name}-"
    namespace     = local.final_namespace
    labels        = local.k8s_full_labels

    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account_v1.this.metadata[0].name
    }
  }

  type                           = "kubernetes.io/service-account-token"
  wait_for_service_account_token = true
}

resource "kubernetes_cluster_role_v1" "cluster_scoped" {
  metadata {
    name   = "${var.cluster_role_name_prefix}-cluster-scoped"
    labels = local.k8s_full_labels
  }

  rule {
    api_groups = [""]
    resources  = ["namespaces"]
    verbs      = ["get", "list"]
  }
}

resource "kubernetes_cluster_role_binding_v1" "cluster_scoped" {
  metadata {
    name   = var.role_binding_name
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
    namespace = local.final_namespace
  }
}

resource "kubernetes_cluster_role_v1" "namespace_scoped" {
  metadata {
    name   = "${var.cluster_role_name_prefix}-namespace-scoped"
    labels = local.k8s_full_labels
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments"]
    verbs      = ["get", "list"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments/scale"]
    verbs      = ["update", "patch"]
  }
}

resource "kubernetes_role_binding_v1" "this" {
  for_each = toset(var.managed_namespaces)

  metadata {
    name      = var.role_binding_name
    namespace = each.value
    labels    = local.k8s_full_labels
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.namespace_scoped.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.this.metadata[0].name
    namespace = local.final_namespace
  }
}

resource "kubernetes_config_map_v1" "app_env" {
  metadata {
    name      = "${var.configmap_name_prefix}-env"
    namespace = local.final_namespace
    labels    = local.k8s_full_labels
  }

  data = {
    "NAMESPACES" : join(",", var.managed_namespaces),
    "NAMESPACES_LABEL_SELECTOR" : join(",", [for k, v in var.managed_namespaces_label_selector : "${k}=${v}"]),
    "DEPLOYMENTS_LABEL_SELECTOR" : join(",", [for k, v in var.deployments_label_selector : "${k}=${v}"]),
  }
}

resource "kubernetes_config_map_v1" "app" {
  metadata {
    name      = "${var.configmap_name_prefix}-app"
    namespace = local.final_namespace
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
      "${path.module}/files/k8s-working-hours-cronjob.yaml.tftpl",
      {
        name               = "${var.working_hours_resource_prefix}-scale-down"
        namespace          = local.final_namespace
        labels             = local.k8s_full_labels
        suspend            = var.working_hours_suspend
        schedule           = var.working_hours_scale_down_schedule
        timezone           = var.cronjob_timezone
        image              = var.working_hours_docker_image
        config_map_app     = kubernetes_config_map_v1.app.metadata[0].name
        config_map_app_env = kubernetes_config_map_v1.app_env.metadata[0].name
        service_account    = kubernetes_service_account_v1.this.metadata[0].name

        # This is the scale down script, so we want to scale down the replicas to 0.
        go_to_replicas = 0
      }
    )
  )
}

resource "kubernetes_manifest" "scale_up" {
  manifest = yamldecode(
    templatefile(
      "${path.module}/files/k8s-working-hours-cronjob.yaml.tftpl",
      {
        name               = "${var.working_hours_resource_prefix}-scale-up"
        namespace          = local.final_namespace
        labels             = local.k8s_full_labels
        suspend            = var.working_hours_suspend
        schedule           = var.working_hours_scale_up_schedule
        timezone           = var.cronjob_timezone
        image              = var.working_hours_docker_image
        config_map_app     = kubernetes_config_map_v1.app.metadata[0].name
        config_map_app_env = kubernetes_config_map_v1.app_env.metadata[0].name
        service_account    = kubernetes_service_account_v1.this.metadata[0].name

        # This is the scale up script, so we want to scale up the replicas to 1.
        go_to_replicas = 1
      }
    )
  )
}
