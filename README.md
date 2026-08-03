# Mem0 self-hosted Railway template

This template deploys [Mem0](https://github.com/mem0ai/mem0) `2.0.3` as an authenticated REST API and dashboard backed by a private pgvector/PostgreSQL service. The current template release is `v1.0.0`.

Upstream project: [Mem0](https://mem0.ai).

The API and dashboard are built from upstream commit `5a2201d76ba2adba7129e53bfeb81634fc8a6ed4`; both Dockerfiles verify the source archive checksum before building. PostgreSQL stores vectors, users, API keys, configuration, and request logs, while a separate volume preserves Mem0's SQLite memory-history database.

Railway builds both services from the public `tech-progress/railway-template-mem0` distribution repository on the `release-v1` compatibility branch. Fork maintainers must change the repository in `.railway/railway.ts`, create their own release branch, and authorize Railway's GitHub App for that source.

## Required environment variables

| Variable | Default | Purpose |
| --- | --- | --- |
| `OPENAI_API_KEY` | none | Required OpenAI credential for extraction and embeddings. |
| `OPENAI_BASE_URL` | empty | Optional OpenAI-compatible endpoint; leave empty for OpenAI. |
| `ADMIN_API_KEY` | generated | Bootstrap key for authenticated API calls. |
| `JWT_SECRET` | generated | Signs dashboard sessions. |
| `POSTGRES_PASSWORD` | generated | Protects the private pgvector service. |

The template supplies the remaining ports, database references, model names, CORS origin, and persistence paths. Keep `AUTH_DISABLED=false` on any public deployment.

## Railway use

Deploy the template and provide `OPENAI_API_KEY`. Open the Mem0 Dashboard domain to create the first administrator through `/setup`, or use the generated `ADMIN_API_KEY` as the `X-API-Key` header for programmatic administration. The separately exposed API domain serves the OpenAPI UI at `/docs`; self-hosted routes do not use the hosted platform's `/v1` prefix.

Use the dashboard Configuration page to change supported LLM and embedding providers. This release bundles OpenAI, Anthropic, and Gemini LLM clients, but the default embedder is OpenAI, so an Anthropic-only credential is not enough for the default write/search path.

## Local verification

```bash
cp .env.example .env
docker compose up -d --build --wait
ADMIN_API_KEY=your-admin-key ./scripts/smoke.sh
docker compose down
```

The repository's release test uses the `test` Compose profile and a disposable OpenAI-compatible embedding stub, which proves pgvector writes and reads without consuming a provider credential. The stub is not part of the Railway topology.

## Support boundary

This is a one-replica baseline for small teams and internal agent services. It does not configure high availability, SSO, external log scheduling, private-only API ingress, or local embedding models. Both public services terminate TLS at Railway; PostgreSQL remains private.
