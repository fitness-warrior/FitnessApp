# Setup Guide

## Prerequisites

Before running the project, make sure you have the following installed:

- Python 3.11+
- Flutter SDK
- PostgreSQL
- Git

!!! tip "Recommended: Use Docker"
    The easiest way to run this project is with Docker Compose, which automatically
    sets up the backend and database. Manual setup is only required if Docker
    is not being used.

---

## Cloning the Repository

Open a terminal and run:

```bash
git clone https://github.com/fitness-warrior/FitnessApp
cd FitnessApp
```

---

## Option A: Running with Docker

```bash
docker-compose up --build
```

!!! note "First Run"
    The initial Docker build may take several minutes because the required
    images and dependencies must be downloaded.

Once running, the backend will be available at:

```text
http://localhost:5001
```

---

## Option B: Manual Setup

### Setting up the Database

!!! warning "PostgreSQL Version"
    Make sure PostgreSQL 16 or above is installed to match the project's
    Docker configuration.

Make sure PostgreSQL is running, then create the database:

```sql
psql -U postgres
CREATE DATABASE fitnessapp;
```

---

### Running the Backend

Install the required Python dependencies:

```bash
cd backend
pip install -r requirements.txt
```

!!! note "Environment Variable Required"
    Make sure the `DATABASE_URL` environment variable is configured before
    starting the backend server.

Example:

```bash
DATABASE_URL=postgresql://fitness:fitness@localhost:5432/fitnessapp
```

Start the backend server:

```bash
uvicorn main:app --host 0.0.0.0 --port 5001
```

---

## Running the Flutter App

Install Flutter dependencies:

```bash
cd flutter_app
flutter pub get
```

Launch the application:

```bash
flutter run
```

!!! warning "Backend Must Be Running"
    Ensure the backend server is running on port `5001` before launching
    the Flutter application, otherwise API requests will fail.