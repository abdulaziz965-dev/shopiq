import '../models/product.dart';

class MockDataService {
  static final Map<String, List<Product>> _catalog = {
    'airpods': [
      Product(id: 'ap1', title: 'Apple AirPods Pro (2nd Gen) USB-C', platform: 'Amazon', platformIcon: '🛒', emoji: '🎧', price: 22999, originalPrice: 29900, rating: 4.7, reviews: 18420, delivery: 'Tomorrow', deliveryDays: 1, discount: 23, affiliateUrl: 'https://amazon.in', category: 'airpods'),
      Product(id: 'ap2', title: 'Apple AirPods Pro 2nd Gen Lightning', platform: 'Flipkart', platformIcon: '📦', emoji: '🎧', price: 21499, originalPrice: 26900, rating: 4.5, reviews: 9800, delivery: '2 days', deliveryDays: 2, discount: 20, affiliateUrl: 'https://flipkart.com', category: 'airpods'),
      Product(id: 'ap3', title: 'Apple AirPods Pro 2nd Gen Open Box', platform: 'Croma', platformIcon: '🏪', emoji: '🎧', price: 19999, originalPrice: 27900, rating: 4.2, reviews: 340, delivery: '3-5 days', deliveryDays: 4, discount: 28, affiliateUrl: 'https://croma.com', category: 'airpods'),
    ],
    'headphones': [
      Product(id: 'hp1', title: 'Sony WH-1000XM5 Wireless Noise Cancelling', platform: 'Amazon', platformIcon: '🛒', emoji: '🎵', price: 26990, originalPrice: 34990, rating: 4.8, reviews: 32100, delivery: 'Tomorrow', deliveryDays: 1, discount: 23, affiliateUrl: 'https://amazon.in', category: 'headphones'),
      Product(id: 'hp2', title: 'Sony WH-1000XM5 Flipkart Special', platform: 'Flipkart', platformIcon: '📦', emoji: '🎵', price: 25999, originalPrice: 34990, rating: 4.7, reviews: 14200, delivery: '2 days', deliveryDays: 2, discount: 26, affiliateUrl: 'https://flipkart.com', category: 'headphones'),
      Product(id: 'hp3', title: 'Bose QuietComfort 45 Wireless', platform: 'Amazon', platformIcon: '🛒', emoji: '🎵', price: 21990, originalPrice: 32000, rating: 4.6, reviews: 8900, delivery: 'Tomorrow', deliveryDays: 1, discount: 31, affiliateUrl: 'https://amazon.in', category: 'headphones'),
      Product(id: 'hp4', title: 'JBL Tour One M2 Over-Ear', platform: 'Flipkart', platformIcon: '📦', emoji: '🎵', price: 14999, originalPrice: 22000, rating: 4.3, reviews: 2100, delivery: '3 days', deliveryDays: 3, discount: 32, affiliateUrl: 'https://flipkart.com', category: 'headphones'),
    ],
    'iphone': [
      Product(id: 'ip1', title: 'Apple iPhone 16 Pro 128GB Natural Titanium', platform: 'Amazon', platformIcon: '🛒', emoji: '📱', price: 119900, originalPrice: 134900, rating: 4.8, reviews: 41200, delivery: 'Tomorrow', deliveryDays: 1, discount: 11, affiliateUrl: 'https://amazon.in', category: 'iphone'),
      Product(id: 'ip2', title: 'Apple iPhone 16 Pro 128GB No Cost EMI', platform: 'Flipkart', platformIcon: '📦', emoji: '📱', price: 117999, originalPrice: 134900, rating: 4.7, reviews: 28700, delivery: '2 days', deliveryDays: 2, discount: 12, affiliateUrl: 'https://flipkart.com', category: 'iphone'),
      Product(id: 'ip3', title: 'Apple iPhone 16 Base Model 128GB', platform: 'Amazon', platformIcon: '🛒', emoji: '📱', price: 79900, originalPrice: 89900, rating: 4.6, reviews: 19300, delivery: 'Tomorrow', deliveryDays: 1, discount: 11, affiliateUrl: 'https://amazon.in', category: 'iphone'),
    ],
    'laptop': [
      Product(id: 'lp1', title: 'MacBook Air M3 13-inch 8GB 256GB Midnight', platform: 'Amazon', platformIcon: '🛒', emoji: '💻', price: 114900, originalPrice: 134900, rating: 4.9, reviews: 12400, delivery: 'Tomorrow', deliveryDays: 1, discount: 15, affiliateUrl: 'https://amazon.in', category: 'laptop'),
      Product(id: 'lp2', title: 'Dell XPS 15 Core i7 16GB 512GB RTX 4060', platform: 'Flipkart', platformIcon: '📦', emoji: '💻', price: 149990, originalPrice: 185990, rating: 4.5, reviews: 3200, delivery: '3 days', deliveryDays: 3, discount: 19, affiliateUrl: 'https://flipkart.com', category: 'laptop'),
      Product(id: 'lp3', title: 'ASUS ROG Zephyrus G14 Ryzen 9 32GB', platform: 'Amazon', platformIcon: '🛒', emoji: '💻', price: 129990, originalPrice: 169990, rating: 4.6, reviews: 5600, delivery: '2 days', deliveryDays: 2, discount: 24, affiliateUrl: 'https://amazon.in', category: 'laptop'),
      Product(id: 'lp4', title: 'Lenovo IdeaPad Slim 5 Core i5 16GB', platform: 'Flipkart', platformIcon: '📦', emoji: '💻', price: 52990, originalPrice: 69990, rating: 4.4, reviews: 8900, delivery: 'Tomorrow', deliveryDays: 1, discount: 24, affiliateUrl: 'https://flipkart.com', category: 'laptop'),
    ],
    'shoes': [
      Product(id: 'sh1', title: 'Nike Air Max 270 Running Shoes White/Black', platform: 'Myntra', platformIcon: '👗', emoji: '👟', price: 8495, originalPrice: 12995, rating: 4.5, reviews: 6700, delivery: '3-5 days', deliveryDays: 4, discount: 35, affiliateUrl: 'https://myntra.com', category: 'shoes'),
      Product(id: 'sh2', title: 'Adidas Ultraboost 22 Running Shoes', platform: 'Amazon', platformIcon: '🛒', emoji: '👟', price: 7499, originalPrice: 11999, rating: 4.6, reviews: 4200, delivery: 'Tomorrow', deliveryDays: 1, discount: 37, affiliateUrl: 'https://amazon.in', category: 'shoes'),
      Product(id: 'sh3', title: 'Puma Velocity Nitro 2 Running Shoes', platform: 'Flipkart', platformIcon: '📦', emoji: '👟', price: 4999, originalPrice: 8999, rating: 4.3, reviews: 2800, delivery: '2 days', deliveryDays: 2, discount: 44, affiliateUrl: 'https://flipkart.com', category: 'shoes'),
    ],
    'samsung': [
      Product(id: 'ss1', title: 'Samsung Galaxy S24 Ultra 256GB Titanium Black', platform: 'Amazon', platformIcon: '🛒', emoji: '📱', price: 129999, originalPrice: 149999, rating: 4.7, reviews: 22300, delivery: 'Tomorrow', deliveryDays: 1, discount: 13, affiliateUrl: 'https://amazon.in', category: 'samsung'),
      Product(id: 'ss2', title: 'Samsung Galaxy S24 256GB Marble Gray', platform: 'Flipkart', platformIcon: '📦', emoji: '📱', price: 74999, originalPrice: 89999, rating: 4.6, reviews: 18700, delivery: 'Tomorrow', deliveryDays: 1, discount: 17, affiliateUrl: 'https://flipkart.com', category: 'samsung'),
      Product(id: 'ss3', title: 'Samsung Galaxy A55 128GB Navy', platform: 'Amazon', platformIcon: '🛒', emoji: '📱', price: 38999, originalPrice: 45999, rating: 4.4, reviews: 9100, delivery: '2 days', deliveryDays: 2, discount: 15, affiliateUrl: 'https://amazon.in', category: 'samsung'),
    ],
  };

