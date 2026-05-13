# Testing

Our FitnessApp project uses various types of testing to allow us to verify the reliability of the applicatinon.

The project includes:

- Backend/API tests
- Integration tests
- Unit tests
- Widget tests

These test ensure reliability across the backend and the frontend of our application.

## Testing Strategy

These different tests validate different parts of functionality throughout the app

Unit tests - Validate individual functions

Integration tests - Test the apps flow between multiple screens

Widget tests - Validate Flutter UI and rendering

Backend tests - Validate API endpoints and database operations

## Running tests

### Running Flutter tests

```bash
flutter test
```

### Running Integration tests

```bash
flutter test integration_test
```