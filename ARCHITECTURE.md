# Gemura - Architectural Design

## 🏗️ System Architecture Overview

Gemura follows a **Clean Architecture** pattern with **Domain-Driven Design (DDD)** principles, ensuring separation of concerns, testability, and maintainability.

## 📐 Architecture Layers

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                      │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐        │
│  │   Screens   │ │  Widgets    │ │  Providers  │        │
│  └─────────────┘ └─────────────┘ └─────────────┘        │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                     Domain Layer                           │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐        │
│  │   Models    │ │  Entities   │ │ Use Cases   │        │
│  └─────────────┘ └─────────────┘ └─────────────┘        │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                     Data Layer                             │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐        │
│  │ Repositories│ │ Data Sources│ │   Models    │        │
│  └─────────────┘ └─────────────┘ └─────────────┘        │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                   Infrastructure Layer                      │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐        │
│  │   Network   │ │   Storage   │ │   External  │        │
│  │   Services  │ │   Services  │ │   Services  │        │
│  └─────────────┘ └─────────────┘ └─────────────┘        │
└─────────────────────────────────────────────────────────────┘
```

## 🎯 Design Principles

### **1. Clean Architecture**
- **Independence**: Each layer is independent of others
- **Dependency Rule**: Dependencies point inward (Domain → Data → Infrastructure)
- **Testability**: Each layer can be tested in isolation
- **Maintainability**: Changes in one layer don't affect others

### **2. Domain-Driven Design**
- **Ubiquitous Language**: Business terms used consistently
- **Bounded Contexts**: Clear boundaries between features
- **Aggregates**: Business entities with clear boundaries
- **Value Objects**: Immutable objects representing concepts

### **3. SOLID Principles**
- **Single Responsibility**: Each class has one reason to change
- **Open/Closed**: Open for extension, closed for modification
- **Liskov Substitution**: Subtypes are substitutable
- **Interface Segregation**: Small, focused interfaces
- **Dependency Inversion**: Depend on abstractions, not concretions

## 🏛️ Layer Details

### **Presentation Layer**

#### **Structure**
```
lib/features/{feature}/presentation/
├── screens/
│   ├── {feature}_screen.dart
│   └── {feature}_details_screen.dart
├── widgets/
│   ├── {feature}_card.dart
│   └── {feature}_form.dart
└── providers/
    └── {feature}_provider.dart
```

#### **Responsibilities**
- **UI Components**: Screens, widgets, forms
- **State Management**: Riverpod providers
- **Navigation**: Screen routing and transitions
- **User Input**: Form validation and handling

#### **Key Components**
```dart
// Example: Auth Provider
class AuthProvider extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  
  AuthProvider(this._repository) : super(AuthState.initial());
  
  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _repository.signIn(email, password);
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}
```

### **Domain Layer**

#### **Structure**
```
lib/features/{feature}/domain/
├── models/
│   ├── {entity}.dart
│   └── {value_object}.dart
├── repositories/
│   └── {feature}_repository.dart
└── use_cases/
    └── {feature}_use_case.dart
```

#### **Responsibilities**
- **Business Logic**: Core business rules and logic
- **Entities**: Domain objects with identity
- **Value Objects**: Immutable objects without identity
- **Use Cases**: Application-specific business rules

#### **Key Components**
```dart
// Example: User Entity
class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final DateTime createdAt;
  
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
  });
  
  bool get isActive => role != UserRole.inactive;
  bool get isMerchant => role == UserRole.merchant;
}

// Example: Repository Interface
abstract class UserRepository {
  Future<User> getUser(String id);
  Future<List<User>> getUsers();
  Future<void> createUser(User user);
  Future<void> updateUser(User user);
  Future<void> deleteUser(String id);
}
```

### **Data Layer**

#### **Structure**
```
lib/features/{feature}/data/
├── repositories/
│   └── {feature}_repository_impl.dart
├── data_sources/
│   ├── {feature}_remote_data_source.dart
│   └── {feature}_local_data_source.dart
└── models/
    └── {feature}_model.dart
