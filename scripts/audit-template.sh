#!/usr/bin/env bash
set -euo pipefail

template_id="${1:?Usage: ./scripts/audit-template.sh TEMPLATE_ID [EXPECTED_STATUS]}"
expected_status="${2:-}"
template_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
template_json="$(
  railway api \
    'query Audit($id: String!) { template(id: $id) { name status serializedConfig } }' \
    --var "id=${template_id}" --compact
)"
graph_json="$(cd "${template_root}" && ./node_modules/.bin/railway-iac-ts .railway/railway.ts)"

actual_name="$(jq -r '.data.template.name' <<<"${template_json}")"
actual_services="$(
  jq -r '.data.template.serializedConfig.services | [.[] | .name] | sort | join("\n")' \
    <<<"${template_json}"
)"
[[ "${actual_name}" == "Mem0 self-hosted" ]]
[[ "${actual_services}" == $'Mem0 API\nMem0 Dashboard\nMem0 PostgreSQL' ]]
if [[ -n "${expected_status}" ]]; then
  [[ "$(jq -r '.data.template.status' <<<"${template_json}")" == "${expected_status}" ]]
fi

failures=0
for service_name in "Mem0 API" "Mem0 Dashboard" "Mem0 PostgreSQL"; do
  desired="$(
    jq -c --arg service "${service_name}" \
      '.graph.resources[] | select(.type == "service" and .name == $service)' \
      <<<"${graph_json}"
  )"
  actual="$(
    jq -c --arg service "${service_name}" \
      '[.data.template.serializedConfig.services[] | select(.name == $service)][0]' \
      <<<"${template_json}"
  )"

  if [[ "$(jq -r '.source.type' <<<"${desired}")" == "image" ]]; then
    [[ "$(jq -r '.source.image' <<<"${actual}")" == "$(jq -r '.source.image' <<<"${desired}")" ]] \
      || failures=$((failures + 1))
  else
    expected_repo="$(jq -r '.source.repo' <<<"${desired}")"
    actual_repo="$(jq -r '.source.repo | sub("^https://github.com/"; "") | sub("\\.git$"; "")' <<<"${actual}")"
    [[ "${actual_repo}" == "${expected_repo}" ]] || failures=$((failures + 1))
    for field in branch rootDirectory; do
      [[ "$(jq -r --arg field "${field}" '.source[$field]' <<<"${actual}")" == \
         "$(jq -r --arg field "${field}" '.source[$field]' <<<"${desired}")" ]] \
        || failures=$((failures + 1))
    done
    for field in builder dockerfilePath; do
      [[ "$(jq -r --arg field "${field}" '.build[$field]' <<<"${actual}")" == \
         "$(jq -r --arg field "${field}" '.build[$field]' <<<"${desired}")" ]] \
        || failures=$((failures + 1))
    done
  fi

  expected_health="$(jq -r '.deploy.healthcheckPath // ""' <<<"${desired}")"
  actual_health="$(jq -r '.deploy.healthcheckPath // ""' <<<"${actual}")"
  [[ "${actual_health}" == "${expected_health}" ]] || failures=$((failures + 1))

  while IFS= read -r variable; do
    key="$(jq -r '.key' <<<"${variable}")"
    expected="$(jq -r '.value' <<<"${variable}")"
    value="$(jq -r --arg key "${key}" '.variables[$key].defaultValue // "__MISSING__"' <<<"${actual}")"
    optional="$(jq -r --arg key "${key}" '.variables[$key].isOptional // false' <<<"${actual}")"
    if [[ -z "${expected}" ]]; then
      [[ "${value}" == "__MISSING__" || -z "${value}" ]] || failures=$((failures + 1))
    else
      [[ "${value}" == "${expected}" ]] || failures=$((failures + 1))
    fi
    if [[ "${key}" == "OPENAI_BASE_URL" ]]; then
      [[ "${optional}" == "true" ]] || failures=$((failures + 1))
    else
      [[ "${optional}" == "false" ]] || failures=$((failures + 1))
    fi
  done < <(jq -c --arg service "${service_name}" '.[$service] | to_entries[]' "${template_root}/template-defaults.json")
done

while IFS= read -r service_name; do
  expected="$(jq -c --arg service "${service_name}" '.[$service]' "${template_root}/template-volumes.json")"
  actual="$(
    jq -c --arg service "${service_name}" '
      [.data.template.serializedConfig.services[] | select(.name == $service) |
       .volumeMounts[] | {mountPath,sizeMB}][0]
    ' <<<"${template_json}"
  )"
  [[ "${actual}" == "${expected}" ]] || failures=$((failures + 1))
done < <(jq -r 'keys[]' "${template_root}/template-volumes.json")

for service_name in "Mem0 API" "Mem0 Dashboard"; do
  expected_port="$(jq -r --arg service "${service_name}" '.[$service].publicPort' "${template_root}/template-networking.json")"
  actual_port="$(
    jq -r --arg service "${service_name}" '
      [.data.template.serializedConfig.services[] | select(.name == $service) |
       .networking.serviceDomains["<hasDomain>"].port][0] // 0
    ' <<<"${template_json}"
  )"
  [[ "${actual_port}" == "${expected_port}" ]] || failures=$((failures + 1))
done
postgres_private="$(
  jq -r '[.data.template.serializedConfig.services[] | select(.name == "Mem0 PostgreSQL") |
    (.networking.serviceDomains | length == 0)][0]' <<<"${template_json}"
)"
[[ "${postgres_private}" == "true" ]] || failures=$((failures + 1))

(( failures == 0 )) || {
  echo "Template audit failed with ${failures} mismatch(es)." >&2
  exit 1
}
echo "Template ${template_id} matches the Mem0 source, builds, defaults, volumes, and networking."
