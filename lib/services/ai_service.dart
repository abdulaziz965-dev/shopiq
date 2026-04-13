import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class AIService {
  static const _apiKey = String.fromEnvironment('ANTHROPIC_API_KEY', defaultValue: '');

  static const _model  = 'claude-sonnet-4-20250514';
  static const _url    = 'https://api.anthropic.com/v1/messages';

  static const _system = '''You are ShopIQ AI, an expert Indian shopping assistant.
Focus on practical buying advice: best value, reliability, delivery, and seller trust.
Always mention prices in Indian Rupees (₹) when discussing price.
Keep replies concise and actionable (2-5 bullet points or short lines).
If the prompt is vague, ask one clarifying question.
Flag suspicious review patterns for fraud risk.''';

  bool get _hasApiKey => _apiKey.isNotEmpty && !_apiKey.startsWith('YOUR_');

  /// AI recommendation summary shown above search results.
  Future<String> generateSearchSummary(List<Product> products, String query) async {
    if (products.isEmpty) return '';
    final best = products.first;

    final listing = products.take(3).toList().asMap().entries.map((e) {
      final p = e.value;
      return '${e.key + 1}. ${p.title} on ${p.platform} — ₹${_fmt(p.price)}, '
          '${p.rating}★, ${p.reviews} reviews, ${p.delivery} delivery, ${p.discount}% off';
    }).join('\n');

    final prompt = 'User searched for "$query". Top results:\n$listing\n\n'
        'Write a SHORT 2-sentence recommendation (max 55 words). '
        'Lead with the best pick and why. Include an emoji. Mention platform name.';

    try {
      return await _call(prompt, maxTokens: 130);
    } catch (_) {
      return '🏆 **${best.title}** on ${best.platform} is the top pick — '
          '₹${_fmt(best.price)} with ${best.rating}★ and ${best.delivery} delivery.';
    }
  }

  /// Full conversational chat.
  Future<String> chat(List<Map<String, String>> history, String message) async {
    if (!_hasApiKey) return _fallback(message);

    final normalizedHistory = history
        .where((m) => (m['role'] == 'user' || m['role'] == 'assistant') && (m['content']?.trim().isNotEmpty ?? false))
        .map((m) => {'role': m['role']!, 'content': m['content']!.trim()})
        .toList();
    final recent = normalizedHistory.length > 8
        ? normalizedHistory.sublist(normalizedHistory.length - 8)
        : normalizedHistory;

    final messages = [
      ...recent,
      {'role': 'user', 'content': message},
    ];

    try {
      final body = jsonEncode({
        'model': _model,
        'max_tokens': 280,
        'temperature': 0.4,
        'system': _system, 'messages': messages,
      });
      final resp = await http.post(Uri.parse(_url),
          headers: _headers, body: body)
          .timeout(const Duration(seconds: 20));
      if (resp.statusCode == 200) {
        return (jsonDecode(resp.body)['content'][0]['text'] as String).trim();
      }
      return _fallback(message);
    } catch (_) {
      return _fallback(message);
    }
  }

  Future<String> _call(String prompt, {int maxTokens = 150}) async {
    if (!_hasApiKey) throw Exception('Missing ANTHROPIC_API_KEY');

    final body = jsonEncode({
      'model': _model, 'max_tokens': maxTokens,
      'temperature': 0.4,
      'messages': [{'role': 'user', 'content': prompt}],
    });
    final resp = await http.post(Uri.parse(_url),
        headers: _headers, body: body)
        .timeout(const Duration(seconds: 20));
    if (resp.statusCode == 200) {
      return (jsonDecode(resp.body)['content'][0]['text'] as String).trim();
    }
    throw Exception('API ${resp.statusCode}');
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'x-api-key': _apiKey,
    'anthropic-version': '2023-06-01',
  };

  String _fallback(String query) {
    final q = query.toLowerCase();
    if (q.contains('fake') || q.contains('review')) {
      return 'Our Review Shield™ flags products with very high ratings but very few reviews '
          '— these are often new listings with manipulated scores. Always check verified purchase badges. 🛡️';
    }
    if (q.contains('best') || q.contains('recommend')) {
      return 'Use the Search tab to find the best deals across Amazon, Flipkart, and Myntra. '
          'ShopIQ ranks results by price, rating, and delivery speed automatically! 🔍';
    }
    return 'Great question! Search for any product and I\'ll rank listings from multiple platforms '
        'and show you the best value deal. 🛒';
  }

  String _fmt(double price) {
    final s = price.toStringAsFixed(0);
    final buf = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      if (count == 3 || (count > 3 && (count - 3) % 2 == 0)) buf.write(',');
      buf.write(s[i]);
      count++;
    }
    return buf.toString().split('').reversed.join();
  }
}
