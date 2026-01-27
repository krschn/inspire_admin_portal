# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Development Commands

```bash
flutter pub get              # Install dependencies
flutter run -d chrome        # Run web app (primary target)
flutter analyze              # Static analysis
flutter test                 # Run all tests
flutter test path/to/test.dart  # Run single test file
```

## Architecture Overview

This is a Flutter Web admin portal using **Clean Architecture** with three layers:

### Layer Structure
```
lib/
├── core/                    # Shared utilities, errors, providers
├── features/{feature}/
│   ├── data/               # Models, datasources, repository implementations
│   ├── domain/             # Entities, repository interfaces, use cases
│   └── presentation/       # Providers, pages, widgets
```

### Data Flow Pattern
```
UI Widget → Provider (Riverpod) → UseCase → Repository → DataSource → Firestore
```

### Error Handling
- **Data layer**: Throws custom exceptions (`ServerException`, `NetworkException`)
- **Repository layer**: Catches exceptions, returns `Either<Failure, T>` using fpdart
- **Presentation layer**: Pattern matches on Either, shows errors via `SnackbarService`

```dart
// Repository pattern example
Future<Either<Failure, T>> someMethod() async {
  try {
    final result = await remoteDataSource.fetch();
    return Right(result.toEntity());
  } on NetworkException {
    return const Left(NetworkFailure());
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message));
  }
}
```

### State Management
Uses **Riverpod 3.x** with `AsyncNotifier` for async state and `Notifier` for sync state:
- Use cases are provided via `Provider`
- Feature state uses `AsyncNotifierProvider`
- Simple state uses `NotifierProvider`

### Firestore Structure
```
events/
  └── {eventId}/
      └── talk/
          └── {talkId}/
```

Paths are centralized in `lib/core/constants/firestore_paths.dart`.

### Model Pattern
Models extend their domain entities and provide:
- `fromFirestore(DocumentSnapshot)` - Firestore deserialization
- `fromEntity(Entity)` - Convert domain entity to model
- `toFirestore()` - Firestore serialization
- `toEntity()` - Convert back to domain entity

## Key Dependencies

- **flutter_riverpod**: State management (v3.x - uses Notifier, not StateNotifier)
- **fpdart**: Functional programming (Either type for error handling)
- **cloud_firestore**: Firebase database
- **excel**: Excel file parsing for batch uploads
- **equatable**: Entity equality
