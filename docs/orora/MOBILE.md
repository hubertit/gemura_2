# Orora Mobile App

## Overview

The Orora Mobile App is a Flutter-based cross-platform application for Android and iOS, designed for farmers, collectors, and field staff.

---

## Target Users

| User Type | Primary Features |
|-----------|------------------|
| **Farmer** | View own animals, record milk, check payments |
| **Collector** | Record collections, view suppliers |
| **Manager** | Full access, reports, analytics |
| **Veterinarian** | Health records, treatments |

---

## App Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Orora Mobile App                          │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │
│  │   Screens   │  │   Widgets   │  │   Dialogs   │          │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘          │
│         └─────────────────┼─────────────────┘                │
│                           │                                  │
│  ┌────────────────────────▼─────────────────────────┐       │
│  │              State Management (Riverpod)          │       │
│  └────────────────────────┬─────────────────────────┘       │
│                           │                                  │
│  ┌────────────────────────▼─────────────────────────┐       │
│  │                  Repository Layer                 │       │
│  │   ┌──────────┐  ┌──────────┐  ┌──────────┐       │       │
│  │   │ Animals  │  │   Milk   │  │ Inventory│       │       │
│  │   └──────────┘  └──────────┘  └──────────┘       │       │
│  └────────────────────────┬─────────────────────────┘       │
│                           │                                  │
│  ┌────────────────────────▼─────────────────────────┐       │
│  │                  Data Sources                     │       │
│  │   ┌──────────┐           ┌──────────┐            │       │
│  │   │ Remote   │           │  Local   │            │       │
│  │   │ (API)    │           │ (SQLite) │            │       │
│  │   └──────────┘           └──────────┘            │       │
│  └──────────────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────────┘
```

---

## Technology Stack

| Component | Technology |
|-----------|------------|
| Framework | Flutter 3.x |
| Language | Dart |
| State Management | Riverpod 2.x |
| HTTP Client | Dio |
| Local Storage | Hive / SQLite |
| Image Handling | cached_network_image |
| Camera | image_picker |
| Notifications | firebase_messaging |

---

## Project Structure

```
apps/orora-mobile/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart
│   │   │   ├── app_strings.dart
│   │   │   └── api_endpoints.dart
│   │   ├── theme/
│   │   │   └── app_theme.dart
│   │   ├── utils/
│   │   │   ├── validators.dart
│   │   │   └── formatters.dart
│   │   └── network/
│   │       ├── api_client.dart
│   │       └── api_interceptor.dart
│   │
│   ├── data/
│   │   ├── models/
│   │   │   ├── animal.dart
│   │   │   ├── milk_sale.dart
│   │   │   └── user.dart
│   │   ├── repositories/
│   │   │   ├── animal_repository.dart
│   │   │   └── milk_repository.dart
│   │   └── datasources/
│   │       ├── remote/
│   │       └── local/
│   │
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── animal_provider.dart
│   │   └── milk_provider.dart
│   │
│   ├── features/
│   │   ├── auth/
│   │   │   ├── screens/
│   │   │   │   ├── login_screen.dart
│   │   │   │   └── register_screen.dart
│   │   │   └── widgets/
│   │   │
│   │   ├── home/
│   │   │   ├── screens/
│   │   │   │   └── home_screen.dart
│   │   │   └── widgets/
│   │   │       ├── dashboard_card.dart
│   │   │       └── quick_actions.dart
│   │   │
│   │   ├── animals/
│   │   │   ├── screens/
│   │   │   │   ├── animal_list_screen.dart
│   │   │   │   ├── animal_detail_screen.dart
│   │   │   │   └── add_animal_screen.dart
│   │   │   └── widgets/
│   │   │       ├── animal_card.dart
│   │   │       └── animal_form.dart
│   │   │
│   │   ├── milk/
│   │   │   ├── screens/
│   │   │   │   ├── collection_screen.dart
│   │   │   │   └── collection_history_screen.dart
│   │   │   └── widgets/
│   │   │
│   │   ├── inventory/
│   │   │   └── screens/
│   │   │
│   │   └── profile/
│   │       └── screens/
│   │
│   └── widgets/
│       ├── common/
│       │   ├── app_button.dart
│       │   ├── app_input.dart
│       │   └── loading_indicator.dart
│       └── dialogs/
│
├── assets/
│   ├── images/
│   ├── icons/
│   └── fonts/
│
├── android/
├── ios/
└── pubspec.yaml
```

---

## Screens

### MVP Screens

| Screen | Description | Priority |
|--------|-------------|----------|
| Splash | App loading | High |
| Login | User authentication | High |
| Home/Dashboard | Overview with stats | High |
| Animal List | Browse animals | High |
| Animal Detail | View animal info | High |
| Add Animal | Register new animal | High |
| Milk Collection | Record collection | High |
| Collection History | View past collections | High |
| Profile | User settings | Medium |

### Post-MVP Screens

| Screen | Description | Target |
|--------|-------------|--------|
| Breeding Records | Track breeding | Beta |
| Health Records | Vaccinations, treatments | Beta |
| Weight Tracking | Record weights | Beta |
| Inventory | View products | Beta |
| Reports | Basic reports | v1.0 |
| Settings | App configuration | v1.0 |

---

## API Integration

### API Client Setup

```dart
class ApiClient {
  final Dio _dio;
  
