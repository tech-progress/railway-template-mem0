#!/usr/bin/env bash
set -euo pipefail

template_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
required_files=(
  ".dockerignore" ".env.example" ".gitignore" ".railway/railway.ts"
  "CHANGELOG.md" "Dockerfile.api" "Dockerfile.dashboard"
  "LICENSE_REVIEW.md" "MARKETPLACE.md" "PUBLISHING.md" "README.md"
  "SUPPORT.md" "UPGRADE.md" "VERSION" "bun.lock" "compose.yaml"
  "constraints.txt" "package.json" "requirements-runtime.txt"
  "scripts/audit-template.sh" "scripts/ensure-app-db.py" "scripts/mock-openai.py"
  "scripts/restore-template-draft.sh" "scripts/smoke.sh" "scripts/start-api.sh"
  "scripts/verify.sh" "template-defaults.json" "template-descriptions.json"
  "template-networking.json" "template-volumes.json"
)

for file in "${required_files[@]}"; do
  test -f "${template_root}/${file}" || {
    echo "Missing required file: ${file}" >&2
    exit 1
  }
done

template_version="$(<"${template_root}/VERSION")"
[[ "${template_version}" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]
escaped_version="${template_version//./\\.}"
grep -Eq "^## \\[${escaped_version}\\] - [0-9]{4}-[0-9]{2}-[0-9]{2}$" \
  "${template_root}/CHANGELOG.md"
for file in README.md PUBLISHING.md; do
  grep -Fq "current template release is \`v${template_version}\`" \
    "${template_root}/${file}"
done

POSTGRES_PASSWORD=verify-postgres-password \
  JWT_SECRET=verify-jwt-secret-at-least-32-characters \
  ADMIN_API_KEY=verify-admin-api-key OPENAI_API_KEY=verify-openai-key \
  docker compose -f "${template_root}/compose.yaml" config --quiet

for file in template-defaults.json template-descriptions.json template-networking.json template-volumes.json; do
  jq empty "${template_root}/${file}"
done
for file in scripts/audit-template.sh scripts/restore-template-draft.sh scripts/smoke.sh scripts/start-api.sh scripts/verify.sh; do
  bash -n "${template_root}/${file}"
done
python3 -c 'import pathlib, sys; [compile(pathlib.Path(p).read_text(), p, "exec") for p in sys.argv[1:]]' \
  "${template_root}/scripts/ensure-app-db.py" "${template_root}/scripts/mock-openai.py"

graph_json="$(cd "${template_root}" && ./node_modules/.bin/railway-iac-ts .railway/railway.ts)"
jq -e '
  .graph.resources |
  ([.[] | select(.type == "service") | .name] | sort) ==
    ["Mem0 API", "Mem0 Dashboard", "Mem0 PostgreSQL"] and
  ([.[] | select(.type == "volume")] | length) == 2 and
  ([.[] | select(.name == "Mem0 API")][0].source.repo == "tech-progress/railway-template-mem0") and
  ([.[] | select(.name == "Mem0 API")][0].source.branch == "release-v1") and
  ([.[] | select(.name == "Mem0 API")][0].build.dockerfilePath == "Dockerfile.api") and
  ([.[] | select(.name == "Mem0 API")][0].deploy.healthcheckPath == "/docs") and
  ([.[] | select(.name == "Mem0 Dashboard")][0].build.dockerfilePath == "Dockerfile.dashboard") and
  ([.[] | select(.name == "Mem0 Dashboard")][0].deploy.healthcheckPath == "/api/health")
' <<<"${graph_json}" >/dev/null

pins=(
  "5a2201d76ba2adba7129e53bfeb81634fc8a6ed4"
  "b781700cfa3bd4a4f7cb611d6b9c3d8625b64ee8747274ba5e0b546e88af6c60"
  "sha256:14358309a308569c32bdc37e2e0e9694be33a9d99e68afb0f5ff33cc1f695dce"
  "sha256:57cd7c3a7a273101a6485ba99423ee568157882804b1124b4dd04266317710de"
  "sha256:fb4cd12c85ee03686f6af5362a0b0d56d50c58a04632e6c0fb8363f609372293"
  "sha256:7ae6051efd0e60444282c27c7e141af07f322ce033300e727a49c3dd11075e38"
)
for pin in "${pins[@]}"; do
  grep -Rqs "${pin}" \
    "${template_root}/Dockerfile.api" "${template_root}/Dockerfile.dashboard" \
    "${template_root}/compose.yaml" "${template_root}/.railway/railway.ts"
done

jq -e '
  ."Mem0 API".ADMIN_API_KEY == "${{secret(32)}}" and
  ."Mem0 API".JWT_SECRET == "${{secret(64)}}" and
  ."Mem0 API".AUTH_DISABLED == "false" and
  ."Mem0 API".OPENAI_API_KEY == "" and
  ."Mem0 API".POSTGRES_PASSWORD == "${{Mem0 PostgreSQL.POSTGRES_PASSWORD}}" and
  ."Mem0 PostgreSQL".POSTGRES_PASSWORD == "${{secret(48)}}"
' "${template_root}/template-defaults.json" >/dev/null
jq -e '
  ."Mem0 API" == {mountPath:"/app/history",sizeMB:1000} and
  ."Mem0 PostgreSQL" == {mountPath:"/var/lib/postgresql/data",sizeMB:5000}
' "${template_root}/template-volumes.json" >/dev/null
jq -e '."Mem0 API".publicPort == 8000 and ."Mem0 Dashboard".publicPort == 3000' \
  "${template_root}/template-networking.json" >/dev/null

if find "${template_root}" -type f \( -name ".env" -o -name "*.local" \) -print -quit | grep -q .; then
  echo "Local secret file found in the template directory." >&2
  exit 1
fi

echo "Mem0 template structure, source pins, builds, variables, volumes, and networking are valid."
