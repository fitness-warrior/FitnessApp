# Project Structure

## Overview

Our Fitness Warrior repository has 2 main directories, those being Flutter frontend and Python backend, along with all the configuration files at root directory.

## Root Directory

```text
FitnessApp/
├── backend/                  # Python/FastAPI backend
├── flutter_app/              # Flutter/Dart frontend
├── docs/                     # Read the Docs documentation
├── site/                     # Auto-generated documentation build (not committed)
├── .github/                  # GitHub Actions workflows
├── .vscode/                  # VS Code workspace settings
├── .gitignore                # Git ignore rules
├── .readthedocs.yaml         # Read the Docs build configuration
├── docker-compose.yml        # Docker configuration for running the full stack
├── mkdocs.yml                # MkDocs documentation configuration
├── package.json              # Project package configuration
├── README.md                 # Project readme
└── requirements.txt          # Python dependencies for documentation
```

## Backend

The backend contains the main API logic. The backend folder is the primary version of our backend. The flutter_app/python folder is an earlier version of the backend that only contains a few specific features.

```text
backend/
├── main.py          # Main FastAPI application — handles auth, workouts,
│                    # meals, streaks, XP and all core API endpoints
├── auth.py          # JWT authentication, password hashing and verification
├── Dockerfile       # Docker configuration for the backend container
└── requirements.txt # Python dependencies for the backend
```

```text
flutter_app/python/
├── database/        # Database helper modules
│   ├── exercise.py      # Exercise filtering and selection
│   ├── workout_save.py  # Workout saving logic
│   ├── login.py         # Login database queries
│   ├── meal_plan.py     # Meal plan database queries
│   ├── workout_plan.py  # Workout plan database queries
│   └── chart_data.py    # Progress chart data queries
└── app.py           # Original FastAPI backend (exercise and workout endpoints)
```

## Flutter App

The lib folder contains all main application code, the views folder is used for the different screens in the app. The services folder holds the business logic.

```text
flutter_app/
├── lib/                      # Main application source code
│   ├── config/               # App configuration and constants
│   ├── data/                 # Data layer and API communication
│   ├── dialogs/              # Reusable dialog components
│   ├── graphs/               # Progress graph components
│   ├── models/               # Data models
│   ├── repositories/         # Repository pattern for data access
│   ├── services/             # Business logic and services
│   ├── views/                # All app screens and pages
│   ├── widgets/              # Reusable UI components
│   └── main.dart             # App entry point
├── python/                   # Additional Python scripts
│   ├── database/             # Database helper scripts
│   └── app.py                # Python app script
├── assets/                   # Static assets
│   └── images/               # Image assets
├── images/                   # Game and costume images
├── sql/                      # SQL scripts for database setup
├── test/                     # Flutter test files
│   ├── models/               # Model tests
│   ├── services/             # Service tests
│   └── widgets/              # Widget tests
├── android/                  # Android platform files
├── web/                      # Web platform files
├── pubspec.yaml              # Flutter dependencies and configuration
└── pubspec.lock              # Locked dependency versions
```

## GitHub Actions

We have used GitHub Actions during this project to automatically run Python tests when code is pushed to the repository.

```text
.github/
└── workflows/
    └── python-tests.yml      # Automated Python test workflow
```

## Documentation

```text
docs/
├── index.md                  # Home page
├── introduction.md           # Project introduction
├── setup.md                  # Setup and installation guide
├── features.md               # Feature descriptions
├── requirements.md           # Functional and non-functional requirements
├── testing.md                # Test plan and results
├── architecture.md           # System architecture
├── projectstructure.md       # Structure of the project
├── authors.md                # Team members
├── futureimprovements.md     # Planned future features
└── usageguide.md             # How to use the app
```