  // Flash deals for home screen
  static final List<Map<String, dynamic>> flashDeals = [
    {'emoji': '🎧', 'title': 'Sony WF-1000XM5', 'price': '₹16,990', 'original': '₹22,990', 'discount': '26%', 'color': 0xFF1A1A3E},
    {'emoji': '📱', 'title': 'Samsung Galaxy A55', 'price': '₹38,999', 'original': '₹49,999', 'discount': '22%', 'color': 0xFF1E2A1E},
    {'emoji': '⌚', 'title': 'Apple Watch SE 2', 'price': '₹27,900', 'original': '₹34,900', 'discount': '20%', 'color': 0xFF2A1E1E},
    {'emoji': '🎮', 'title': 'PS5 DualSense', 'price': '₹5,999', 'original': '₹7,490', 'discount': '20%', 'color': 0xFF1A1E2A},
    {'emoji': '📷', 'title': 'GoPro Hero 12', 'price': '₹29,990', 'original': '₹42,990', 'discount': '30%', 'color': 0xFF2A1A1E},
  ];

  // Price drop alerts
  static final List<Map<String, dynamic>> priceDrops = [
    {'emoji': '💻', 'title': 'MacBook Air M2', 'price': '₹99,900', 'original': '₹1,12,900', 'drop': '₹13,000', 'color': 0xFF1E1A2E},
    {'emoji': '🎧', 'title': 'Bose QC45', 'price': '₹21,990', 'original': '₹32,000', 'drop': '₹5,000', 'color': 0xFF1A2E1A},
    {'emoji': '📺', 'title': 'LG C3 OLED 55"', 'price': '₹1,24,990', 'original': '₹1,64,990', 'drop': '₹20,000', 'color': 0xFF2E1A1E},
  ];

