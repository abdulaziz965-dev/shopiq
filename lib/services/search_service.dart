import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/product.dart';
import 'backend_service.dart';
import 'real_search_service.dart';
import 'image_search_service.dart';

enum SearchState { idle, loading, results, empty }
enum SearchMode { text, image }

class SearchService extends ChangeNotifier {
  SearchState _state = SearchState.idle;
  SearchMode _mode = SearchMode.text;
  List<Product> _results = [];
  List<Product> _filteredResults = [];
  String _query = '';
  String _activeFilter = 'All';
  String _sortBy = 'score';
  ImageIdentifyResult? _imageResult;
  String? _errorMessage;

  final _realSearch = RealSearchService();
  final _imageSearch = ImageSearchService();
  final _backend = BackendService();

  SearchState get state => _state;
  SearchMode get mode => _mode;
  List<Product> get results => _filteredResults;
  String get query => _query;
  String get activeFilter => _activeFilter;
  ImageIdentifyResult? get imageResult => _imageResult;
  String? get errorMessage => _errorMessage;

  Future<void> search(String query) async {
    if (query.trim().isEmpty) return;
    _query = query.trim();
    _mode = SearchMode.text;
    _state = SearchState.loading;
    _results = [];
    _filteredResults = [];
    _activeFilter = 'All';
    _imageResult = null;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_backend.isConfigured) {
        final backendResults = await _backend.searchProducts(query);
        if (backendResults.isNotEmpty) {
          _results = Product.assignBadges(_deduplicate(backendResults));
        } else {
          throw Exception('Backend returned no listings');
        }
      } else {
        if (!_realSearch.hasAnyLiveProviderConfigured) {
          final missing = _realSearch.missingKeys.join(', ');
          throw StateError('Missing $missing and BACKEND_BASE_URL');
        }
        final results = await _fetchReal(query);
        _results = results;
      }
    } on StateError catch (e) {
      _errorMessage =
          'Live listings need runtime setup ($e). Use --dart-define-from-file=dart_define.json and include BACKEND_BASE_URL if using backend.';
      _results = [];
    } catch (e) {
      if (_backend.isConfigured) {
        try {
          final results = await _fetchReal(query);
          _results = results;
          _errorMessage =
              'Backend temporarily unavailable ($e). Showing direct provider results.';
        } catch (providerError) {
          _errorMessage =
              'Backend failed ($e) and providers failed ($providerError).';
          _results = [];
        }
      } else {
        _errorMessage =
            'Live search API is temporarily unavailable: $e.';
        _results = [];
      }
    }

    _filteredResults = _sortList(List.from(_results));
    _state = _results.isEmpty ? SearchState.empty : SearchState.results;
    notifyListeners();
  }

  Future<List<Product>> _fetchReal(String query) async {
    final combined = <Product>[];
    final failures = <String>[];

    if (_realSearch.hasSerpConfigured) {
      try {
        combined.addAll(await _realSearch.searchGoogleShopping(query));
      } catch (e) {
        failures.add('SerpAPI: $e');
      }
    }

    if (_realSearch.hasRapidConfigured) {
      try {
        combined.addAll(await _realSearch.searchAmazon(query));
      } catch (e) {
        failures.add('Amazon RapidAPI: $e');
      }
      try {
        combined.addAll(await _realSearch.searchFlipkart(query));
      } catch (e) {
        failures.add('Flipkart RapidAPI: $e');
      }
    }

    if (combined.isEmpty) {
      final reason = failures.isEmpty ? 'No listings returned from live providers' : failures.join(' | ');
      throw Exception(reason);
    }

    return Product.assignBadges(_deduplicate(combined));
  }

  List<Product> _deduplicate(List<Product> products) {
    final seen = <String>{};
    return products.where((p) {
      final key = p.title.toLowerCase().substring(0, p.title.length.clamp(0, 30));
      if (seen.contains(key)) return false;
      seen.add(key);
      return true;
    }).toList();
  }

  Future<void> searchFromFile(File imageFile) async {
    _mode = SearchMode.image;
    _state = SearchState.loading;
    _imageResult = null;
    _query = 'Identifying product...';
    notifyListeners();

    try {
      final identified = await _imageSearch.identifyProduct(imageFile);
      _imageResult = identified;
      _query = identified.searchQuery;
      notifyListeners();
      await search(identified.searchQuery);
    } catch (e) {
      _errorMessage = 'Could not identify product. Try a clearer photo.';
      _state = SearchState.empty;
      notifyListeners();
    }
  }

  Future<void> searchFromBytes(Uint8List bytes, String mimeType) async {
    _mode = SearchMode.image;
    _state = SearchState.loading;
    _imageResult = null;
    _query = 'Identifying product...';
    notifyListeners();

    try {
      final identified = await _imageSearch.identifyProductFromBytes(bytes, mimeType);
      _imageResult = identified;
      _query = identified.searchQuery;
      notifyListeners();
      await search(identified.searchQuery);
    } catch (e) {
      _errorMessage = 'Could not identify product: $e';
      _state = SearchState.empty;
      notifyListeners();
    }
  }

  void applyFilter(String filter) {
    _activeFilter = filter;
    List<Product> base = List.from(_results);
    switch (filter) {
      case 'Amazon': base = base.where((p) => p.platform == 'Amazon').toList(); break;
      case 'Flipkart': base = base.where((p) => p.platform == 'Flipkart').toList(); break;
      case 'Myntra': base = base.where((p) => p.platform == 'Myntra').toList(); break;
      case 'Under ₹5000': base = base.where((p) => p.price < 5000).toList(); break;
      case '4★+': base = base.where((p) => p.rating >= 4.0).toList(); break;
    }
    _filteredResults = _sortList(base);
    notifyListeners();
  }

  void setSortBy(String sort) {
    _sortBy = sort;
    _filteredResults = _sortList(List.from(_filteredResults));
    notifyListeners();
  }

  List<Product> _sortList(List<Product> list) {
    final s = List<Product>.from(list);
    switch (_sortBy) {
      case 'price': s.sort((a, b) => a.price.compareTo(b.price)); break;
      case 'rating': s.sort((a, b) => b.rating.compareTo(a.rating)); break;
      default: s.sort((a, b) => b.score.compareTo(a.score));
    }
    return s;
  }

  void clearResults() {
    _state = SearchState.idle;
    _results = [];
    _filteredResults = [];
    _query = '';
    _imageResult = null;
    _errorMessage = null;
    notifyListeners();
  }
}
