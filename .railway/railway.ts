import {
  defineRailway,
  github,
  group,
  preserve,
  project,
  service,
  volume,
} from "railway/iac";

const SOURCE = github("tech-progress/railway-template-mem0", {
  branch: "release-v1",
  rootDirectory: "/",
});

export default defineRailway(() => {
  const postgresData = volume("Mem0 PostgreSQL Data", { sizeMB: 5_000 });
  const historyData = volume("Mem0 History Data", { sizeMB: 1_000 });

  const postgres = service("Mem0 PostgreSQL", {
    source: {
      image:
        "pgvector/pgvector:pg17@sha256:ac08538c6f8b9904c33c8224c5e5706dbe760aca29db1d096972b4052c22a75d",
    },
    volumeMounts: { "/var/lib/postgresql/data": postgresData },
    env: {
      PGDATA: "/var/lib/postgresql/data/pgdata",
      POSTGRES_DB: "postgres",
      POSTGRES_USER: "mem0",
      POSTGRES_PASSWORD: preserve(),
    },
  });

  const api = service("Mem0 API", {
    source: SOURCE,
    build: {
      builder: "DOCKERFILE",
      dockerfilePath: "Dockerfile.api",
      watchPatterns: ["/**", "!/FINDINGS.md"],
    },
    healthcheck: "/docs",
    healthcheckTimeout: 300,
    volumeMounts: { "/app/history": historyData },
    env: {
      PORT: "8000",
      POSTGRES_HOST: postgres.env.RAILWAY_PRIVATE_DOMAIN,
      POSTGRES_PORT: "5432",
      POSTGRES_DB: postgres.env.POSTGRES_DB,
      POSTGRES_USER: postgres.env.POSTGRES_USER,
      POSTGRES_PASSWORD: postgres.env.POSTGRES_PASSWORD,
      POSTGRES_COLLECTION_NAME: "memories",
      APP_DB_NAME: "mem0_app",
      HISTORY_DB_PATH: "/app/history/history.db",
      JWT_SECRET: preserve(),
      ADMIN_API_KEY: preserve(),
      AUTH_DISABLED: "false",
      OPENAI_API_KEY: preserve(),
      OPENAI_BASE_URL: preserve(),
      DASHBOARD_URL: "https://${{Mem0 Dashboard.RAILWAY_PUBLIC_DOMAIN}}",
      MEM0_DEFAULT_LLM_MODEL: "gpt-4.1-nano-2025-04-14",
      MEM0_DEFAULT_EMBEDDER_MODEL: "text-embedding-3-small",
      MEM0_TELEMETRY: "false",
      REQUEST_LOG_RETENTION_DAYS: "30",
    },
  });

  const dashboard = service("Mem0 Dashboard", {
    source: SOURCE,
    build: {
      builder: "DOCKERFILE",
      dockerfilePath: "Dockerfile.dashboard",
      watchPatterns: ["/**", "!/FINDINGS.md"],
    },
    healthcheck: "/api/health",
    healthcheckTimeout: 300,
    env: {
      PORT: "3000",
      NEXT_PUBLIC_API_URL: "https://${{Mem0 API.RAILWAY_PUBLIC_DOMAIN}}",
      API_INTERNAL_URL: "http://${{Mem0 API.RAILWAY_PRIVATE_DOMAIN}}:8000",
      NEXT_PUBLIC_INSTANCE_NAME: "Mem0",
    },
  });

  return project("Mem0 self-hosted", {
    resources: [
      group("Application", [dashboard, api, historyData]),
      group("Data", [postgres, postgresData]),
    ],
  });
});
