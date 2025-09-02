# Search Architecture Documentation

## Overview
The app has two separate search functionalities with the same UI/UX design but different purposes:

1. **Marketplace Product Search** - Searches products in the marketplace
2. **Transaction Search** - Searches user transactions and financial records

## Search Providers

### 1. Marketplace Search Provider
- **File**: `lib/features/market/presentation/providers/search_provider.dart`
- **Provider Name**: `marketSearchProvider`
- **Purpose**: Search marketplace products via API
- **API Endpoint**: `https://api.gemura.rw/v2/market/products/search.php`
- **Features**:
  - Product search by name, description, code
  - Category filtering
  - Price range filtering
  - Seller type filtering
  - Sorting (newest, oldest, price_low, price_high, rating, name)
  - Pagination
  - Real-time search

### 2. Transaction Search Provider
- **File**: `lib/features/home/presentation/providers/search_provider.dart`
- **Provider Name**: `transactionSearchProvider`
- **Purpose**: Search local transaction records
- **Data Source**: Local transaction data
- **Features**:
  - Transaction search by description, customer name, phone, reference
  - Search by transaction ID, type, status, payment method
  - Search by amount
  - Real-time local search

## Search Screens

### 1. Marketplace Search Screen
- **File**: `lib/features/market/presentation/screens/search_screen.dart`
- **Class**: `MarketSearchScreen`
- **Provider Used**: `marketSearchProvider`
- **Features**:
  - Product search interface
  - Advanced filters (category, price, seller type)
  - Product grid display
  - Infinite scroll pagination
  - Number formatting (e.g., "RWF 2,300")

### 2. Home Search Screen
- **File**: `lib/features/home/presentation/screens/search_screen.dart`
- **Class**: `SearchScreen`
- **Provider Used**: `transactionSearchProvider`
- **Features**:
  - Transaction search interface
  - Transaction list display
  - Financial record search

## Key Benefits of Separation

1. **Clear Purpose**: Each search provider has a specific, well-defined purpose
2. **No Conflicts**: Different provider names prevent import conflicts
3. **Maintainable**: Easy to modify one search without affecting the other
4. **Scalable**: Can add more search providers for different features
5. **Consistent UI**: Same search interface design across different contexts

## Usage Examples

### Marketplace Search
```dart
// In marketplace screens
final searchState = ref.watch(marketSearchProvider);
ref.read(marketSearchProvider.notifier).search(filters);
```

### Transaction Search
```dart
// In home/transaction screens
final searchState = ref.watch(transactionSearchProvider);
ref.read(transactionSearchProvider.notifier).searchTransactions(transactions, query);
```

## API Integration

The marketplace search is fully integrated with the production API at `https://api.gemura.rw/v2/` and supports:
- Real-time product search
- Advanced filtering and sorting
- Pagination for large result sets
- Proper error handling
- Consistent response format matching other APIs

## Future Enhancements

1. **Unified Search Interface**: Could create a common search widget that adapts based on context
2. **Global Search**: Could implement a global search that searches across multiple data sources
3. **Search History**: Could add search history and suggestions
4. **Advanced Filters**: Could add more sophisticated filtering options
