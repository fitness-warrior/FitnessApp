# Setup Guide

## Prerequisites

Before running the project, make sure you have the following installed:

- Python 3.11+
- Flutter SDK
- PostgreSQL
- Git

!!! tip "Recommended: Use Docker"
    The easiest way to run this project is with Docker Compose, which sets up 
    the backend and database automatically. Manual setup is only needed if you 
    are not using Docker.

## Cloning the Repository

Open a terminal and run:

```bash
git clone https://github.com/fitness-warrior/FitnessApp
cd FitnessApp
```

## Option A: Running with Docker

```bash
docker-compose up --build
```

!!! note "First Run"
    The first build may take a few minutes as Docker downloads the required images.

Once running, the backend will be available at `http://localhost:5001`.

## Setting up the Database

!!! warning "PostgreSQL Version"
    Make sure you are running PostgreSQL 16 or above to match the Docker configuration.

Make sure PostgreSQL is running, then create a database for the project:

```bash
psql -U postgres
CREATE DATABASE fitnessapp;
```

### Running the Backend

```bash
cd backend
pip install -r requirements.txt
```
Then start the backend server:

```bash
uvicorn main:app --host 0.0.0.0 --port 5001
```

!!! note "Environment Variable"
    Make sure to set the `DATABASE_URL` environment variable before running:

DATABASE_URL=postgresql://fitness:fitness@localhost:5432/fitnessapp

## Running the Flutter App

```bash
cd flutter_app
flutter pub get
```

```bash
flutter run
```

!!! warning "Backend Must Be Running First"
    Make sure the backend is running on port 5001 before launching the Flutter app, 
    otherwise API calls will fail.