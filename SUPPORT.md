# Supporting Mem0 self-hosted

Check the three service states first. A healthy dashboard with a failing API usually means the browser shell is available while database migrations or provider configuration failed underneath it.

If the API cannot start, inspect its logs for PostgreSQL connectivity and Alembic errors. Confirm `POSTGRES_HOST`, `POSTGRES_USER`, and `POSTGRES_PASSWORD` still reference the private Mem0 PostgreSQL service, and preserve both volumes while diagnosing. The startup wrapper safely creates `mem0_app` when absent and reruns idempotent migrations on every boot.

Provider authentication errors appear when a memory is written or searched, not necessarily at process startup. Verify `OPENAI_API_KEY`, leave `OPENAI_BASE_URL` empty for OpenAI, and confirm the selected models exist at that endpoint. A dashboard CORS error usually means `DASHBOARD_URL` no longer matches the dashboard's exact `https://` Railway domain.

The generated `ADMIN_API_KEY` remains a bootstrap credential even after dashboard users and per-user keys are created. Rotate it as a Railway variable if exposed, and rotate `JWT_SECRET` only when invalidating every dashboard session is acceptable.
