#!/usr/bin/env bash

set -e

BASE=$(dirname "${0}")
# Source the kind-function
# shellcheck disable=SC1091
. "${BASE}/kind.common.sh"

delete_kind_cluster
