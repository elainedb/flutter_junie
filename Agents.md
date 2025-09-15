# Flutter Clean Architecture Agents Guide

## Overview

This comprehensive guide provides coding agents with architectural patterns, best practices, and implementation strategies for creating robust Flutter applications. Based on analysis of four exemplary Flutter projects, this document establishes standards for clean architecture implementation in modern Flutter development.

## Table of Contents

1. [Core Architectural Principles](#core-architectural-principles)
2. [Project Structure Guidelines](#project-structure-guidelines)
3. [State Management Strategies](#state-management-strategies)
4. [Dependency Injection Patterns](#dependency-injection-patterns)
5. [Testing Strategies](#testing-strategies)
6. [Code Organization](#code-organization)
7. [Technical Stack Recommendations](#technical-stack-recommendations)
8. [Implementation Patterns](#implementation-patterns)
9. [Quality Assurance Guidelines](#quality-assurance-guidelines)
10. [Agent Instructions](#agent-instructions)

---

## Core Architectural Principles

### Clean Architecture Foundation

All Flutter applications MUST follow **Robert C. Martin's Clean Architecture** with strict layer separation:

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                       │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │    UI/Views     │  │   ViewModels    │  │ Controllers  │ │
│  │   (Widgets)     │  │ (State Mgmt)    │  │  (Routing)   │ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Domain Layer                           │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │    Entities     │  │    Use Cases    │  │ Repository   │ │
│  │  (Core Models)  │  │ (Business Logic)│  │ Interfaces   │ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                       Data Layer                            │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │  Repository     │  │  Data Sources   │  │     DTOs     │ │
│  │ Implementation  │  │ (API/Local DB)  │  │   (Models)   │ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
│                                                             │
│  ┌─────────────────┐  ┌─────────────────┐                  │
│  │    Services     │  │     Mappers     │                  │
│  │ (HTTP/Storage)  │  │ (Data Transform)│                  │
│  └─────────────────┘  └─────────────────┘                  │
└─────────────────────────────────────────────────────────────┘
```

### Dependency Rules

1. **Inner layers** MUST NOT depend on outer layers
2. **Dependencies** point inward (Dependency Inversion Principle)
3. **Abstractions** define contracts between layers
4. **Business logic** remains independent of frameworks

### Key Principles

- **Single Responsibility**: Each class has one reason to change
- **Open/Closed**: Open for extension, closed for modification
- **Liskov Substitution**: Derived classes must be substitutable for base classes
- **Interface Segregation**: No client should depend on methods it doesn't use
- **Dependency Inversion**: Depend on abstractions, not concretions

---

## Project Structure Guidelines

### Standard Directory Structure

```
lib/
├── core/                          # Core utilities and abstractions
│   ├── errors/                    # Custom exceptions and error types
│   ├── usecases/                  # Abstract use case base classes
│   ├── utils/                     # Shared utilities and extensions
│   └── constants/                 # Application constants
├── features/                      # Feature-based organization
│   └── [feature_name]/
│       ├── data/
│       │   ├── datasources/       # Remote and local data sources
│       │   ├── models/            # DTOs and data models
│       │   ├── repositories/      # Repository implementations
│       │   └── services/          # External service integrations
│       ├── domain/
│       │   ├── entities/          # Business entities
│       │   ├── repositories/      # Repository interfaces
│       │   └── usecases/          # Business use cases
│       └── presentation/
│           ├── bloc/              # State management (BLoC/Cubit)
│           ├── pages/             # Screen widgets
│           ├── widgets/           # Feature-specific widgets
│           └── viewmodels/        # ViewModels (if not using BLoC)
├── shared/                        # Shared across features
│   ├── widgets/                   # Reusable UI components
│   ├── theme/                     # App theming and styling
│   ├── routing/                   # Navigation configuration
│   └── config/                    # App configuration
├── di.dart                        # Dependency injection setup
└── main.dart                      # Application entry point
```

### Alternative Structures

#### Layer-First Organization (for smaller apps)
```
lib/
├── data/
├── domain/
├── presentation/
├── core/
├── di.dart
└── main.dart
```

#### Hybrid Structure (for medium complexity)
```
lib/
├── config/                        # Dependency injection & configuration
├── data/                          # Cross-cutting data concerns
├── domain/                        # Cross-cutting business logic
├── ui/                            # Feature-organized presentation
│   ├── [feature]/
│   │   ├── viewmodels/
│   │   └── widgets/
│   └── shared/
├── utils/
└── main.dart
```

---

## State Management Strategies

### Primary Recommendations

#### 1. **Flutter BLoC (Recommended)**
Best for: Complex apps, team development, predictable state management

```dart
// BLoC Implementation
@injectable
class UserBloc extends Bloc<UserEvent, UserState> {
  final GetUserUseCase _getUserUseCase;

  UserBloc(this._getUserUseCase) : super(UserInitial()) {
    on<LoadUser>(_onLoadUser);
  }

  Future<void> _onLoadUser(LoadUser event, Emitter<UserState> emit) async {
    emit(UserLoading());

    final result = await _getUserUseCase(GetUserParams(event.userId));

    result.fold(
      (failure) => emit(UserError(failure.message)),
      (user) => emit(UserLoaded(user)),
    );
  }
}

// Usage in Widget
class UserPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        return state.when(
          initial: () => Container(),
          loading: () => CircularProgressIndicator(),
          loaded: (user) => UserWidget(user),
          error: (message) => ErrorWidget(message),
        );
      },
    );
  }
}
```

#### 2. **Provider + ChangeNotifier (Alternative)**
Best for: Simple to medium apps, quick prototyping

```dart
// ViewModel Implementation
class UserViewModel extends ChangeNotifier {
  final GetUserUseCase _getUserUseCase;

  UserState _state = UserState.initial();
  UserState get state => _state;

  UserViewModel(this._getUserUseCase);

  Future<void> loadUser(String userId) async {
    _state = UserState.loading();
    notifyListeners();

    final result = await _getUserUseCase(GetUserParams(userId));

    _state = result.fold(
      (failure) => UserState.error(failure.message),
      (user) => UserState.loaded(user),
    );
    notifyListeners();
  }
}
```

#### 3. **Riverpod (Modern Choice)**
Best for: Type safety, dependency injection, compile-time safety

```dart
// Provider Definition
final userProvider = StateNotifierProvider<UserNotifier, UserState>(
  (ref) => UserNotifier(ref.read(getUserUseCaseProvider)),
);

// Notifier Implementation
class UserNotifier extends StateNotifier<UserState> {
  final GetUserUseCase _getUserUseCase;

  UserNotifier(this._getUserUseCase) : super(UserState.initial());

  Future<void> loadUser(String userId) async {
    state = UserState.loading();

    final result = await _getUserUseCase(GetUserParams(userId));

    state = result.fold(
      (failure) => UserState.error(failure.message),
      (user) => UserState.loaded(user),
    );
  }
}
```

### State Management Selection Matrix

| Criteria | BLoC | Provider | Riverpod | GetIt + ValueNotifier |
|----------|------|----------|----------|----------------------|
| **Complexity** | High | Low | Medium | Low |
| **Learning Curve** | Steep | Easy | Moderate | Easy |
| **Type Safety** | Good | Good | Excellent | Basic |
| **Testing** | Excellent | Good | Good | Good |
| **Performance** | Excellent | Good | Excellent | Good |
| **Team Size** | Large | Small-Medium | Medium-Large | Small |
| **Maintainability** | Excellent | Good | Excellent | Basic |

---

## Dependency Injection Patterns

### Primary Approach: GetIt + Injectable

#### 1. Setup
```dart
// di.dart
final getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async => getIt.init();

// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(MyApp());
}
```

#### 2. Registration Patterns
```dart
// Repository Registration
@LazySingleton(as: UserRepository)
class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource _remoteDataSource;
  final UserLocalDataSource _localDataSource;

  UserRepositoryImpl(this._remoteDataSource, this._localDataSource);

  @override
  Future<Either<Failure, User>> getUser(String id) async {
    try {
      final localUser = await _localDataSource.getUser(id);
      if (localUser != null) return Right(localUser);

      final remoteUser = await _remoteDataSource.getUser(id);
      await _localDataSource.cacheUser(remoteUser);
      return Right(remoteUser);
    } catch (e) {
      return Left(ServerFailure('Failed to get user'));
    }
  }
}

// UseCase Registration
@injectable
class GetUserUseCase extends UseCase<User, GetUserParams> {
  final UserRepository _repository;

  GetUserUseCase(this._repository);

  @override
  Future<Either<Failure, User>> call(GetUserParams params) async {
    return await _repository.getUser(params.userId);
  }
}

// BLoC Registration
@injectable
class UserBloc extends Bloc<UserEvent, UserState> {
  final GetUserUseCase _getUserUseCase;

  UserBloc(this._getUserUseCase) : super(UserInitial());
}
```

#### 3. Environment-Specific Configuration
```dart
// Development Environment
@dev
@LazySingleton(as: ApiClient)
class DevApiClient implements ApiClient {
  @override
  String get baseUrl => 'https://dev-api.example.com';
}

// Production Environment
@prod
@LazySingleton(as: ApiClient)
class ProdApiClient implements ApiClient {
  @override
  String get baseUrl => 'https://api.example.com';
}

// Registration
@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
void configureDependencies() => getIt.init();
```

### Alternative: Provider-Based DI

```dart
class DependencyProvider {
  static List<Provider> get providers => [
    // Data Sources
    Provider<ApiClient>(create: (_) => ApiClientImpl()),
    Provider<DatabaseHelper>(create: (_) => DatabaseHelperImpl()),

    // Repositories
    ProxyProvider2<ApiClient, DatabaseHelper, UserRepository>(
      update: (_, apiClient, dbHelper, __) =>
          UserRepositoryImpl(apiClient, dbHelper),
    ),

    // Use Cases
    ProxyProvider<UserRepository, GetUserUseCase>(
      update: (_, repository, __) => GetUserUseCase(repository),
    ),

    // BLoCs
    ProxyProvider<GetUserUseCase, UserBloc>(
      update: (_, useCase, __) => UserBloc(useCase),
    ),
  ];
}
```

---

## Testing Strategies

### Testing Pyramid Structure

#### 1. Unit Tests (70% of total tests)
Test individual components in isolation:

```dart
// Use Case Test
class MockUserRepository extends Mock implements UserRepository {}

void main() {
  group('GetUserUseCase', () {
    late GetUserUseCase useCase;
    late MockUserRepository mockRepository;

    setUp(() {
      mockRepository = MockUserRepository();
      useCase = GetUserUseCase(mockRepository);
    });

    test('should return user when repository call is successful', () async {
      // Arrange
      const testUser = User(id: '1', name: 'John Doe');
      when(() => mockRepository.getUser(any()))
          .thenAnswer((_) async => const Right(testUser));

      // Act
      final result = await useCase(const GetUserParams('1'));

      // Assert
      expect(result, const Right(testUser));
      verify(() => mockRepository.getUser('1'));
      verifyNoMoreInteractions(mockRepository);
    });
  });
}
```

#### 2. Widget Tests (20% of total tests)
Test UI components and user interactions:

```dart
void main() {
  group('UserPage Widget Tests', () {
    late MockUserBloc mockUserBloc;

    setUp(() {
      mockUserBloc = MockUserBloc();
    });

    testWidgets('should display loading indicator when state is loading',
      (WidgetTester tester) async {
      // Arrange
      when(() => mockUserBloc.state).thenReturn(UserLoading());

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<UserBloc>(
            create: (_) => mockUserBloc,
            child: UserPage(),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should load user when refresh is triggered',
      (WidgetTester tester) async {
      // Arrange
      when(() => mockUserBloc.state).thenReturn(UserLoaded(testUser));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.fling(find.byType(ListView), Offset(0, 300), 1000);
      await tester.pump();

      // Assert
      verify(() => mockUserBloc.add(LoadUser('1')));
    });
  });
}
```

#### 3. Integration Tests (10% of total tests)
Test complete user journeys:

```dart
void main() {
  group('User Flow Integration Tests', () {
    testWidgets('complete user login and data loading flow',
      (WidgetTester tester) async {
      // Setup app with real dependencies
      await tester.pumpWidget(MyApp());

      // Navigate to login
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      // Enter credentials
      await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');
      await tester.tap(find.byKey(const Key('submit_button')));
      await tester.pumpAndSettle();

      // Verify navigation to home page
      expect(find.byKey(const Key('home_page')), findsOneWidget);

      // Verify user data is loaded
      expect(find.text('Welcome, John!'), findsOneWidget);
    });
  });
}
```

### Test Doubles Strategy

#### 1. Fake Implementations (Preferred for complex objects)
```dart
class FakeUserRepository implements UserRepository {
  final Map<String, User> _users = {
    '1': User(id: '1', name: 'John Doe'),
    '2': User(id: '2', name: 'Jane Smith'),
  };

  @override
  Future<Either<Failure, User>> getUser(String id) async {
    await Future.delayed(Duration(milliseconds: 100)); // Simulate network delay

    final user = _users[id];
    if (user != null) {
      return Right(user);
    } else {
      return Left(NotFoundFailure('User not found'));
    }
  }
}
```

#### 2. Mock Objects (For simple interfaces)
```dart
class MockApiClient extends Mock implements ApiClient {}
class MockDatabaseHelper extends Mock implements DatabaseHelper {}
```

#### 3. Test Fixtures
```dart
// test_fixtures.dart
class TestFixtures {
  static const User johnDoe = User(
    id: '1',
    name: 'John Doe',
    email: 'john@example.com',
  );

  static const User janeSmith = User(
    id: '2',
    name: 'Jane Smith',
    email: 'jane@example.com',
  );

  static final List<User> userList = [johnDoe, janeSmith];
}
```

### BLoC Testing with bloc_test

```dart
void main() {
  group('UserBloc', () {
    late MockGetUserUseCase mockGetUserUseCase;
    late UserBloc userBloc;

    setUp(() {
      mockGetUserUseCase = MockGetUserUseCase();
      userBloc = UserBloc(mockGetUserUseCase);
    });

    blocTest<UserBloc, UserState>(
      'emits [UserLoading, UserLoaded] when LoadUser is successful',
      build: () {
        when(() => mockGetUserUseCase(any()))
            .thenAnswer((_) async => Right(TestFixtures.johnDoe));
        return userBloc;
      },
      act: (bloc) => bloc.add(LoadUser('1')),
      expect: () => [
        UserLoading(),
        UserLoaded(TestFixtures.johnDoe),
      ],
      verify: (_) {
        verify(() => mockGetUserUseCase(GetUserParams('1'))).called(1);
      },
    );
  });
}
```

### Test Coverage Requirements

- **Minimum Coverage**: 80% overall
- **Critical Paths**: 95% coverage for business logic
- **UI Components**: 70% coverage for widgets
- **Error Scenarios**: 100% coverage for error handling

---

## Code Organization

### Feature-Based Organization

```
features/
├── authentication/
│   ├── data/
│   │   ├── datasources/
│   │   │   ├── auth_remote_datasource.dart
│   │   │   └── auth_local_datasource.dart
│   │   ├── models/
│   │   │   ├── user_model.dart
│   │   │   └── login_request_model.dart
│   │   └── repositories/
│   │       └── auth_repository_impl.dart
│   ├── domain/
│   │   ├── entities/
│   │   │   └── user.dart
│   │   ├── repositories/
│   │   │   └── auth_repository.dart
│   │   └── usecases/
│   │       ├── login_usecase.dart
│   │       ├── logout_usecase.dart
│   │       └── get_current_user_usecase.dart
│   └── presentation/
│       ├── bloc/
│       │   ├── auth_bloc.dart
│       │   ├── auth_event.dart
│       │   └── auth_state.dart
│       ├── pages/
│       │   ├── login_page.dart
│       │   └── register_page.dart
│       └── widgets/
│           ├── login_form.dart
│           └── auth_button.dart
├── profile/
└── settings/
```

### Naming Conventions

#### Files and Classes
- **Files**: snake_case (e.g., `user_repository_impl.dart`)
- **Classes**: PascalCase (e.g., `UserRepositoryImpl`)
- **Methods**: camelCase (e.g., `getCurrentUser()`)
- **Constants**: SCREAMING_SNAKE_CASE (e.g., `API_BASE_URL`)

#### Architecture-Specific Naming
- **Entities**: Domain objects (e.g., `User`, `Product`)
- **Models**: Data transfer objects with `Model` suffix (e.g., `UserModel`)
- **Repositories**: Interface without suffix, implementation with `Impl` (e.g., `UserRepository`, `UserRepositoryImpl`)
- **Use Cases**: Action-based naming (e.g., `GetUserUseCase`, `CreateOrderUseCase`)
- **BLoCs**: Feature-based with `Bloc` suffix (e.g., `UserBloc`, `OrderBloc`)

### Import Organization

```dart
// System imports
import 'dart:async';
import 'dart:convert';

// Flutter SDK imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// External package imports
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

// Internal imports - Core
import '../../../core/error/exceptions.dart';
import '../../../core/error/failures.dart';

// Internal imports - Feature
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../models/user_model.dart';
```

---

## Technical Stack Recommendations

### Essential Dependencies

#### State Management
```yaml
dependencies:
  # BLoC Pattern (Primary)
  flutter_bloc: ^8.1.3
  bloc_concurrency: ^0.2.2

  # Alternative: Provider
  provider: ^6.1.2

  # Alternative: Riverpod
  flutter_riverpod: ^2.4.9
```

#### Dependency Injection
```yaml
dependencies:
  get_it: ^8.0.3
  injectable: ^2.5.0

dev_dependencies:
  injectable_generator: ^2.7.0
  build_runner: ^2.4.15
```

#### Networking
```yaml
dependencies:
  dio: ^5.4.0
  retrofit: ^4.1.0         # Optional: Type-safe HTTP client
  json_annotation: ^4.9.0

dev_dependencies:
  retrofit_generator: ^8.0.4
  json_serializable: ^6.9.5
```

#### Local Storage
```yaml
dependencies:
  # NoSQL
  hive: ^2.2.3
  hive_flutter: ^1.1.0

  # SQL Alternative
  drift: ^2.14.1
  sqlite3_flutter_libs: ^0.5.20

  # Simple Key-Value
  shared_preferences: ^2.3.5

dev_dependencies:
  hive_generator: ^2.0.1
  drift_dev: ^2.14.1
```

#### Navigation
```yaml
dependencies:
  # Declarative Routing (Recommended)
  go_router: ^16.0.0

  # Alternative: Code Generation
  auto_route: ^9.0.1

dev_dependencies:
  auto_route_generator: ^9.0.1
```

#### Utilities
```yaml
dependencies:
  freezed_annotation: ^3.0.0
  equatable: ^2.0.5
  dartz: ^0.10.1           # Functional programming (Either, Option)
  cached_network_image: ^3.4.1
  intl: ^0.20.2           # Internationalization

dev_dependencies:
  freezed: ^3.0.6
  build_runner: ^2.4.15
```

#### Testing
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  bloc_test: ^9.1.5
  mocktail: ^1.0.3
  integration_test:
    sdk: flutter
  flutter_lints: ^5.0.0
```

### Optional Enhancements

#### Code Generation
```yaml
dependencies:
  flutter_gen_runner: ^5.10.0    # Asset generation

dev_dependencies:
  flutter_gen_runner: ^5.10.0
```

#### UI/UX
```yaml
dependencies:
  google_fonts: ^6.2.1
  flutter_animate: ^4.2.0
  lottie: ^3.1.0
  shimmer: ^3.0.0
```

#### Performance
```yaml
dependencies:
  flutter_displaymode: ^0.6.0    # High refresh rate
  visibility_detector: ^0.4.0+2  # Widget visibility
```

---

## Implementation Patterns

### 1. Repository Pattern

#### Interface Definition
```dart
abstract class UserRepository {
  Future<Either<Failure, User>> getUser(String id);
  Future<Either<Failure, List<User>>> getUsers();
  Future<Either<Failure, User>> createUser(CreateUserParams params);
  Future<Either<Failure, User>> updateUser(UpdateUserParams params);
  Future<Either<Failure, void>> deleteUser(String id);
  Stream<List<User>> watchUsers();
}
```

#### Implementation
```dart
@LazySingleton(as: UserRepository)
class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource _remoteDataSource;
  final UserLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;

  UserRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._networkInfo,
  );

  @override
  Future<Either<Failure, User>> getUser(String id) async {
    try {
      if (await _networkInfo.isConnected) {
        final remoteUser = await _remoteDataSource.getUser(id);
        await _localDataSource.cacheUser(remoteUser);
        return Right(remoteUser.toEntity());
      } else {
        final localUser = await _localDataSource.getUser(id);
        return Right(localUser.toEntity());
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Stream<List<User>> watchUsers() {
    return _localDataSource.watchUsers()
        .map((models) => models.map((m) => m.toEntity()).toList());
  }
}
```

### 2. Use Case Pattern

#### Abstract Base Class
```dart
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class NoParams extends Equatable {
  @override
  List<Object> get props => [];
}
```

#### Concrete Implementation
```dart
@injectable
class GetUserUseCase extends UseCase<User, GetUserParams> {
  final UserRepository _repository;

  GetUserUseCase(this._repository);

  @override
  Future<Either<Failure, User>> call(GetUserParams params) async {
    return await _repository.getUser(params.userId);
  }
}

@freezed
class GetUserParams with _$GetUserParams {
  const factory GetUserParams({
    required String userId,
  }) = _GetUserParams;
}
```

### 3. BLoC State Management

#### Event Definition
```dart
@freezed
class UserEvent with _$UserEvent {
  const factory UserEvent.loadUser(String userId) = LoadUser;
  const factory UserEvent.refreshUser() = RefreshUser;
  const factory UserEvent.updateUser(UpdateUserParams params) = UpdateUser;
}
```

#### State Definition
```dart
@freezed
class UserState with _$UserState {
  const factory UserState.initial() = UserInitial;
  const factory UserState.loading() = UserLoading;
  const factory UserState.loaded(User user) = UserLoaded;
  const factory UserState.error(String message) = UserError;
}
```

#### BLoC Implementation
```dart
@injectable
class UserBloc extends Bloc<UserEvent, UserState> {
  final GetUserUseCase _getUserUseCase;
  final UpdateUserUseCase _updateUserUseCase;

  UserBloc(
    this._getUserUseCase,
    this._updateUserUseCase,
  ) : super(const UserState.initial()) {
    on<LoadUser>(_onLoadUser);
    on<RefreshUser>(_onRefreshUser);
    on<UpdateUser>(_onUpdateUser);
  }

  Future<void> _onLoadUser(LoadUser event, Emitter<UserState> emit) async {
    emit(const UserState.loading());

    final result = await _getUserUseCase(GetUserParams(userId: event.userId));

    result.fold(
      (failure) => emit(UserState.error(failure.message)),
      (user) => emit(UserState.loaded(user)),
    );
  }

  Future<void> _onRefreshUser(RefreshUser event, Emitter<UserState> emit) async {
    if (state is UserLoaded) {
      final currentUser = (state as UserLoaded).user;
      final result = await _getUserUseCase(GetUserParams(userId: currentUser.id));

      result.fold(
        (failure) => emit(UserState.error(failure.message)),
        (user) => emit(UserState.loaded(user)),
      );
    }
  }

  Future<void> _onUpdateUser(UpdateUser event, Emitter<UserState> emit) async {
    if (state is UserLoaded) {
      final result = await _updateUserUseCase(event.params);

      result.fold(
        (failure) => emit(UserState.error(failure.message)),
        (user) => emit(UserState.loaded(user)),
      );
    }
  }
}
```

### 4. Data Model Pattern

#### Entity (Domain Layer)
```dart
@freezed
class User with _$User {
  const factory User({
    required String id,
    required String name,
    required String email,
    String? avatar,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _User;

  // Business logic methods
  bool get hasAvatar => avatar != null && avatar!.isNotEmpty;
  bool get isRecentlyCreated =>
      DateTime.now().difference(createdAt).inDays < 30;
}
```

#### Model (Data Layer)
```dart
@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String name,
    required String email,
    String? avatar,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  // Conversion methods
  User toEntity() => User(
    id: id,
    name: name,
    email: email,
    avatar: avatar,
    createdAt: DateTime.parse(createdAt),
    updatedAt: DateTime.parse(updatedAt),
  );

  static UserModel fromEntity(User entity) => UserModel(
    id: entity.id,
    name: entity.name,
    email: entity.email,
    avatar: entity.avatar,
    createdAt: entity.createdAt.toIso8601String(),
    updatedAt: entity.updatedAt.toIso8601String(),
  );
}
```

### 5. Error Handling Pattern

#### Exception Hierarchy
```dart
abstract class AppException implements Exception {
  final String message;
  const AppException(this.message);
}

class ServerException extends AppException {
  const ServerException(super.message);
}

class CacheException extends AppException {
  const CacheException(super.message);
}

class NetworkException extends AppException {
  const NetworkException(super.message);
}
```

#### Failure Hierarchy
```dart
@freezed
class Failure with _$Failure {
  const factory Failure.server(String message) = ServerFailure;
  const factory Failure.cache(String message) = CacheFailure;
  const factory Failure.network(String message) = NetworkFailure;
  const factory Failure.validation(String message) = ValidationFailure;
  const factory Failure.unexpected(String message) = UnexpectedFailure;
}

extension FailureX on Failure {
  String get message => when(
    server: (message) => message,
    cache: (message) => message,
    network: (message) => message,
    validation: (message) => message,
    unexpected: (message) => message,
  );
}
```

### 6. Network Layer Pattern

#### API Client Setup
```dart
@injectable
class ApiClient {
  late final Dio _dio;

  ApiClient(@Named('baseUrl') String baseUrl) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: Duration(seconds: 30),
      receiveTimeout: Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.addAll([
      LogInterceptor(requestBody: true, responseBody: true),
      AuthInterceptor(),
      ErrorInterceptor(),
    ]);
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) =>
      _dio.get(path, queryParameters: queryParameters);

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);

  Future<Response> delete(String path) =>
      _dio.delete(path);
}

// Retrofit alternative for type safety
@RestApi()
abstract class UserApiService {
  factory UserApiService(Dio dio) = _UserApiService;

  @GET('/users/{id}')
  Future<UserModel> getUser(@Path('id') String id);

  @GET('/users')
  Future<List<UserModel>> getUsers(@Queries() Map<String, dynamic> queries);

  @POST('/users')
  Future<UserModel> createUser(@Body() CreateUserRequest request);
}
```

---

## Quality Assurance Guidelines

### Code Quality Standards

#### Static Analysis
```yaml
# analysis_options.yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - always_declare_return_types
    - always_use_package_imports
    - avoid_dynamic_calls
    - avoid_empty_else
    - avoid_relative_lib_imports
    - prefer_single_quotes
    - sort_constructors_first
    - sort_unnamed_constructors_first
    - unawaited_futures
    - use_super_parameters

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
  errors:
    invalid_annotation_target: ignore
```

#### Formatting Standards
```yaml
# Dart format configuration
line-length: 100
```

### Documentation Standards

#### Class Documentation
```dart
/// Repository responsible for managing user data.
///
/// Handles both local and remote data sources, implementing caching strategies
/// for optimal performance and offline support.
///
/// Throws [ServerException] when remote operations fail.
/// Throws [CacheException] when local operations fail.
abstract class UserRepository {
  /// Retrieves a user by their unique identifier.
  ///
  /// Returns [User] if found, otherwise returns [Failure].
  /// Checks local cache first, falls back to remote if needed.
  Future<Either<Failure, User>> getUser(String id);
}
```

#### Method Documentation
```dart
/// Creates a new user account with the provided information.
///
/// Validates user data before creation and ensures email uniqueness.
/// Automatically generates a unique user ID and timestamps.
///
/// Parameters:
/// - [params]: User creation parameters including name, email, etc.
///
/// Returns:
/// - [Right<User>]: Successfully created user
/// - [Left<ValidationFailure>]: Invalid user data
/// - [Left<ServerFailure>]: Server-side creation error
///
/// Throws:
/// - [ServerException]: When remote API is unreachable
///
/// Example:
/// ```dart
/// final result = await repository.createUser(
///   CreateUserParams(name: 'John', email: 'john@example.com'),
/// );
/// ```
Future<Either<Failure, User>> createUser(CreateUserParams params);
```

### Performance Guidelines

#### Widget Optimization
```dart
// Use const constructors when possible
class UserCard extends StatelessWidget {
  const UserCard({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(user.name),
        subtitle: Text(user.email),
      ),
    );
  }
}

// Optimize rebuilds with selective BlocBuilder
class UserPageContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Only rebuilds when user data changes
        BlocBuilder<UserBloc, UserState>(
          buildWhen: (previous, current) =>
              previous != current && current is UserLoaded,
          builder: (context, state) {
            return state.maybeWhen(
              loaded: (user) => UserProfile(user: user),
              orElse: () => Container(),
            );
          },
        ),

        // Static content doesn't rebuild
        const SizedBox(height: 16),
        const ActionButtons(),
      ],
    );
  }
}
```

#### Memory Management
```dart
class UserBloc extends Bloc<UserEvent, UserState> {
  StreamSubscription? _userSubscription;

  UserBloc(this._getUserUseCase) : super(const UserState.initial()) {
    on<LoadUser>(_onLoadUser);
    on<WatchUser>(_onWatchUser);
  }

  Future<void> _onWatchUser(WatchUser event, Emitter<UserState> emit) async {
    await _userSubscription?.cancel();

    _userSubscription = _getUserUseCase.watchUser(event.userId).listen(
      (user) => add(UserLoaded(user)),
    );
  }

  @override
  Future<void> close() {
    _userSubscription?.cancel();
    return super.close();
  }
}
```

---

## Agent Instructions

### For New Project Creation

When creating a new Flutter project, agents MUST follow this sequence:

#### 1. Project Initialization
```bash
# Create Flutter project
flutter create --org com.yourcompany project_name
cd project_name

# Add essential dependencies
flutter pub add flutter_bloc bloc_concurrency get_it injectable dio freezed_annotation json_annotation equatable dartz cached_network_image

# Add dev dependencies
flutter pub add -d flutter_test bloc_test mocktail injectable_generator build_runner freezed json_serializable flutter_lints
```

#### 2. Directory Structure Setup
```bash
# Create core architecture directories
mkdir -p lib/{core/{error,usecases,utils,constants},features,shared/{widgets,theme,routing,config}}

# Create standard subdirectories
mkdir -p lib/core/{error,usecases,utils,constants}
mkdir -p lib/shared/{widgets,theme,routing,config}
```

#### 3. Core File Generation
Create these files in order:

1. `lib/core/error/exceptions.dart` - Exception definitions
2. `lib/core/error/failures.dart` - Failure types
3. `lib/core/usecases/usecase.dart` - UseCase base class
4. `lib/di.dart` - Dependency injection setup
5. `pubspec.yaml` updates with dependencies

#### 4. Feature Implementation
For each feature, create:

1. **Domain layer first**: Entities, repository interfaces, use cases
2. **Data layer second**: Models, data sources, repository implementations
3. **Presentation layer third**: BLoC/ViewModels, pages, widgets

#### 5. Testing Setup
Create test structure mirroring lib/ structure and add:

1. Test fixtures and helpers
2. Mock/fake implementations
3. Unit tests for each component
4. Widget tests for UI components

### Code Generation Requirements

Agents MUST run code generation after creating freezed/json classes:

```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### Quality Checks

Before completing any feature, agents MUST:

1. Run `flutter analyze` and fix all issues
2. Run `flutter test` and ensure all tests pass
3. Check test coverage meets minimum 80% requirement
4. Verify all public APIs have documentation
5. Ensure consistent naming conventions throughout

### Common Patterns Agents Should Follow

#### 1. Always Use Freezed for Data Classes
```dart
@freezed
class User with _$User {
  const factory User({
    required String id,
    required String name,
  }) = _User;
}
```

#### 2. Always Use Either for Error Handling
```dart
Future<Either<Failure, User>> getUser(String id);
```

#### 3. Always Use BLoC for State Management
```dart
@injectable
class FeatureBloc extends Bloc<FeatureEvent, FeatureState> {
  // Implementation
}
```

#### 4. Always Use Repository Pattern
```dart
abstract class FeatureRepository {
  // Interface methods
}

@LazySingleton(as: FeatureRepository)
class FeatureRepositoryImpl implements FeatureRepository {
  // Implementation
}
```

#### 5. Always Create Comprehensive Tests
```dart
// Unit tests
void main() {
  group('FeatureBloc', () {
    // Test implementation
  });
}

// Widget tests
void main() {
  testWidgets('Feature page displays correctly', (tester) async {
    // Test implementation
  });
}
```

### Forbidden Practices

Agents MUST NOT:

1. Use `setState` in complex state management scenarios
2. Put business logic in widgets
3. Make direct API calls from UI components
4. Skip error handling in repository implementations
5. Create features without corresponding tests
6. Use dynamic types without strong justification
7. Ignore static analysis warnings
8. Create classes without proper documentation

### Performance Considerations

Agents SHOULD:

1. Use `const` constructors wherever possible
2. Implement selective rebuilding with BlocBuilder conditions
3. Dispose of resources properly in BLoC close() methods
4. Use ListView.builder for large lists
5. Implement proper image caching with CachedNetworkImage
6. Use efficient data structures for collections

### Accessibility Requirements

Agents MUST ensure:

1. All interactive elements have semantic labels
2. Sufficient color contrast ratios
3. Proper focus management
4. Screen reader compatibility
5. Keyboard navigation support

### Security Guidelines

Agents MUST:

1. Never hardcode API keys or sensitive data
2. Implement proper input validation
3. Use secure storage for sensitive information
4. Implement proper authentication token handling
5. Follow HTTPS best practices

---

## Conclusion

This comprehensive guide provides the foundation for creating robust, scalable, and maintainable Flutter applications following Clean Architecture principles. Agents following these guidelines will produce high-quality code that meets industry standards for enterprise Flutter development.

The patterns and practices outlined here are based on analysis of proven production applications and represent current best practices in the Flutter ecosystem. Regular updates to this guide should reflect evolving patterns and new framework capabilities.

Remember: **Architecture is not about perfection, but about making informed decisions that support long-term maintainability and team productivity.**