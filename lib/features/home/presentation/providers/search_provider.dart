import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/transaction.dart';

class SearchNotifier extends StateNotifier<SearchState> {
  SearchNotifier() : super(SearchState());

  void setSearchQuery(String query) {
    state = state.copyWith(query: query);
  }

  void setSearchResults(List<Transaction> results) {
    state = state.copyWith(results: results);
  }

  void clearSearch() {
    state = SearchState();
  }

  List<Transaction> searchTransactions(List<Transaction> transactions, String query) {
    if (query.isEmpty) return [];
    
    final lowercaseQuery = query.toLowerCase();
    return transactions.where((transaction) {
      return transaction.description.toLowerCase().contains(lowercaseQuery) ||
             transaction.customerName.toLowerCase().contains(lowercaseQuery) ||
             transaction.customerPhone.contains(query) ||
             transaction.reference.toLowerCase().contains(lowercaseQuery) ||
             transaction.id.toLowerCase().contains(lowercaseQuery) ||
             transaction.type.toLowerCase().contains(lowercaseQuery) ||
             transaction.status.toLowerCase().contains(lowercaseQuery) ||
             transaction.paymentMethod.toLowerCase().contains(lowercaseQuery) ||
             transaction.amount.toString().contains(query);
    }).toList();
  }
}

class SearchState {
  final String query;
  final List<Transaction> results;
  final bool isSearching;

  SearchState({
    this.query = '',
    this.results = const [],
    this.isSearching = false,
  });

  SearchState copyWith({
    String? query,
    List<Transaction>? results,
    bool? isSearching,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isSearching: isSearching ?? this.isSearching,
    );
  }
}

final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier();
}); 