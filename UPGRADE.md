# Upgrading Mem0 self-hosted

Template 1.0.1 keeps the existing services, variables, and volume paths. It upgrades both source builds and the Python SDK to 2.2.1 and replaces Node 20 with Node 22. Back up initialized data before the API's automatic Alembic migrations; a successful fresh boot does not establish compatibility with every older database. Deploy the API and dashboard from the same verified template release.

Back up both the PostgreSQL and Mem0 History volumes before changing the pinned upstream commit. The two stores are one logical dataset: PostgreSQL holds vectors and application records, while `/app/history/history.db` holds memory history.

Review upstream server migrations, authentication notes, dashboard environment changes, and the Mem0 Python package release together. Update the commit and archive checksum in both Dockerfiles, keep the `mem0ai` constraint aligned with that release, rebuild both images without cache, and run the empty-volume and initialized-volume smoke tests.

Deploy the candidate into a disposable Railway project before moving the published template. Confirm migrations, dashboard login, a real provider-backed memory write/search/delete cycle, current replica health, and volume attachments. Roll back the source release only when the target schema is compatible; otherwise restore both volume backups as a pair.
