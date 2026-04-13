import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

/// RealSearchService calls real e-commerce search APIs.
///
/// PRIMARY:   SerpAPI Google Shopping  (https://serpapi.com — free 100 searches/month)
/// FALLBACK:  RapidAPI Real-Time Amazon Data
///
/// Setup:
///   1. Sign up at https://serpapi.com → copy your API key → set SERP_API_KEY
///   2. Sign up at https://rapidapi.com → subscribe to "Real-Time Amazon Data" → set RAPID_API_KEY
class RealSearchService {
  static const _serpApiKey = String.fromEnvironment('SERP_API_KEY', defaultValue: '');
  static const _rapidApiKey = String.fromEnvironment('RAPID_API_KEY', defaultValue: '');

  bool get _hasSerpKey => _serpApiKey.isNotEmpty && !_serpApiKey.startsWith('YOUR_');
  bool get _hasRapidKey => _rapidApiKey.isNotEmpty && !_rapidApiKey.startsWith('YOUR_');
  bool get hasSerpConfigured => _hasSerpKey;
  bool get hasRapidConfigured => _hasRapidKey;
  bool get hasAnyLiveProviderConfigured => _hasSerpKey || _hasRapidKey;
  List<String> get missingKeys {
    final keys = <String>[];
    if (!_hasSerpKey) keys.add('SERP_API_KEY');
    if (!_hasRapidKey) keys.add('RAPID_API_KEY');
    return keys;
  }

  /// Search Google Shopping via SerpAPI
  Future<List<Product>> searchGoogleShopping(String query) async {
    if (!_hasSerpKey) throw StateError('Missing SERP_API_KEY');

    final url = Uri.parse(
      'https://serpapi.com/search.json'
      '?engine=google_shopping'
      '&q=${Uri.encodeComponent(query)}'
      '&gl=in'          // India
      '&hl=en'
      '&currency=INR'
      '&api_key=$_serpApiKey',
    );

    final resp = await http.get(url).timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) throw Exception('SerpAPI error ${resp.statusCode}');

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final items = (data['shopping_results'] as List?) ?? [];

