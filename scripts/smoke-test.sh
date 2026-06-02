#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:-http://localhost:8080}"
BASE_URL="${BASE_URL%/}"

# Smoke test scope:
# 1. Confirm the HTTP listener responds on /metrics.
# 2. Confirm the Auditum API responds to a simple project listing request.

echo "GET ${BASE_URL}/metrics"
curl --silent --show-error --fail "${BASE_URL}/metrics" >/dev/null
echo "metrics endpoint OK"
echo

echo "GET ${BASE_URL}/api/v1alpha1/projects?page_size=1"
curl --silent --show-error --fail \
  --header "Accept: application/json+pretty" \
  "${BASE_URL}/api/v1alpha1/projects?page_size=1"
echo