  // Price history mock data (6 months)
  static List<PricePoint> getPriceHistory(String productId) {
    final now = DateTime.now();
    final basePrice = _getBasePrice(productId);
    final rand = _seeded(productId.hashCode);

    return List.generate(6, (i) {
      final date = DateTime(now.year, now.month - (5 - i));
      final variation = (rand.call() % 10 - 5) / 100.0;
      final price = basePrice * (1 + variation + (5 - i) * 0.02);
      return PricePoint(date: date, price: price.roundToDouble(), platform: 'Amazon');
    });
  }

  static double _getBasePrice(String productId) {
    for (final products in _catalog.values) {
      for (final p in products) {
        if (p.id == productId) return p.price;
      }
    }
    return 25000;
  }

  // Simple deterministic pseudo-random for consistent mock data
  static int Function() _seeded(int seed) {
    int s = seed;
    return () {
      s = (s * 1103515245 + 12345) & 0x7fffffff;
      return s;
    };
  }

  static List<Product> search(String query) {
    final q = query.toLowerCase().trim();

    // Direct category match
    for (final entry in _catalog.entries) {
      if (q.contains(entry.key)) {
        return Product.assignBadges(
          entry.value.map((p) => _clone(p)).toList(),
        );
      }
    }

    // Fuzzy keyword matching
    if (_anyMatch(q, ['ear', 'audio', 'beat'])) return Product.assignBadges(_cloneList(_catalog['headphones']!));
    if (_anyMatch(q, ['phone', 'mobile', 'android', 'oneplus'])) return Product.assignBadges(_cloneList(_catalog['samsung']!));
    if (_anyMatch(q, ['shoe', 'nike', 'adidas', 'sneaker', 'run'])) return Product.assignBadges(_cloneList(_catalog['shoes']!));
    if (_anyMatch(q, ['mac', 'laptop', 'computer', 'notebook', 'dell', 'asus', 'lenovo'])) return Product.assignBadges(_cloneList(_catalog['laptop']!));
    if (_anyMatch(q, ['samsung', 'galaxy'])) return Product.assignBadges(_cloneList(_catalog['samsung']!));

    // Default to headphones as interesting demo
    return Product.assignBadges(_cloneList(_catalog['headphones']!));
  }

  static bool _anyMatch(String q, List<String> keywords) =>
      keywords.any((k) => q.contains(k));

  static List<Product> _cloneList(List<Product> prods) =>
      prods.map((p) => _clone(p)).toList();

  static Product _clone(Product p) => Product(
    id: p.id, title: p.title, platform: p.platform,
    platformIcon: p.platformIcon, emoji: p.emoji,
    price: p.price, originalPrice: p.originalPrice,
    rating: p.rating, reviews: p.reviews,
    delivery: p.delivery, deliveryDays: p.deliveryDays,
    discount: p.discount, affiliateUrl: _listingUrl(platform: p.platform, title: p.title, rawUrl: p.affiliateUrl),
    category: p.category,
  );

  static String _listingUrl({
    required String platform,
    required String title,
    required String rawUrl,
  }) {
    final url = rawUrl.trim();
    if (url.isNotEmpty && !_isRoot(url)) return url;

    final q = Uri.encodeComponent(title);
    final p = platform.toLowerCase();
    if (p.contains('amazon')) return 'https://www.amazon.in/s?k=$q';
    if (p.contains('flipkart')) return 'https://www.flipkart.com/search?q=$q';
    if (p.contains('myntra')) return 'https://www.myntra.com/$q';
    if (p.contains('croma')) return 'https://www.croma.com/searchB?q=$q%3Arelevance';
    return 'https://www.google.com/search?q=$q';
  }

  static bool _isRoot(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return uri.path.isEmpty || uri.path == '/';
  }

  static List<String> get trendingTerms => [
    'AirPods Pro', 'Sony WH-1000XM5', 'iPhone 16', 'MacBook M3',
    'Samsung S24', 'OnePlus 12', 'Nike Air Max', 'Dell XPS 15',
  ];

  static List<String> get categories => [
    '🎧 Headphones', '📱 Smartphones', '💻 Laptops',
    '👟 Shoes', '⌚ Smartwatches', '🎮 Gaming',
  ];
}
