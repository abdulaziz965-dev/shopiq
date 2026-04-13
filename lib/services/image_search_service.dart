import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// ImageSearchService
///
/// Flow:
///   1. User picks image (camera or gallery)
///   2. Image sent to Claude Vision → identifies product name + brand + model
///   3. Identified query passed to RealSearchService for live listings
class ImageSearchService {
  static const _anthropicKey = String.fromEnvironment('ANTHROPIC_API_KEY', defaultValue: '');
  static const _model = 'claude-sonnet-4-20250514';

  bool get _hasApiKey => _anthropicKey.isNotEmpty && !_anthropicKey.startsWith('YOUR_');

  /// Identify product in image using Claude Vision.
  /// Returns a search query string like "Sony WH-1000XM5 headphones"
  Future<ImageIdentifyResult> identifyProduct(File imageFile) async {
    if (!_hasApiKey) throw StateError('Missing ANTHROPIC_API_KEY');

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    final mediaType = _detectMediaType(imageFile.path);

    final body = jsonEncode({
      'model': _model,
      'max_tokens': 200,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'image',
              'source': {
                'type': 'base64',
                'media_type': mediaType,
                'data': base64Image,
              },
            },
            {
              'type': 'text',
              'text': '''Identify the product in this image. 
Respond ONLY with a JSON object (no markdown) in this exact format:
{
  "name": "exact product name with brand and model",
  "category": "one of: smartphone, laptop, headphones, earphones, smartwatch, shoes, camera, tablet, tv, clothing, other",
  "brand": "brand name",
  "confidence": "high | medium | low",
  "searchQuery": "optimized search query for Indian e-commerce sites like Amazon India and Flipkart"
}

If you cannot identify a product, set confidence to "low" and make a best guess.'''
            }
          ],
        }
      ],
    });

    final resp = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': _anthropicKey,
        'anthropic-version': '2023-06-01',
      },
      body: body,
    ).timeout(const Duration(seconds: 15));

    if (resp.statusCode != 200) {
      throw Exception('Vision API error: ${resp.statusCode}');
    }

    final data = jsonDecode(resp.body);
    final text = data['content'][0]['text'] as String;

    // Strip any markdown fences if present
    final cleaned = text.replaceAll(RegExp(r'```json\s*|```\s*'), '').trim();
    final parsed = jsonDecode(cleaned) as Map<String, dynamic>;

    return ImageIdentifyResult(
      productName: parsed['name'] as String? ?? 'Unknown Product',
      category: parsed['category'] as String? ?? 'other',
      brand: parsed['brand'] as String? ?? '',
      confidence: parsed['confidence'] as String? ?? 'low',
      searchQuery: parsed['searchQuery'] as String? ?? parsed['name'] as String? ?? 'product',
    );
  }

  /// Identify product from raw bytes (for web/cross-platform use)
  Future<ImageIdentifyResult> identifyProductFromBytes(
    Uint8List bytes,
    String mimeType,
  ) async {
    if (!_hasApiKey) throw StateError('Missing ANTHROPIC_API_KEY');

    final base64Image = base64Encode(bytes);

    final body = jsonEncode({
      'model': _model,
      'max_tokens': 200,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'image',
              'source': {
                'type': 'base64',
                'media_type': mimeType,
                'data': base64Image,
              },
            },
            {
              'type': 'text',
              'text': '''Identify the product in this image. 
Respond ONLY with a JSON object (no markdown, no explanation):
{"name":"product name with brand and model","category":"smartphone|laptop|headphones|earphones|smartwatch|shoes|camera|tablet|tv|clothing|other","brand":"brand","confidence":"high|medium|low","searchQuery":"search query optimized for Amazon India / Flipkart"}

If no product visible, use confidence: "low" and best guess.'''
            }
          ],
        }
      ],
    });

    final resp = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': _anthropicKey,
        'anthropic-version': '2023-06-01',
      },
      body: body,
    ).timeout(const Duration(seconds: 15));

    if (resp.statusCode != 200) {
      throw Exception('Vision API ${resp.statusCode}: ${resp.body}');
    }

    final data = jsonDecode(resp.body);
    final text = (data['content'][0]['text'] as String)
        .replaceAll(RegExp(r'```json\s*|```\s*'), '')
        .trim();

    try {
      final parsed = jsonDecode(text) as Map<String, dynamic>;
      return ImageIdentifyResult(
        productName: parsed['name'] as String? ?? 'Product',
        category: parsed['category'] as String? ?? 'other',
        brand: parsed['brand'] as String? ?? '',
        confidence: parsed['confidence'] as String? ?? 'low',
        searchQuery: parsed['searchQuery'] as String? ?? 'product',
      );
    } catch (_) {
      // Fallback: treat whole response as product name
      return ImageIdentifyResult(
        productName: text.length > 60 ? text.substring(0, 60) : text,
        category: 'other',
        brand: '',
        confidence: 'low',
        searchQuery: text.length > 60 ? text.substring(0, 60) : text,
      );
    }
  }

  String _detectMediaType(String path) {
    final ext = path.toLowerCase().split('.').last;
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }
}

class ImageIdentifyResult {
  final String productName;
  final String category;
  final String brand;
  final String confidence; // high | medium | low
  final String searchQuery;

  const ImageIdentifyResult({
    required this.productName,
    required this.category,
    required this.brand,
    required this.confidence,
    required this.searchQuery,
  });

  bool get isHighConfidence => confidence == 'high';
  bool get isLowConfidence => confidence == 'low';

  String get emoji {
    switch (category) {
      case 'smartphone': return '📱';
      case 'laptop': return '💻';
      case 'headphones': return '🎵';
      case 'earphones': return '🎧';
      case 'smartwatch': return '⌚';
      case 'shoes': return '👟';
      case 'camera': return '📷';
      case 'tablet': return '📱';
      case 'tv': return '📺';
      case 'clothing': return '👕';
      default: return '📦';
    }
  }
}
