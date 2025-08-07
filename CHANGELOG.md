# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres
to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.3.0] - 2025-08-07

[Compare with previous version](https://github.com/sparkfabrik/terraform-kubernetes-application-sleep-cycles/compare/1.2.0...1.3.0)

### Changed

- Temporary update default Docker image from `bitnami/kubectl:1.31` to `bitnamilegacy/kubectl:1.31` because of the deprecation of the `bitnami/kubectl` image.

## [1.2.0] - 2025-04-15

[Compare with previous version](https://github.com/sparkfabrik/terraform-kubernetes-application-sleep-cycles/compare/1.1.0...1.2.0)

### Added

- Add support for node affinity and tolerations for the cronjobs.

## [1.1.0] - 2025-04-11

[Compare with previous version](https://github.com/sparkfabrik/terraform-kubernetes-application-sleep-cycles/compare/1.0.0...1.1.0)

### Added

- Add support to define docker registry separately from the docker image. This allows to use the image defined in the module, but to use a different registry for the image.

## [1.0.0] - 2025-04-10

[Compare with previous version](https://github.com/sparkfabrik/terraform-kubernetes-application-sleep-cycles/compare/0.2.0...1.0.0)

### Breaking Changes

- The `managed_namespaces` variable has been renamed to `working_hours_managed_namespaces`.
- The `managed_namespaces_label_selector` variable has been renamed to `working_hours_managed_namespaces_label_selector`.
- The `managed_namespaces_all_label_selector` variable has been renamed to `working_hours_managed_namespaces_all_label_selector`.
- The `deployments_label_selector` variable has been renamed to `working_hours_deployments_label_selector`.
- The `statefulsets_label_selector` variable has been renamed to `working_hours_statefulsets_label_selector`.
- The `configmap_name_prefix` variable has been renamed to `working_hours_configmap_name_prefix`.
- The `cronjob_timezone` variable has been renamed to `working_hours_cronjob_timezone`.

### Added

- Add support for node drain feature useful for draining nodes after the sleep cycle and ensuring that the nodes are drained and ready to be shut down.
- Add support for deleting all pods in `Terminating` state.
- Add test helpers (Kind and Terraform project to install the module in the Kind cluster) for testing the sleep cycles scripts.
- Add support to run working hours script in all namespaces, without the need to specify/label them using `working_hours_all_namespaces` variable. Add `working_hours_all_namespaces_excluded_resources_label_selector` variable to exclude resources when using `working_hours_all_namespaces` variable.

## [0.2.0] - 2024-12-06

[Compare with previous version](https://github.com/sparkfabrik/terraform-kubernetes-application-sleep-cycles/compare/0.1.0...0.2.0)

- Add default protected Kubernetes system namespaces (kube-node-lease, kube-public, kube-system)
- Add management of statefulsets sleep cycle
- Add management of all resources in a namespace
- Refactor working-hours.sh script for better maintainability

## [0.1.0] - 2024-11-06

- First release.