```

#### **Responsibilities**
- **Data Access**: Repository implementations
- **Data Sources**: Remote and local data sources
- **Data Models**: API and database models
- **Data Mapping**: Between domain and data models

#### **Key Components**
```dart
// Example: Repository Implementation
class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource _remoteDataSource;
  final UserLocalDataSource _localDataSource;
  
  UserRepositoryImpl(this._remoteDataSource, this._localDataSource);
  
  @override
  Future<User> getUser(String id) async {
    try {
      final userModel = await _remoteDataSource.getUser(id);
      return userModel.toDomain();
    } catch (e) {
      final localUser = await _localDataSource.getUser(id);
      return localUser?.toDomain();
    }
  }
}
```

## 🔄 State Management Architecture

### **Riverpod Pattern**
```dart
// Provider Hierarchy
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.read(authRemoteDataSourceProvider),
    ref.read(authLocalDataSourceProvider),
  );
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

// State Management
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  
  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });
  
  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
```

## 🗄️ Data Flow Architecture

### **Unidirectional Data Flow**
```
User Action → Provider → Repository → Data Source → API/Database
                ↓
            State Update → UI Rebuild
```

### **Data Flow Example**
```dart
// 1. User Action
onPressed: () => ref.read(authProvider.notifier).signIn(email, password)

// 2. Provider Action
Future<void> signIn(String email, String password) async {
  state = state.copyWith(isLoading: true);
  try {
    final user = await _repository.signIn(email, password);
    state = state.copyWith(user: user, isLoading: false);
  } catch (e) {
    state = state.copyWith(error: e.toString(), isLoading: false);
  }
}

// 3. Repository Implementation
Future<User> signIn(String email, String password) async {
  final userModel = await _remoteDataSource.signIn(email, password);
  await _localDataSource.saveUser(userModel);
  return userModel.toDomain();
}

// 4. UI Rebuild
Consumer(
  builder: (context, ref, child) {
    final authState = ref.watch(authProvider);
    return authState.isLoading 
        ? CircularProgressIndicator()
        : LoginForm();
  },
)
```

## 🔐 Security Architecture

### **Authentication Flow**
```
Login Screen → Auth Provider → Auth Repository → Auth API
                    ↓
            Token Storage → Secure Storage
                    ↓
            Route Guard → Protected Routes
```

### **Security Components**
```dart
// Token Management
class TokenManager {
  static const String _tokenKey = 'auth_token';
  
  static Future<void> saveToken(String token) async {
    await SecureStorage.write(key: _tokenKey, value: token);
  }
  
  static Future<String?> getToken() async {
    return await SecureStorage.read(key: _tokenKey);
  }
}

// Route Guard
class AuthGuard extends ConsumerWidget {
  final Widget child;
  
  const AuthGuard({required this.child});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    if (authState.user == null) {
      return LoginScreen();
    }
    
    return child;
  }
}
```

## 🌐 Network Architecture

### **API Layer**
```dart
// HTTP Client Configuration
class ApiClient {
  final Dio _dio;
  
  ApiClient() : _dio = Dio() {
    _dio.options.baseUrl = AppConfig.apiBaseUrl;
    _dio.options.connectTimeout = Duration(seconds: 30);
    _dio.options.receiveTimeout = Duration(seconds: 30);
    _dio.interceptors.add(AuthInterceptor());
    _dio.interceptors.add(LoggingInterceptor());
  }
}

// API Service
abstract class AuthApiService {
  Future<UserModel> signIn(String email, String password);
  Future<UserModel> signUp(String email, String password, String name);
  Future<void> signOut();
}

class AuthApiServiceImpl implements AuthApiService {
  final ApiClient _client;
  
  AuthApiServiceImpl(this._client);
  
  @override
  Future<UserModel> signIn(String email, String password) async {
    final response = await _client.post('/auth/signin', data: {
      'email': email,
      'password': password,
    });
    return UserModel.fromJson(response.data);
  }
}
```

## 💾 Storage Architecture

### **Local Storage Strategy**
```dart
// Storage Service
abstract class StorageService {
  Future<void> save<T>(String key, T value);
  Future<T?> get<T>(String key);
  Future<void> delete(String key);
  Future<void> clear();
}

// SQLite Implementation
class SQLiteStorageService implements StorageService {
  final Database _database;
  
  SQLiteStorageService(this._database);
  
