#!/bin/sh
# Runs files/remove-terminating-pods.sh against a fake kubectl. No cluster needed.

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
SCRIPT="${ROOT}/files/remove-terminating-pods.sh"
WORK=$(mktemp -d "${TMPDIR:-/tmp}/rtp-test.XXXXXX") || exit 1
trap 'rm -rf "${WORK}"' EXIT

mkdir "${WORK}/bin"
cat >"${WORK}/bin/kubectl" <<'FAKE'
#!/bin/sh
# Env: FAKE_LIST (file with the list output), FAKE_LIST_RC, FAKE_CALLS (call log),
# FAKE_MISSING (pod name already gone), FAKE_FORBIDDEN (pod name whose delete is denied).
if [ "$1" = "get" ]; then
  [ "${FAKE_LIST_RC:-0}" -ne 0 ] && { echo "error: list failed" >&2; exit "${FAKE_LIST_RC}"; }
  cat "${FAKE_LIST}"
  exit 0
fi
echo "$*" >>"${FAKE_CALLS}"
for last; do :; done
if [ "${last}" = "${FAKE_FORBIDDEN:-}" ]; then
  echo "Error from server (Forbidden): pods \"${last}\" is forbidden" >&2
  exit 1
fi
if [ "${last}" = "${FAKE_MISSING:-}" ]; then
  case " $* " in
  *" --ignore-not-found "*) exit 0 ;;
  esac
  echo "Error from server (NotFound): pods \"${last}\" not found" >&2
  exit 1
fi
echo "pod \"${last}\" force deleted"
FAKE
chmod +x "${WORK}/bin/kubectl"

FAILURES=0
CASE=0

# run_case <list file content> [VAR=value ...]; sets RC, OUT, ERR, CALLS.
run_case() {
  CASE=$((CASE + 1))
  printf '%s\n' "${1}" >"${WORK}/list"
  shift
  : >"${WORK}/calls"
  RC=0
  env PATH="${WORK}/bin:${PATH}" FAKE_LIST="${WORK}/list" FAKE_CALLS="${WORK}/calls" "$@" \
    sh "${SCRIPT}" >"${WORK}/out" 2>"${WORK}/err" || RC=$?
  OUT=$(cat "${WORK}/out")
  ERR=$(cat "${WORK}/err")
  CALLS=$(cat "${WORK}/calls")
}

check() {
  name="${1}"
  shift
  if "$@"; then
    echo "PASS: ${name}"
  else
    echo "FAIL: ${name}"
    FAILURES=$((FAILURES + 1))
  fi
}

rc_is() { [ "${RC}" -eq "${1}" ]; }
rc_nonzero() { [ "${RC}" -ne 0 ]; }
deleted() { printf '%s\n' "${CALLS}" | grep -q -- "-n ${1} .* ${2}\$"; }
no_calls() { [ -z "${CALLS}" ]; }
both_deleted() { deleted team-a app-1 && deleted team-c app-3; }
out_has() { printf '%s\n' "${OUT}" | grep -q -- "${1}"; }
err_has() { printf '%s\n' "${ERR}" | grep -q -- "${1}"; }
out_lacks() { ! out_has "${1}"; }

LIST_MIXED='team-a   app-1   1/1   Terminating   0   5m
team-a   app-2   1/1   Running   0   5m'

run_case "${LIST_MIXED}" FAKE_MISSING=app-1
check "1 not-found race: exit 0" rc_is 0
check "1 not-found race: no error output" test -z "${ERR}"

run_case "team-a   app-1   1/1   Terminating   0   5m
team-a   app-2   1/1   Terminating   0   5m" FAKE_MISSING=app-1
check "1 not-found race: other pod still deleted" deleted team-a app-2

run_case "team-a   x-terminating-pods-cronjob-1   1/1   Running   0   1m
team-a   x-terminating-pods-cronjob-0   0/1   Completed   0   1h
team-a   app-1   1/1   Terminating   0   5m"
check "2 own pods: exit 0" rc_is 0
check "2 own pods: Running and Completed not deleted" test "$(printf '%s\n' "${CALLS}" | grep -c cronjob)" -eq 0
check "2 own pods: Terminating pod deleted" deleted team-a app-1

run_case "team-a   app-1   1/1   Terminating   0   5m
team-b   app-2   1/1   Terminating   0   5m
team-c   app-3   1/1   Terminating   0   5m" FAKE_FORBIDDEN=app-2
check "3 delete error: non-zero exit" rc_nonzero
check "3 delete error: error on stderr" err_has "Error removing pod team-b/app-2"
check "3 delete error: other pods still deleted" both_deleted
check "3 delete error: no success message" out_lacks "All pods in terminating state are removed"

run_case "${LIST_MIXED}" FAKE_LIST_RC=1
check "4 list failure: non-zero exit" rc_nonzero
check "4 list failure: no delete calls" no_calls
check "4 list failure: error on stderr" err_has "Error listing pods"

run_case "team-a   app-2   1/1   Running   0   5m"
check "5 none terminating: exit 0" rc_is 0
check "5 none terminating: message" out_has "No pods stuck in terminating state to remove."
check "5 none terminating: no delete calls" no_calls

run_case "${LIST_MIXED}" DRY_RUN=1
check "6 dry run: exit 0" rc_is 0
check "6 dry run: no delete calls" no_calls
check "6 dry run: same flags as real delete" out_has \
  "DRY-RUN: kubectl delete pod -n team-a --grace-period=0 --force --wait=false --ignore-not-found app-1"

run_case "${LIST_MIXED}"
check "6 real delete: flags" test "${CALLS}" = \
  "delete pod -n team-a --grace-period=0 --force --wait=false --ignore-not-found app-1"

run_case "team-a   app-1   1/1   Terminating   0   5m
kube-system   dns-1   1/1   Terminating   0   5m" PROTECTED_NAMESPACES="kube-*,other"
check "7 protected namespace: exit 0" rc_is 0
check "7 protected namespace: skipped" out_has "Skipping pod dns-1 in protected namespace kube-system"
check "7 protected namespace: not deleted" test "$(printf '%s\n' "${CALLS}" | grep -c dns-1)" -eq 0
check "7 protected namespace: unprotected deleted" deleted team-a app-1

if [ "${FAILURES}" -ne 0 ]; then
  echo "${FAILURES} check(s) failed"
  exit 1
fi
echo "All checks passed"
