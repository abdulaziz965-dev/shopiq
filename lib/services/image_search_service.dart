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
  static const _supportedMediaTypes = {
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/gif',
  };

  bool get _hasApiKey => _anthropicKey.isNotEmpty && !_anthropicKey.startsWith('YOUR_');

  /// Identify product in image using Claude Vision.
  /// Returns a search query string like "Sony WH-1000XM5 headphones"
  Future<ImageIdentifyResult> identifyProduct(File imageFile) async {
    if (!_hasApiKey) throw StateError('Missing ANTHROPIC_API_KEY');

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    final mediaType = _detectMediaType(imageFile.path);

    final body = _buildVisionBody(base64Image, mediaType);

    final resp = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': _anthropicKey,
        'anthropic-version': '2023-06-01',
      },
      body: body,
    ).timeout(const Duration(seconds: 30));

    if (resp.statusCode != 200) {
      throw Exception('Vision API ${resp.statusCode}: ${resp.body}');
    }

    final text = _extractTextFromResponse(resp.body);
    return _parseIdentifyResult(text);
  }

  /// Identify product from raw bytes (for web/cross-platform use)
  Future<ImageIdentifyResult> identifyProductFromBytes(
    Uint8List bytes,
    String mimeType,
  ) async {
    if (!_hasApiKey) throw StateError('Missing ANTHROPIC_API_KEY');

    final base64Image = base64Encode(bytes);

    final normalizedMimeType = _normalizeMediaType(mimeType);
    final body = _buildVisionBody(base64Image, normalizedMimeType);

    final resp = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': _anthropicKey,
        'anthropic-version': '2023-06-01',
      },
      body: body,
    ).timeout(const Duration(seconds: 30));

    if (resp.statusCode != 200) {
      throw Exception('Vision API ${resp.statusCode}: ${resp.body}');
    }

    final text = _extractTextFromResponse(resp.body);
    return _parseIdentifyResult(text);
  }

  String _buildVisionPrompt() => '''Identify the primary consumer product in this image.
Return ONLY valid JSON (no markdown, no extra text) with exactly these keys:
{"name":"exact product name with brand and model if visible","category":"smartphone|laptop|headphones|earphones|smartwatch|shoes|camera|tablet|tv|clothing|other","brand":"brand","confidence":"high|medium|low","searchQuery":"optimized search query for Amazon India / Flipkart"}
If uncertain, set confidence to "low" and provide your best short guess.''';

  String _buildVisionBody(String base64Image, String mediaType) => jsonEncode({
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
            'text': _buildVisionPrompt(),
          }
        ],
      }
    ],
  });

  String _extractTextFromResponse(String responseBody) {
    final data = jsonDecode(responseBody) as Map<String, dynamic>;
    final content = data['content'];
    if (content is List && content.isNotEmpty) {
      final first = content.first;
      if (first is Map<String, dynamic>) {
        final text = first['text'];
        if (text is String && text.trim().isNotEmpty) return text.trim();
      }
    }
    throw const FormatException('Vision response did not contain text content.');
  }

  ImageIdentifyResult _parseIdentifyResult(String rawText) {
    final cleaned = rawText.replaceAll(RegExp(r'```json\s*|```\s*'), '').trim();

    Map<String, dynamic>? parsed;
    try {
      parsed = jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (_) {
      final match = RegExp(r'\{[\s\S]*\}').firstMatch(cleaned);
      if (match != null) {
        try {
          parsed = jsonDecode(match.group(0)!) as Map<String, dynamic>;
        } catch (_) {
          parsed = null;
        }
      }
    }

    final productName = (parsed?['name'] as String?)?.trim();
    final brand = (parsed?['brand'] as String?)?.trim() ?? '';
    final category = _normalizeCategory((parsed?['category'] as String?)?.trim());
    final confidence = _normalizeConfidence((parsed?['confidence'] as String?)?.trim());
    final searchQuery = (parsed?['searchQuery'] as String?)?.trim();

    final fallbackText = cleaned.isEmpty ? 'product' : cleaned;
    final safeText = fallbackText.length > 80 ? fallbackText.substring(0, 80) : fallbackText;

    return ImageIdentifyResult(
      productName: productName?.isNotEmpty == true ? productName! : safeText,
      category: category,
      brand: brand,
      confidence: confidence,
      searchQuery: searchQuery?.isNotEmpty == true ? searchQuery! : (productName?.isNotEmpty == true ? productName! : safeText),
    );
  }

  String _normalizeMediaType(String mimeType) {
    final value = mimeType.trim().toLowerCase();
    if (value == 'image/jpg') return 'image/jpeg';
    if (_supportedMediaTypes.contains(value)) return value;
    return 'image/jpeg';
  }

  String _normalizeCategory(String? category) {
    const allowed = {
      'smartphone',
      'laptop',
      'headphones',
      'earphones',
      'smartwatch',
      'shoes',
      'camera',
      'tablet',
      'tv',
      'clothing',
      'other',
    };
    final value = (category ?? '').toLowerCase();
    return allowed.contains(value) ? value : 'other';
  }

  String _normalizeConfidence(String? confidence) {
    final value = (confidence ?? '').toLowerCase();
    switch (value) {
      case 'high':
      case 'medium':
      case 'low':
        return value;
      default:
        return 'low';
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
