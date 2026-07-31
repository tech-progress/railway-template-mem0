#!/usr/bin/env python3
import os
import time

import psycopg
from psycopg import sql


host = os.environ.get("POSTGRES_HOST", "postgres")
port = int(os.environ.get("POSTGRES_PORT", "5432"))
user = os.environ.get("POSTGRES_USER", "postgres")
password = os.environ["POSTGRES_PASSWORD"]
database = os.environ.get("POSTGRES_DB", "postgres")
app_database = os.environ.get("APP_DB_NAME", "mem0_app")

for attempt in range(60):
    try:
        with psycopg.connect(
            host=host,
            port=port,
            user=user,
            password=password,
            dbname=database,
            autocommit=True,
        ) as connection:
            exists = connection.execute(
                "SELECT 1 FROM pg_database WHERE datname = %s", (app_database,)
            ).fetchone()
            if not exists:
                connection.execute(
                    sql.SQL("CREATE DATABASE {}").format(sql.Identifier(app_database))
                )
        break
    except psycopg.OperationalError:
        if attempt == 59:
            raise
        time.sleep(2)
