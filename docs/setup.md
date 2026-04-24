# Setup Guide

## Prerequisites

Before running the project, make sure you have the following installed:

- Python 3.11+
- Flutter SDK
- PostgreSQL
- Git

## Cloning the Repository

Open a terminal and run:

```bash
git clone https://github.com/fitness-warrior/FitnessApp
cd FitnessApp
```

## Setting up the Database

Make sure PostgreSQL is running, then create a database for the project:

```bash
psql -U postgres
CREATE DATABASE fitnessapp;
```