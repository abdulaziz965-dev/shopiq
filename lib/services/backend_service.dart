import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/product.dart';

class BackendService {
  static const _baseUrl = String.fromEnvironment('BACKEND_BASE_URL', defaultValue: '');

  String get _resolvedBaseUrl {
    final env = _baseUrl.trim();
    if (env.isNotEmpty) return env;
    if (kIsWeb) return Uri.base.origin;
    return '';
  }

  bool get isConfigured => _resolvedBaseUrl.isNotEmpty;

  Future<List<Product>> searchProducts(String query) async {
    if (!isConfigured) {
      throw StateError('Missing BACKEND_BASE_URL');
    }

    final uri = Uri.parse('$_resolvedBaseUrl/api/search').replace(
      queryParameters: {'q': query},
    );

    final resp = await http.get(uri).timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) {
      throw Exception('Backend API ${resp.statusCode}');
    }

    final decoded = jsonDecode(resp.body);
    final items = _extractItems(decoded);

    final products = <Product>[];
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      if (item is! Map<String, dynamic>) continue;
      products.add(_toProduct(item, query, i));
    }

    return products;
  }

  Future<List<String>> autocompleteSuggestions(String query, {int limit = 8}) async {
    if (!isConfigured) return const [];

    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    try {
      final uri = Uri.parse('$_resolvedBaseUrl/api/suggest').replace(
        queryParameters: {
          'q': trimmed,
          'limit': limit.toString(),
        },
      );

      final resp = await http.get(uri).timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return const [];

      final decoded = jsonDecode(resp.body);
      final raw = _extractSuggestionItems(decoded);

      return raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .take(limit)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  List<dynamic> _extractItems(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map<String, dynamic>) {
      final items = decoded['items'];
      if (items is List) return items;
      final results = decoded['results'];
      if (results is List) return results;
      final data = decoded['data'];
      if (data is List) return data;
      if (data is Map<String, dynamic>) {
        final dataItems = data['items'];
        if (dataItems is List) return dataItems;
      }
    }
    return const [];
  }

  List<dynamic> _extractSuggestionItems(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map<String, dynamic>) {
      final suggestions = decoded['suggestions'];
      if (suggestions is List) return suggestions;
      final items = decoded['items'];
      if (items is List) return items;
      final data = decoded['data'];
      if (data is List) return data;
    }
    return const [];
  }

  Product _toProduct(Map<String, dynamic> item, String query, int index) {
    final platform = (item['platform'] ?? item['store'] ?? 'Online').toString();
    final title = (item['title'] ?? item['name'] ?? 'Product').toString();
    final imageUrlRaw = item['imageUrl'] ?? item['image'] ?? item['thumbnail'];

    final url = (item['affiliateUrl'] ?? item['url'] ?? item['link'] ?? '').toString();

    return Product(
      id: (item['id'] ?? item['productId'] ?? 'be_${index + 1}').toString(),
      title: title,
      platform: platform,
      platformIcon: _platformIcon(platform),
      emoji: _emoji(query),
      price: _toDouble(item['price']),
      originalPrice: _toDouble(item['originalPrice'] ?? item['mrp'] ?? item['listPrice']),
      rating: _toDouble(item['rating'], fallback: 4.0),
      reviews: _toInt(item['reviews'] ?? item['reviewCount']),
      delivery: (item['delivery'] ?? item['deliveryText'] ?? 'Check site').toString(),
      deliveryDays: _toInt(item['deliveryDays'], fallback: 3),
      discount: _toInt(item['discount'] ?? item['discountPercent']),
      affiliateUrl: url,
      category: query.toLowerCase(),
      imageUrl: imageUrlRaw?.toString(),
    );
  }

  double _toDouble(dynamic v, {double fallback = 0}) {
    if (v is num) return v.toDouble();
    if (v == null) return fallback;
    final cleaned = v.toString().replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? fallback;
  }

  int _toInt(dynamic v, {int fallback = 0}) {
    if (v is num) return v.toInt();
    if (v == null) return fallback;
    final cleaned = v.toString().replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned) ?? fallback;
  }

  String _platformIcon(String platform) {
    final p = platform.toLowerCase();
    if (p.contains('amazon')) return '🛒';
    if (p.contains('flipkart')) return '📦';
    if (p.contains('myntra')) return '👗';
    return '🛍️';
  }

  String _emoji(String query) {
    final q = query.toLowerCase();
    if (q.contains('phone') || q.contains('mobile') || q.contains('iphone') || q.contains('samsung')) return '📱';
    if (q.contains('laptop') || q.contains('macbook')) return '💻';
    if (q.contains('headphone') || q.contains('earphone') || q.contains('airpod')) return '🎧';
    if (q.contains('watch')) return '⌚';
    if (q.contains('shoe') || q.contains('sneaker')) return '👟';
    if (q.contains('camera')) return '📷';
    if (q.contains('tv') || q.contains('television')) return '📺';
    return '📦';
  }
}
