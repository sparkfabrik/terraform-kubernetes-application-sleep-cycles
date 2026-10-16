# Upgrading

This guide lists the actions needed to upgrade the module between versions.

The module follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html). A version with no entry here needs no action beyond bumping the module version.

## How to upgrade

Follow these steps, in order:

1. Find the version you run (the `version` or `ref` of the module source) and the target version.
2. Read every section below between those two versions, oldest first, and apply each required action. Do not skip a section, even when the target is several releases ahead.
3. Read the matching sections in `CHANGELOG.md` for the full list of changes.
4. Bump the module version and run `terraform init -upgrade`.
5. Run `terraform plan` and check that it only changes the module resources you expect, mostly the CronJob ConfigMaps.
6. Apply, then check the logs of the next working hours CronJob run. The `WARNING: Following namespaces were filtered out` line lists the protected namespaces that were skipped.

## 2.3.0

No action required. This release adds a feature and does not change the behavior of existing configurations.

Entries in `protected_namespaces` and `additional_protected_namespaces` now accept wildcards. Each entry is matched against the whole namespace name:

| Entry          | Matches                                        | Does not match                   |
| -------------- | ---------------------------------------------- | -------------------------------- |
| `monitoring`   | `monitoring`                                   | `monitoring-eu`, `my-monitoring` |
| `*monitoring*` | `monitoring`, `monitoring-eu`, `my-monitoring` | `monitor`                        |
| `kube-*`       | `kube-system`, `kube-public`                   | `my-kube-system`                 |
| `*-prod`       | `shop-prod`, `api-prod`                        | `shop-prod-1`, `prod`            |
| `review-?`     | `review-1`, `review-a`                         | `review-12`, `review-`           |
| `app-??-prod`  | `app-eu-prod`, `app-us-prod`                   | `app-prod`, `app-eu1-prod`       |

`*` matches any sequence of characters, including none. `?` matches exactly one character. An entry that contains `[`, `]` or `\` is compared as a literal name, as before.

### Optional: restore the substring matching of versions before 2.2.0

Versions before 2.2.0 protected every namespace whose name contained a protected entry. To get the same result for an entry, wrap it in `*`:

```hcl
additional_protected_namespaces = [
  "*monitoring*", # before 2.2.0: "monitoring"
]
```

## 2.2.0

**Protected namespaces match by exact name.** Before 2.2.0, an entry also protected every namespace whose name contained it, so `monitoring` also protected `my-monitoring`. From 2.2.0, `monitoring` protects only `monitoring`.

Required action, before upgrading:

1. List the namespaces in the cluster (`kubectl get namespaces`) and compare them with your `protected_namespaces` and `additional_protected_namespaces` entries.
2. For each namespace that contains an entry without being equal to it, decide with its owner whether it must stay protected. Protection decides which workloads scale down, so do not change it without that agreement.
3. Keep each namespace protected in one of these ways, preferring the exact name. Use a wildcard only when the namespaces follow a naming convention that new namespaces will also follow.
   - Add its exact name to `additional_protected_namespaces`.
   - Add the `sparkfabrik.com/always-on` label to the namespace. The label takes effect at the next CronJob run, with no Terraform apply.
   - From 2.3.0, add a wildcard pattern such as `*monitoring*` (see [2.3.0](#230)).

If you override `protected_namespaces`, check its entries too. Its default entries are exact system namespace names, so they need no action.