    return items.take(20).map((item) {
      final rawPrice = item['price'] as String? ?? '₹0';
      final price = _parsePrice(rawPrice);
      final source = item['source'] as String? ?? 'Online Store';

      final rawLink = item['link'] as String? ?? '';
      return Product(
        id: 'serp_${item['position']}',
        title: item['title'] as String? ?? 'Product',
        platform: _normalizePlatform(source),
        platformIcon: _platformIcon(source),
        emoji: _categoryEmoji(query),
        price: price,
        originalPrice: price * 1.15,   // estimate original
        rating: (item['rating'] as num?)?.toDouble() ?? 4.0,
        reviews: (item['reviews'] as num?)?.toInt() ?? 0,
        delivery: 'Check site',
        deliveryDays: 3,
        discount: 13,
        affiliateUrl: _listingUrl(
          platform: _normalizePlatform(source),
          query: query,
          rawUrl: rawLink,
        ),
        category: query.toLowerCase(),
        imageUrl: item['thumbnail'] as String?,
      );
    }).toList();
  }

  /// Search Amazon India via RapidAPI "Real-Time Amazon Data"
  Future<List<Product>> searchAmazon(String query) async {
    if (!_hasRapidKey) throw StateError('Missing RAPID_API_KEY');

    final url = Uri.parse(
      'https://real-time-amazon-data.p.rapidapi.com/search'
      '?query=${Uri.encodeComponent(query)}'
      '&page=1'
      '&country=IN'
      '&sort_by=RELEVANCE',
    );

    final resp = await http.get(url, headers: {
      'x-rapidapi-host': 'real-time-amazon-data.p.rapidapi.com',
      'x-rapidapi-key': _rapidApiKey,
    }).timeout(const Duration(seconds: 10));

    if (resp.statusCode != 200) throw Exception('Amazon API error ${resp.statusCode}');

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final items = (data['data']?['products'] as List?) ?? [];

    return items.take(10).map((item) {
      final priceStr = item['product_price'] as String? ?? '₹0';
      final origStr = item['product_original_price'] as String?;
      final price = _parsePrice(priceStr);
      final orig = origStr != null ? _parsePrice(origStr) : price * 1.2;

      final asin = (item['asin'] as String?)?.trim() ?? '';
      return Product(
        id: 'amz_${item['asin'] ?? _fallbackId('amz')}',
        title: item['product_title'] as String? ?? 'Amazon Product',
        platform: 'Amazon',
        platformIcon: '🛒',
        emoji: _categoryEmoji(query),
        price: price,
        originalPrice: orig,
        rating: (item['product_star_rating'] as num?)?.toDouble() ?? 4.0,
        reviews: _parseReviews(item['product_num_ratings']),
        delivery: _amazonDelivery(item),
        deliveryDays: _amazonDeliveryDays(item),
        discount: _calcDiscount(price, orig),
        affiliateUrl: asin.isNotEmpty
          ? 'https://www.amazon.in/dp/$asin'
          : _listingUrl(platform: 'Amazon', query: query),
        category: query.toLowerCase(),
        imageUrl: item['product_photo'] as String?,
      );
    }).toList();
  }

  /// Search Flipkart via RapidAPI "Flipkart"
  Future<List<Product>> searchFlipkart(String query) async {
    if (!_hasRapidKey) return [];

    final url = Uri.parse(
      'https://flipkart-product-scrapper.p.rapidapi.com/search'
      '?q=${Uri.encodeComponent(query)}',
    );

    final resp = await http.get(url, headers: {
      'x-rapidapi-host': 'flipkart-product-scrapper.p.rapidapi.com',
      'x-rapidapi-key': _rapidApiKey,
    }).timeout(const Duration(seconds: 10));

    if (resp.statusCode != 200) return []; // Graceful fallback

    final data = jsonDecode(resp.body);
    final items = (data is List ? data : (data['products'] as List?)) ?? [];

    return items.take(8).map<Product>((item) {
      final price = _parsePrice(item['price']?.toString() ?? '₹0');
      final orig = _parsePrice(item['originalPrice']?.toString() ?? '₹0');

      final rawUrl = item['url']?.toString() ?? '';
      return Product(
        id: 'fk_${item['id'] ?? _fallbackId('fk')}',
        title: item['name'] as String? ?? 'Flipkart Product',
        platform: 'Flipkart',
        platformIcon: '📦',
        emoji: _categoryEmoji(query),
        price: price,
        originalPrice: orig > 0 ? orig : price * 1.2,
        rating: (item['rating'] as num?)?.toDouble() ?? 4.0,
        reviews: _parseReviews(item['ratingCount']),
        delivery: '2-3 days',
        deliveryDays: 2,
        discount: _calcDiscount(price, orig > 0 ? orig : price * 1.2),
        affiliateUrl: _listingUrl(platform: 'Flipkart', query: query, rawUrl: rawUrl),
        category: query.toLowerCase(),
        imageUrl: item['image'] as String?,
      );
    }).toList();
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────

  double _parsePrice(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[₹$,\s]'), '');
    final match = RegExp(r'[\d.]+').firstMatch(cleaned);
    return match != null ? double.tryParse(match.group(0)!) ?? 0 : 0;
  }

  int _parseReviews(dynamic val) {
    if (val == null) return 0;
    final s = val.toString().replaceAll(RegExp(r'[,\s]'), '');
    return int.tryParse(s) ?? 0;
  }

  int _calcDiscount(double price, double orig) {
    if (orig <= 0 || price >= orig) return 0;
    return ((orig - price) / orig * 100).round();
  }

  String _fallbackId(String prefix) {
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}';
  }

  String _listingUrl({required String platform, required String query, String? rawUrl}) {
    final normalized = (rawUrl ?? '').trim();
    if (normalized.isNotEmpty) {
      if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
        if (!_isRootDomain(normalized)) return normalized;
      } else if (normalized.startsWith('/')) {
        if (platform.toLowerCase().contains('flipkart')) {
          return 'https://www.flipkart.com$normalized';
        }
      }
    }

    final q = Uri.encodeComponent(query.trim());
    final p = platform.toLowerCase();
    if (p.contains('amazon')) return 'https://www.amazon.in/s?k=$q';
    if (p.contains('flipkart')) return 'https://www.flipkart.com/search?q=$q';
    if (p.contains('myntra')) return 'https://www.myntra.com/$q';
    if (p.contains('croma')) return 'https://www.croma.com/searchB?q=$q%3Arelevance';
    return 'https://www.google.com/search?q=$q';
  }

  bool _isRootDomain(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return uri.path.isEmpty || uri.path == '/';
  }

  String _normalizePlatform(String source) {
    final s = source.toLowerCase();
    if (s.contains('amazon')) return 'Amazon';
    if (s.contains('flipkart')) return 'Flipkart';
    if (s.contains('myntra')) return 'Myntra';
    if (s.contains('croma')) return 'Croma';
    if (s.contains('reliance')) return 'Reliance Digital';
    if (s.contains('tata')) return 'Tata CLiQ';
    if (s.contains('meesho')) return 'Meesho';
    return source;
  }

  String _platformIcon(String source) {
    final s = source.toLowerCase();
    if (s.contains('amazon')) return '🛒';
    if (s.contains('flipkart')) return '📦';
    if (s.contains('myntra')) return '👗';
    if (s.contains('croma')) return '🏪';
    return '🛍️';
  }

  String _categoryEmoji(String query) {
    final q = query.toLowerCase();
    if (q.contains('phone') || q.contains('mobile') || q.contains('iphone') || q.contains('samsung')) return '📱';
    if (q.contains('laptop') || q.contains('macbook')) return '💻';
    if (q.contains('headphone') || q.contains('earphone') || q.contains('airpod')) return '🎧';
    if (q.contains('watch')) return '⌚';
    if (q.contains('shoe') || q.contains('sneaker')) return '👟';
    if (q.contains('camera')) return '📷';
    if (q.contains('tv') || q.contains('television')) return '📺';
    if (q.contains('tablet') || q.contains('ipad')) return '📱';
    return '📦';
  }

  String _amazonDelivery(Map item) {
    final delivery = item['delivery'] as String?;
    if (delivery == null) return '2-4 days';
    if (delivery.toLowerCase().contains('tomorrow')) return 'Tomorrow';
    if (delivery.toLowerCase().contains('today')) return 'Today';
    return delivery;
  }

  int _amazonDeliveryDays(Map item) {
    final delivery = (item['delivery'] as String? ?? '').toLowerCase();
    if (delivery.contains('today')) return 0;
    if (delivery.contains('tomorrow')) return 1;
    if (delivery.contains('2')) return 2;
    return 3;
  }
}