  ApiClient() : _dio = Dio(BaseOptions(
    baseUrl: 'http://209.74.80.195:3007/api',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  )) {
    _dio.interceptors.add(AuthInterceptor());
    _dio.interceptors.add(LogInterceptor());
  }
  
  Future<Response> get(String path, {Map<String, dynamic>? params}) =>
    _dio.get(path, queryParameters: params);
    
  Future<Response> post(String path, {dynamic data}) =>
    _dio.post(path, data: data);
}
```

### Repository Pattern

```dart
class AnimalRepository {
  final ApiClient _api;
  final AnimalLocalSource _local;
  
  Future<List<Animal>> getAnimals() async {
    try {
      final response = await _api.get('/animals');
      final animals = (response.data['data'] as List)
        .map((e) => Animal.fromJson(e))
        .toList();
      await _local.cacheAnimals(animals);
      return animals;
    } catch (e) {
      return _local.getCachedAnimals();
    }
  }
}
```

---

## State Management

### Using Riverpod

```dart
// Provider definition
final animalsProvider = FutureProvider<List<Animal>>((ref) async {
  final repository = ref.watch(animalRepositoryProvider);
  return repository.getAnimals();
});

// Usage in widget
class AnimalListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animalsAsync = ref.watch(animalsProvider);
    
    return animalsAsync.when(
      data: (animals) => ListView.builder(
        itemCount: animals.length,
        itemBuilder: (_, i) => AnimalCard(animal: animals[i]),
      ),
      loading: () => const LoadingIndicator(),
      error: (e, _) => ErrorWidget(error: e.toString()),
    );
  }
}
```

---

## Offline Support

### Strategy

1. **Cache API responses** in SQLite/Hive
2. **Queue offline actions** for later sync
3. **Show cached data** when offline
4. **Sync on connectivity** restored

### Implementation

```dart
class OfflineQueue {
  final Box<QueuedAction> _queue;
  
  Future<void> enqueue(QueuedAction action) async {
    await _queue.add(action);
  }
  
  Future<void> processQueue() async {
    for (final action in _queue.values) {
      try {
        await _executeAction(action);
        await action.delete();
      } catch (e) {
        // Will retry later
      }
    }
  }
}
```

---

## Brand Colors

```dart
class AppColors {
  // Primary - Orora Green
  static const primary = Color(0xFF84BD22);
  static const primaryDark = Color(0xFF6A9A1B);
  static const primaryLight = Color(0xFFA5D44A);
  
  // Accent - Orange
  static const accent = Color(0xFFF5A623);
  
  // Neutral
  static const background = Color(0xFFF5F5F5);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
  
  // Status
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFF9800);
  static const error = Color(0xFFF44336);
}
```

---

## App Permissions

### Android (AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### iOS (Info.plist)

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access for animal photos</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Photo library access for animal images</string>
```

---

## Build & Release

### Development

```bash
cd apps/orora-mobile
flutter pub get
flutter run
```

### Build APK (Android)

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Build AAB (Play Store)

```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### Build iOS

```bash
flutter build ios --release
# Then archive in Xcode
```

---

## Testing

### Unit Tests

```bash
flutter test
```

### Integration Tests

```bash
flutter test integration_test/
```

### Widget Tests

```dart
testWidgets('Animal card displays correctly', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: AnimalCard(animal: mockAnimal),
    ),
  );
  
  expect(find.text('A001'), findsOneWidget);
  expect(find.text('Friesian'), findsOneWidget);
});
```

---

## Performance Guidelines

1. **Lazy loading** for lists
2. **Image caching** with cached_network_image
3. **Pagination** for large datasets
4. **Minimize rebuilds** with const widgets
5. **Efficient state** management

---

## Release Checklist

### Pre-Release

- [ ] All MVP features implemented
- [ ] No critical bugs
- [ ] Performance acceptable
- [ ] Offline mode working
- [ ] Tested on multiple devices

### Android Release

- [ ] App signing key created
- [ ] Play Store listing prepared
- [ ] Screenshots captured
- [ ] Privacy policy URL
- [ ] Build AAB uploaded
- [ ] Internal testing passed

### iOS Release

- [ ] Apple Developer account active
- [ ] App Store Connect listing
- [ ] Screenshots (all sizes)
- [ ] Privacy policy
- [ ] Archive and upload
- [ ] TestFlight testing

---

## Version History

| Version | Date | Description |
|---------|------|-------------|
| 0.1.0 | Mar 15, 2026 | Soft Launch (APK distribution) |
| 0.5.0 | Apr 15, 2026 | Beta (Play Store beta, TestFlight) |
| 1.0.0 | Jun 15, 2026 | Production Release (Store listings) |
