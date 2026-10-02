# Changelog

## [1.0.1] - 2026-10-02

- Update the Mem0 library and checksum-verified API/dashboard source snapshot together to 2.2.1.
- Replace the end-of-life Node 20 dashboard runtime with Node 22.23.3 and align pnpm with the upstream lockfile.
- Include upstream workspace overrides during the dashboard's frozen dependency install.
- Refresh Python 3.12, Alpine, and PostgreSQL 17/pgvector image digests without changing services, variables, or volume paths.

## [1.0.0] - 2026-07-31

- Add the pinned Mem0 2.0.3 API and dashboard source builds.
- Add authenticated public API and dashboard services backed by private pgvector.
- Persist PostgreSQL data and SQLite memory history on separate Railway volumes.
- Add cold-start migrations, functional smoke tests, and marketplace publication tooling.
