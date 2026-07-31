# Deploy and Host Mem0 Self-Hosted on Railway

Deploy Mem0 `2.0.3` as an authenticated memory API and team dashboard with private pgvector storage and persistent memory history. The template builds from a checksum-verified upstream commit, runs database migrations automatically, and generates the database, JWT, and administrator secrets.

## About Hosting Mem0 Self-Hosted

Mem0 gives AI agents and applications persistent user, agent, and run memory through a REST API. This Railway topology runs the API, the browser dashboard, and PostgreSQL as separate services, so the database stays on Railway's private network while the two HTTP surfaces receive managed TLS domains.

## Why Deploy Mem0 Self-Hosted on Railway

The deployment keeps authentication enabled and persists both pgvector data and Mem0's SQLite history file, so application restarts do not split current memories from their change history. Railway injects private service references and generated secrets, while you supply the external LLM/embedding credential that actually processes memory operations.

## Common Use Cases

- Give support, sales, or personal-assistant agents durable user preferences across sessions.
- Share one authenticated memory service across several internal applications.
- Inspect memories, entities, API keys, configuration, and request logs through the dashboard.
- Use an OpenAI-compatible provider by setting `OPENAI_BASE_URL` alongside its API key.

## Dependencies for Mem0 Self-Hosted

Mem0 requires an OpenAI key for the default LLM and embedding path. The API also supports the bundled Anthropic and Gemini LLM integrations, but a working embedder remains required for writes and semantic search.

### Deployment Dependencies

- Mem0 API `2.0.3`, built from pinned upstream source
- Mem0 Dashboard from the same pinned upstream commit
- pgvector on PostgreSQL 17 with a persistent volume
- A persistent volume for Mem0's SQLite history database
- `OPENAI_API_KEY`, or an equivalent credential plus `OPENAI_BASE_URL`
