#!/usr/bin/env bash
# Tests the Vector config rendered into the vector-audit-rules ConfigMap.
#
# For each tests/auditlog/*.yaml file:
#   1. renders the project chart's auditlog ConfigMap with the given values,
#   2. runs `vector validate` on the rendered config,
#   3. runs each case's event through the decoding VRL program and checks it is accepted or
#      rejected with the expected abort message.
#
# Requires helm, yq, jq and docker. VECTOR_VERSION should match kitapp's audit.image.tag.
set -euo pipefail

VECTOR_IMAGE="timberio/vector:${VECTOR_VERSION:-0.59.0}-distroless-libc"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

failures=0

pass() { printf '  PASS  %s\n' "$1"; }
fail() { printf '  FAIL  %s\n' "$1"; failures=$((failures + 1)); }

# `vector vrl` always exits 0. Accepted events print the object on stdout and rejected events
# print the abort message on stderr. Each event runs in its own container because stdout and
# stderr can interleave out of order when the streams are piped.
run_vrl() {
  local dir="$1"
  docker run --rm -e VECTOR_LOG=error -v "$dir:/w:ro" "$VECTOR_IMAGE" \
    vrl -q -i /w/event.jsonl -p /w/program.vrl -o >"$dir/stdout" 2>"$dir/stderr" || true
}

docker pull -q "$VECTOR_IMAGE" >/dev/null

for test_file in "$ROOT"/tests/auditlog/*.yaml; do
  name="$(basename "$test_file" .yaml)"
  dir="$WORK/$name"
  mkdir -p "$dir"
  yq -o=json '.' "$test_file" >"$dir/test.json"

  echo "== $name"

  helm_args=()
  while IFS= read -r f; do helm_args+=(-f "$ROOT/$f"); done < <(jq -r '.values[]' "$dir/test.json")
  while IFS= read -r s; do helm_args+=(--set "$s"); done < <(jq -r '.set // [] | .[]' "$dir/test.json")

  helm template t "$ROOT/charts/project" "${helm_args[@]}" \
    --show-only templates/auditlog-configmap.yaml | yq '.data."vector.yaml"' >"$dir/vector.yaml"

  if docker run --rm -v "$dir:/w:ro" "$VECTOR_IMAGE" \
    validate --skip-healthchecks /w/vector.yaml >"$dir/validate.log" 2>&1; then
    pass "vector validate"
  else
    fail "vector validate"
    sed 's/^/        /' "$dir/validate.log"
    continue
  fi

  yq '.sources.audit_http_source.decoding.vrl.source' "$dir/vector.yaml" >"$dir/program.vrl"

  count="$(jq '.cases | length' "$dir/test.json")"
  for ((i = 0; i < count; i++)); do
    case_name="$(jq -r ".cases[$i].name" "$dir/test.json")"
    expected="$(jq -r ".cases[$i].expect | if . == \"accept\" then \"accept\" else \"reject: \" + .reject end" "$dir/test.json")"
    # http_server hands the raw request body to the decoder as .message.
    jq -c ".cases[$i].event | {message: tojson}" "$dir/test.json" >"$dir/event.jsonl"

    run_vrl "$dir"
    if [[ -s "$dir/stdout" ]]; then
      actual="accept"
    else
      actual="reject: $(cat "$dir/stderr")"
    fi

    if [[ "$actual" == "$expected" ]]; then
      pass "$case_name"
    else
      fail "$case_name"
      printf '        expected: %s\n        actual:   %s\n' "$expected" "$actual"
    fi
  done
done

if ((failures > 0)); then
  echo "$failures check(s) failed"
  exit 1
fi
echo "All checks passed"
