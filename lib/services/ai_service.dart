// lib/services/ai_service.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

// ---------------------------------------------------------------------------
// Enums & Data Models
// ---------------------------------------------------------------------------

/// Supported AI providers for meal analysis.
enum AiProvider { openai, gemini }

/// A single food component suggested by the AI.
class AiSuggestedItem {
  /// Display name of the detected food component.
  String name;

  /// Estimated weight in grams.
  int estimatedGrams;

  /// Confidence score between 0.0 and 1.0.
  double confidence;

  /// Barcode of a matched product in the local database (filled after fuzzy matching).
  String? matchedBarcode;

  AiSuggestedItem({
    required this.name,
    required this.estimatedGrams,
    required this.confidence,
    this.matchedBarcode,
  });

  factory AiSuggestedItem.fromJson(Map<String, dynamic> json) {
    return AiSuggestedItem(
      name: json['name'] as String? ?? 'Unknown',
      estimatedGrams: (json['estimatedGrams'] as num?)?.toInt() ?? 100,
      confidence:
          (json['confidence'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 0.5,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'estimatedGrams': estimatedGrams,
        'confidence': confidence,
      };
}

// ---------------------------------------------------------------------------
// Exceptions
// ---------------------------------------------------------------------------

/// Base exception for AI service errors.
sealed class AiServiceException implements Exception {
  final String message;
  const AiServiceException(this.message);
  @override
  String toString() => message;
}

class AiKeyMissingException extends AiServiceException {
  const AiKeyMissingException()
      : super('No API key configured for the selected provider.');
}

class AiAuthException extends AiServiceException {
  const AiAuthException(
      [String msg = 'Authentication failed. Please check your API key.'])
      : super(msg);
}

class AiNetworkException extends AiServiceException {
  const AiNetworkException(
      [String msg = 'Network error. Please check your connection.'])
      : super(msg);
}

class AiParseException extends AiServiceException {
  const AiParseException([String msg = 'Could not parse the AI response.'])
      : super(msg);
}

class AiRateLimitException extends AiServiceException {
  const AiRateLimitException(
      [String msg = 'Rate limit exceeded. Please wait a moment.'])
      : super(msg);
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Provider-agnostic AI service for meal analysis.
///
/// Supports OpenAI GPT-4o and Google Gemini. Stores API keys in native
/// encrypted storage (Keychain / Keystore) via [FlutterSecureStorage].
class AiService {
  AiService._();
  static final AiService instance = AiService._();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Secure storage keys per provider
  static const _keyPrefix = 'ai_api_key_';
  static const _providerKey = 'ai_selected_provider';

  /// The system prompt instructs the AI to decompose every meal into atomic
  /// food components and return strict JSON.
  static const _systemPrompt = '''
You are a nutrition analysis assistant. Analyze the provided meal image(s) or description.

CRITICAL RULES:
1. Break down EVERY meal into its individual, atomic, loggable food components.
   For example, "Cheeseburger with fries" must become: burger bun, beef patty, cheese slice, lettuce, tomato, ketchup, french fries — each as a separate item with its own estimated weight.
2. Do NOT return composite meal names. Always decompose into individual ingredients.
3. Estimate weights in grams as accurately as possible based on visual cues or typical serving sizes.
4. Set confidence between 0.0 and 1.0 based on how certain you are about each item and its quantity.

Respond ONLY with a valid JSON array. No markdown, no explanation, no extra text.
Each element must have exactly these fields:
- "name": string (individual food component name, in the user's language if identifiable)
- "estimatedGrams": integer (estimated weight in grams)
- "confidence": number (0.0 to 1.0)

Example response:
[{"name": "Beef Patty", "estimatedGrams": 150, "confidence": 0.85}, {"name": "Burger Bun", "estimatedGrams": 60, "confidence": 0.9}]
''';

  // ---------------------------------------------------------------------------
  // Key Management
  // ---------------------------------------------------------------------------

  /// Reads the stored API key for the given [provider].
  Future<String?> getApiKey(AiProvider provider) async {
    return _secureStorage.read(key: '$_keyPrefix${provider.name}');
  }

  /// Stores the API key for the given [provider] securely.
  Future<void> setApiKey(AiProvider provider, String key) async {
    await _secureStorage.write(key: '$_keyPrefix${provider.name}', value: key);
  }

  /// Deletes the stored API key for the given [provider].
  Future<void> deleteApiKey(AiProvider provider) async {
    await _secureStorage.delete(key: '$_keyPrefix${provider.name}');
  }

  /// Returns the currently selected provider (default: OpenAI).
  Future<AiProvider> getSelectedProvider() async {
    final value = await _secureStorage.read(key: _providerKey);
    if (value == 'gemini') return AiProvider.gemini;
    return AiProvider.openai;
  }

  /// Persists the selected provider.
  Future<void> setSelectedProvider(AiProvider provider) async {
    await _secureStorage.write(key: _providerKey, value: provider.name);
  }

  // ---------------------------------------------------------------------------
  // Analysis
  // ---------------------------------------------------------------------------

  /// Analyzes one or more meal images and returns suggested food items.
  ///
  /// Optionally accepts a [textHint] describing the meal for better accuracy.
  Future<List<AiSuggestedItem>> analyzeImages(
    List<File> images, {
    String? textHint,
  }) async {
    final provider = await getSelectedProvider();
    final apiKey = await getApiKey(provider);
    if (apiKey == null || apiKey.isEmpty) throw const AiKeyMissingException();

    // Encode images to base64
    final imageDataList = <String>[];
    for (final img in images) {
      final bytes = await img.readAsBytes();
      imageDataList.add(base64Encode(bytes));
    }

    final userContent =
        textHint ?? 'Analyze this meal and identify all food components.';

    switch (provider) {
      case AiProvider.openai:
        return _callOpenAi(apiKey, userContent, imageDataList);
      case AiProvider.gemini:
        return _callGemini(apiKey, userContent, imageDataList);
    }
  }

  /// Analyzes a text-only meal description and returns suggested food items.
  Future<List<AiSuggestedItem>> analyzeText(String description) async {
    final provider = await getSelectedProvider();
    final apiKey = await getApiKey(provider);
    if (apiKey == null || apiKey.isEmpty) throw const AiKeyMissingException();

    switch (provider) {
      case AiProvider.openai:
        return _callOpenAi(apiKey, description, []);
      case AiProvider.gemini:
        return _callGemini(apiKey, description, []);
    }
  }

  /// Retries analysis with user feedback to refine the results.
  Future<List<AiSuggestedItem>> retry({
    required List<AiSuggestedItem> previousResults,
    required String feedback,
    List<File>? images,
  }) async {
    final provider = await getSelectedProvider();
    final apiKey = await getApiKey(provider);
    if (apiKey == null || apiKey.isEmpty) throw const AiKeyMissingException();

    final previousJson =
        jsonEncode(previousResults.map((e) => e.toJson()).toList());
    final userContent = '''
Previous analysis result:
$previousJson

User correction/feedback: $feedback

Please provide an updated analysis incorporating the user's feedback. Return the corrected JSON array.''';

    // Re-encode images if provided
    final imageDataList = <String>[];
    if (images != null) {
      for (final img in images) {
        final bytes = await img.readAsBytes();
        imageDataList.add(base64Encode(bytes));
      }
    }

    switch (provider) {
      case AiProvider.openai:
        return _callOpenAi(apiKey, userContent, imageDataList);
      case AiProvider.gemini:
        return _callGemini(apiKey, userContent, imageDataList);
    }
  }

  /// Tests whether the API key is valid by sending a minimal request.
  Future<bool> testConnection() async {
    try {
      await analyzeText(
          'Test: reply with [{"name":"Test","estimatedGrams":1,"confidence":1.0}]');
      return true;
    } on AiServiceException {
      rethrow;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Provider-specific HTTP calls
  // ---------------------------------------------------------------------------

  Future<List<AiSuggestedItem>> _callOpenAi(
    String apiKey,
    String userContent,
    List<String> imagesBase64,
  ) async {
    final contentParts = <Map<String, dynamic>>[];

    // Add image parts
    for (final img64 in imagesBase64) {
      contentParts.add({
        'type': 'image_url',
        'image_url': {
          'url': 'data:image/jpeg;base64,$img64',
          'detail': 'low',
        },
      });
    }

    // Add text part
    contentParts.add({
      'type': 'text',
      'text': userContent,
    });

    final body = jsonEncode({
      'model': 'gpt-4o',
      'messages': [
        {'role': 'system', 'content': _systemPrompt},
        {'role': 'user', 'content': contentParts},
      ],
      'max_tokens': 2000,
      'temperature': 0.3,
    });

    try {
      final response = await http
          .post(
            Uri.parse('https://api.openai.com/v1/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 60));

      return _handleOpenAiResponse(response);
    } on SocketException {
      throw const AiNetworkException();
    } catch (e) {
      if (e is AiServiceException) rethrow;
      throw AiNetworkException('Request failed: $e');
    }
  }

  List<AiSuggestedItem> _handleOpenAiResponse(http.Response response) {
    if (response.statusCode == 401) throw const AiAuthException();
    if (response.statusCode == 429) throw const AiRateLimitException();
    if (response.statusCode != 200) {
      throw AiNetworkException('API returned status ${response.statusCode}');
    }

    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = json['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) throw const AiParseException();

      final messageContent = choices[0]['message']['content'] as String? ?? '';
      return _parseItemsFromContent(messageContent);
    } catch (e) {
      if (e is AiServiceException) rethrow;
      throw const AiParseException();
    }
  }

  Future<List<AiSuggestedItem>> _callGemini(
    String apiKey,
    String userContent,
    List<String> imagesBase64,
  ) async {
    final parts = <Map<String, dynamic>>[];

    // Add image parts
    for (final img64 in imagesBase64) {
      parts.add({
        'inlineData': {
          'mimeType': 'image/jpeg',
          'data': img64,
        },
      });
    }

    // Add text parts (system prompt + user content combined)
    parts.add({'text': '$_systemPrompt\n\n$userContent'});

    final body = jsonEncode({
      'contents': [
        {'parts': parts}
      ],
      'generationConfig': {
        'temperature': 0.3,
        'maxOutputTokens': 2000,
      },
    });

    try {
      final response = await http
          .post(
            Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey',
            ),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 60));

      return _handleGeminiResponse(response);
    } on SocketException {
      throw const AiNetworkException();
    } catch (e) {
      if (e is AiServiceException) rethrow;
      throw AiNetworkException('Request failed: $e');
    }
  }

  List<AiSuggestedItem> _handleGeminiResponse(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const AiAuthException();
    }
    if (response.statusCode == 429) throw const AiRateLimitException();
    if (response.statusCode != 200) {
      throw AiNetworkException('API returned status ${response.statusCode}');
    }

    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = json['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty)
        throw const AiParseException();

      final content = candidates[0]['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) throw const AiParseException();

      final text = parts[0]['text'] as String? ?? '';
      return _parseItemsFromContent(text);
    } catch (e) {
      if (e is AiServiceException) rethrow;
      throw const AiParseException();
    }
  }

  // ---------------------------------------------------------------------------
  // JSON Parsing
  // ---------------------------------------------------------------------------

  /// Extracts the JSON array from the AI response text.
  ///
  /// Handles cases where the AI wraps JSON in markdown code fences.
  List<AiSuggestedItem> _parseItemsFromContent(String content) {
    // Strip markdown code fences if present
    var cleaned = content.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceFirst(RegExp(r'^```\w*\n?'), '');
      cleaned = cleaned.replaceFirst(RegExp(r'\n?```$'), '');
      cleaned = cleaned.trim();
    }

    // Find JSON array boundaries
    final startIdx = cleaned.indexOf('[');
    final endIdx = cleaned.lastIndexOf(']');
    if (startIdx == -1 || endIdx == -1 || endIdx <= startIdx) {
      throw const AiParseException('No JSON array found in response.');
    }

    final jsonStr = cleaned.substring(startIdx, endIdx + 1);
    final List<dynamic> items = jsonDecode(jsonStr) as List<dynamic>;

    if (items.isEmpty) {
      throw const AiParseException('AI returned an empty list.');
    }

    return items
        .map((e) => AiSuggestedItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
