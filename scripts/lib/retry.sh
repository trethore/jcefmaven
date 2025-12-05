#!/bin/bash
# Simple retry wrapper for curl to handle transient network hiccups.
retry_curl() {
  local attempts=${RETRY_ATTEMPTS:-5}
  local delay=${RETRY_DELAY:-2}
  local try=1
  local exit_code=0

  while true; do
    if curl "$@"; then
      return 0
    fi
    exit_code=$?
    if (( try >= attempts )); then
      echo "curl failed after ${attempts} attempts (exit ${exit_code})" >&2
      return $exit_code
    fi
    echo "curl failed (attempt ${try}/${attempts}), retrying in ${delay}s..." >&2
    sleep "$delay"
    (( try++ ))
  done
}