  @override
  Future<void> save<T>(String key, T value) async {
    await _database.insert(
      'storage',
      {'key': key, 'value': jsonEncode(value)},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
```

## 🧪 Testing Architecture

### **Test Pyramid**
```
┌─────────────────────────────────────────────────────────────┐
│                    E2E Tests (10%)                         │
│                 Integration Tests (20%)                     │
│                   Unit Tests (70%)                         │
└─────────────────────────────────────────────────────────────┘
```

### **Testing Strategy**
```dart
// Unit Test Example
void main() {
  group('AuthProvider', () {
    late MockAuthRepository mockRepository;
    late AuthProvider provider;
    
    setUp(() {
      mockRepository = MockAuthRepository();
      provider = AuthProvider(mockRepository);
    });
    
    test('should emit loading state when signing in', () async {
      when(mockRepository.signIn(any, any))
          .thenAnswer((_) async => User(id: '1', name: 'Test'));
      
      provider.signIn('test@example.com', 'password');
      
      expect(provider.state.isLoading, true);
    });
  });
}
```

## 📱 Feature Architecture

### **Feature Module Structure**
```
lib/features/auth/
├── domain/
│   ├── models/
│   │   ├── user.dart
│   │   └── auth_state.dart
│   ├── repositories/
│   │   └── auth_repository.dart
│   └── use_cases/
│       ├── sign_in_use_case.dart
│       └── sign_up_use_case.dart
├── data/
│   ├── repositories/
│   │   └── auth_repository_impl.dart
│   ├── data_sources/
│   │   ├── auth_remote_data_source.dart
│   │   └── auth_local_data_source.dart
│   └── models/
│       └── user_model.dart
└── presentation/
    ├── screens/
    │   ├── login_screen.dart
    │   └── register_screen.dart
    ├── widgets/
    │   └── login_form.dart
    └── providers/
        └── auth_provider.dart
```

## 🔄 Dependency Injection

### **Provider Configuration**
```dart
// Core Providers
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
final storageProvider = Provider<StorageService>((ref) => SQLiteStorageService());

// Repository Providers
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.read(authRemoteDataSourceProvider),
    ref.read(authLocalDataSourceProvider),
  );
});

// Use Case Providers
final signInUseCaseProvider = Provider<SignInUseCase>((ref) {
  return SignInUseCase(ref.read(authRepositoryProvider));
});

// State Providers
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});
```

## 🚀 Performance Architecture

### **Optimization Strategies**
1. **Widget Optimization**
   - Use `const` constructors
   - Implement `shouldRebuild` in custom widgets
   - Use `ListView.builder` for large lists

2. **State Management**
   - Minimize state updates
   - Use selective watching with Riverpod
   - Implement proper state immutability

3. **Network Optimization**
   - Implement request caching
   - Use pagination for large datasets
   - Optimize image loading and caching

4. **Memory Management**
   - Dispose controllers properly
   - Use weak references where appropriate
   - Implement proper cleanup in providers

## 🔧 Configuration Architecture

### **Environment Configuration**
```dart
// App Configuration
class AppConfig {
  static const String appName = 'Gemura';
  static const String appVersion = '1.0.0';
  
  // API Configuration
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.gemura.com',
  );
  
  // Feature Flags
  static const bool enableAnalytics = bool.fromEnvironment(
    'ENABLE_ANALYTICS',
    defaultValue: true,
  );
}
```

## 📊 Monitoring & Analytics

### **Error Tracking**
```dart
// Error Handler
class ErrorHandler {
  static void handleError(dynamic error, StackTrace? stackTrace) {
    // Log error
    debugPrint('Error: $error');
    debugPrint('StackTrace: $stackTrace');
    
    // Send to analytics
    AnalyticsService.trackError(error, stackTrace);
  }
}
```

## 🔄 Migration Strategy

### **Version Migration**
```dart
// Migration Manager
class MigrationManager {
  static Future<void> migrate() async {
    final currentVersion = await getCurrentVersion();
    final targetVersion = AppConfig.appVersion;
    
    if (currentVersion != targetVersion) {
      await performMigrations(currentVersion, targetVersion);
      await updateVersion(targetVersion);
    }
  }
}
```

This architectural design ensures:
- **Scalability**: Easy to add new features
- **Maintainability**: Clear separation of concerns
- **Testability**: Each layer can be tested independently
- **Performance**: Optimized for mobile devices
- **Security**: Proper authentication and data protection
- **Reliability**: Error handling and monitoring 