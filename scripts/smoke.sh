#!/usr/bin/env bash
set -euo pipefail

api_url="${1:-http://127.0.0.1:8888}"
dashboard_url="${2:-http://127.0.0.1:3000}"
admin_api_key="${ADMIN_API_KEY:?ADMIN_API_KEY is required}"
smoke_user="railway-smoke-$(date +%s)"

curl --fail --silent --show-error \
  --retry 24 --retry-delay 5 --retry-all-errors \
  "${api_url}/docs" | grep -Fq "Mem0 REST APIs"

dashboard_health="$(
  curl --fail --silent --show-error \
    --retry 24 --retry-delay 5 --retry-all-errors \
    "${dashboard_url}/api/health"
)"
jq -e '.status == "ok"' <<<"${dashboard_health}" >/dev/null

config="$(
  curl --fail --silent --show-error \
    --header "X-API-Key: ${admin_api_key}" \
    "${api_url}/configure"
)"
jq -e '
  .vector_store.provider == "pgvector" and
  .llm.provider == "openai" and
  .embedder.provider == "openai"
' <<<"${config}" >/dev/null

created="$(
  curl --fail --silent --show-error \
    --header "Content-Type: application/json" \
    --header "X-API-Key: ${admin_api_key}" \
    --data "$(jq -nc --arg user "${smoke_user}" '
      {messages:[{role:"user",content:"Railway functional smoke memory"}],user_id:$user,infer:false}
    ')" \
    "${api_url}/memories"
)"
memory_id="$(jq -r 'if type == "array" then .[0].id else (.results[0].id // .id // empty) end' <<<"${created}")"
[[ -n "${memory_id}" ]]

listed="$(
  curl --fail --silent --show-error \
    --header "X-API-Key: ${admin_api_key}" \
    "${api_url}/memories?user_id=${smoke_user}"
)"
jq -e --arg id "${memory_id}" '
  [(.results // .)[] | select(.id == $id)] | length == 1
' <<<"${listed}" >/dev/null

curl --fail --silent --show-error \
  --request DELETE \
  --header "X-API-Key: ${admin_api_key}" \
  "${api_url}/memories/${memory_id}" >/dev/null

echo "Mem0 API, dashboard, authentication, pgvector write/read, and cleanup checks passed."
