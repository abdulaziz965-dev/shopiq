class Product {
  final String id;
  final String title;
  final String platform;
  final String platformIcon;
  final String emoji;
  final double price;
  final double originalPrice;
  final double rating;
  final int reviews;
  final String delivery;
  final int deliveryDays;
  final int discount;
  final String affiliateUrl;
  final String category;
  final String? imageUrl;

  bool isBest;
  bool isCheapest;
  bool isTopRated;
  bool isFastest;
  double score;

  Product({
    required this.id,
    required this.title,
    required this.platform,
    required this.platformIcon,
    required this.emoji,
    required this.price,
    required this.originalPrice,
    required this.rating,
    required this.reviews,
    required this.delivery,
    required this.deliveryDays,
    required this.discount,
    required this.affiliateUrl,
    required this.category,
    this.imageUrl,
    this.isBest = false,
    this.isCheapest = false,
    this.isTopRated = false,
    this.isFastest = false,
    this.score = 0,
  });

  static double calcScore(Product p) {
    final deliveryScore = (5 - p.deliveryDays).clamp(0, 5) * 10.0;
    return (p.rating * 20) + (p.discount.clamp(0, 50) * 0.8) + deliveryScore;
  }

  static List<Product> assignBadges(List<Product> products) {
    if (products.isEmpty) return products;
    for (final p in products) {
      p.score = calcScore(p);
      p.isBest = false; p.isCheapest = false; p.isTopRated = false; p.isFastest = false;
    }
    products.reduce((a, b) => a.price < b.price ? a : b).isCheapest = true;
    products.reduce((a, b) => a.rating > b.rating ? a : b).isTopRated = true;
    products.reduce((a, b) => a.deliveryDays < b.deliveryDays ? a : b).isFastest = true;
    products.reduce((a, b) => a.score > b.score ? a : b).isBest = true;
    products.sort((a, b) => b.score.compareTo(a.score));
    return products;
  }

  bool get hasVerifiedReviews => reviews > 15000;
  bool get suspiciousReviews => reviews < 50 && rating > 4.8;

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'platform': platform,
    'platformIcon': platformIcon, 'emoji': emoji,
    'price': price, 'originalPrice': originalPrice,
    'rating': rating, 'reviews': reviews,
    'delivery': delivery, 'deliveryDays': deliveryDays,
    'discount': discount, 'affiliateUrl': affiliateUrl,
    'category': category, 'imageUrl': imageUrl,
  };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    platform: json['platform'] ?? '',
    platformIcon: json['platformIcon'] ?? '🛒',
    emoji: json['emoji'] ?? '📦',
    price: (json['price'] as num?)?.toDouble() ?? 0,
    originalPrice: (json['originalPrice'] as num?)?.toDouble() ?? 0,
    rating: (json['rating'] as num?)?.toDouble() ?? 4.0,
    reviews: json['reviews'] ?? 0,
    delivery: json['delivery'] ?? '3-5 days',
    deliveryDays: json['deliveryDays'] ?? 3,
    discount: json['discount'] ?? 0,
    affiliateUrl: json['affiliateUrl'] ?? '',
    category: json['category'] ?? 'general',
    imageUrl: json['imageUrl'],
  );
}

class PricePoint {
  final DateTime date;
  final double price;
  final String platform;
  const PricePoint({required this.date, required this.price, required this.platform});
}
