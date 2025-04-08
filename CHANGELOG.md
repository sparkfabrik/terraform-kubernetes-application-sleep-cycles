# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres
to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Add support for node drain feature useful for draining nodes after the sleep cycle and ensuring that the nodes are drained and ready to be shut down.
- Add support for deleting all pods in `Terminating` state.
- Add test helpers (Kind and Terraform project to install the module in the Kind cluster) for testing the sleep cycles scripts.

## [0.2.0] - 2024-12-06

[Compare with previous version](https://github.com/sparkfabrik/terraform-kubernetes-application-sleep-cycles/compare/0.1.0...0.2.0)

- Add default protected Kubernetes system namespaces (kube-node-lease, kube-public, kube-system)
- Add management of statefulsets sleep cycle
- Add management of all resources in a namespace
- Refactor working-hours.sh script for better maintainability

## [0.1.0] - 2024-11-06

- First release.
