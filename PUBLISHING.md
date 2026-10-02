# Publishing Mem0 self-hosted

The current template release is `v1.0.1`. The private authoring source is the `mem0` directory in `skyeagle/railway-templates`; both Railway services build from the root of the public `tech-progress/railway-template-mem0` mirror on `release-v1` with separate pinned Dockerfiles. Run `scripts/check-mem0-standalone.sh` from the monorepo before every release.

Apply `.railway/railway.ts` to a source project named `Mem0 self-hosted`, generate domains for the dashboard on port 3000 and API on port 8000, then wait for all three services. Run the authenticated functional smoke test with a real provider key and verify one running, zero crashed replicas per service.

Generate the draft, restore the checked-in defaults, descriptions, volumes, networking ports, build paths, and display name, then deploy the stored draft into a fresh project. Publish only after that deployment and `scripts/audit-template.sh TEMPLATE_ID` pass:

```bash
railway templates publish TEMPLATE_ID \
  --category AI/ML \
  --description "Private AI memory platform with dashboard and persistent pgvector storage." \
  --readme-file MARKETPLACE.md \
  --json
```

Run `scripts/audit-template.sh TEMPLATE_ID PUBLISHED` after publication, stop every source and verification service, confirm zero running instances, delete disposable projects and local test volumes, then update the findings and repository progress. Tag the monorepo release as `mem0-v1.0.1`, tag the public mirror as `v1.0.1`, and move its `release-v1` branch to the same commit.
