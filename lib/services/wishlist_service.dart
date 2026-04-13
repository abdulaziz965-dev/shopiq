import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';

class WishlistService extends ChangeNotifier {
  final Map<String, Product> _items = {};
  static const _key = 'shopiq_wishlist';

  Map<String, Product> get items => Map.unmodifiable(_items);
  int get count => _items.length;
  bool isSaved(String id) => _items.containsKey(id);

  WishlistService() {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final Map<String, dynamic> decoded = jsonDecode(raw);
        decoded.forEach((key, value) {
          _items[key] = Product.fromJson(Map<String, dynamic>.from(value));
        });
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = _items.map((k, v) => MapEntry(k, v.toJson()));
      await prefs.setString(_key, jsonEncode(data));
    } catch (_) {}
  }

  void toggle(Product product) {
    if (_items.containsKey(product.id)) {
      _items.remove(product.id);
    } else {
      _items[product.id] = product;
    }
    notifyListeners();
    _saveToStorage();
  }

  void remove(String id) {
    _items.remove(id);
    notifyListeners();
    _saveToStorage();
  }

  // Simulate price drop detection
  bool hasPriceDrop(String id) {
    // In production: compare current price vs stored price
    return id.hashCode % 3 == 0;
  }

  double priceDrop(Product p) {
    return p.originalPrice - p.price;
  }
}
