# Shared Database + API Setup (Team)

This setup gives everyone the same PostgreSQL schema/data and backend API using Docker.

## Prerequisites
- Docker Desktop installed and running

## Start everything
From the project root:

```powershell
docker compose up --build
```

This starts:
- PostgreSQL on `localhost:5432`
- FastAPI backend on `http://localhost:5001`

## What gets initialized automatically
On first startup, PostgreSQL runs:
- `flutter_app/sql/create_database` (mounted as `init.sql`)

So every teammate gets the same tables and seed data.

## Flutter API URL
Keep Flutter pointing to backend API (not DB):
- Web/Desktop: `http://localhost:5001/api`
- Android emulator: `http://10.0.2.2:5001/api`

(Already handled by `flutter_app/lib/config/api_config.dart`.)

## Reset database to clean state
```powershell
docker compose down -v
docker compose up --build
```

## Important
Do **not** expose PostgreSQL directly to public internet for app clients.
Clients should only call the FastAPI backend.
