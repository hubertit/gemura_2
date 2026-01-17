import 'dart:io';
import 'dart:convert';
import '../config/app_config.dart';

class ClaudeVisionService {
  static bool get _isConfigured => AppConfig.claudeApiKey.isNotEmpty && 
                                  AppConfig.claudeApiKey != 'YOUR_CLAUDE_API_KEY_HERE';

  /// Analyze image using Claude AI Vision API
  static Future<Map<String, dynamic>> analyzeImage(String imagePath) async {
    if (!_isConfigured) {
      return {
        'extractedText': 'Claude AI API not configured',
        'analysis': 'Please configure your Claude AI API key',
        'hasText': false,
      };
    }

    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        return {
          'extractedText': 'Image file not found',
          'analysis': 'Unable to access image file',
          'hasText': false,
        };
      }

      // Read image as base64
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Prepare the API request
      final url = Uri.parse(AppConfig.claudeApiUrl);
      // Headers are set directly on the request

      final body = {
        'model': 'claude-3-5-sonnet-20241022',
        'max_tokens': 1000,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': '''Look at this image and tell me what you see in a friendly, conversational way. If this is a veterinary product, supplement, or medication, explain it like you're talking to a dairy farmer who wants to understand:

1. What the product is and who makes it
2. What it's used for in dairy operations
3. How it helps with animal health
4. Any important safety or usage notes

For supplements and medications, focus on:
- Product name and manufacturer
- What it does for livestock (muscle function, immune support, etc.)
- Why it's important for dairy operations
- Safety considerations

Format your response as JSON with these fields:
{
  "extractedText": "text found in image",
  "documentType": "supplement/medication/receipt/etc",
  "keyInfo": {
    "vendor": "manufacturer name",
    "product": "product name if found",
    "purpose": "what it's used for"
  },
  "businessRelevance": "why this matters for dairy farming",
  "analysis": "friendly explanation of the product and its benefits"
}'''
              },
              {
                'type': 'image',
                'source': {
                  'type': 'base64',
                  'media_type': 'image/jpeg',
                  'data': base64Image
                }
              }
            ]
          }
        ]
      };

      // print('🚀 Sending request to Claude Vision API...');

      final request = await HttpClient().openUrl('POST', url);
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('x-api-key', AppConfig.claudeApiKey);
      request.headers.set('anthropic-version', '2023-06-01');
      request.write(jsonEncode(body));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      // print('📊 Claude Vision Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseBody);
        final content = jsonResponse['content'][0]['text'];

        // print('📝 Claude Vision Response: $content');

        try {
          // Try to parse as JSON
          final analysis = jsonDecode(content);
          return {
            'extractedText': analysis['extractedText'] ?? 'No text found',
            'documentType': analysis['documentType'] ?? 'Unknown',
            'keyInfo': analysis['keyInfo'] ?? {},
            'businessRelevance': analysis['businessRelevance'] ?? '',
            'analysis': analysis['analysis'] ?? '',
            'hasText': (analysis['extractedText'] ?? '').isNotEmpty,
          };
        } catch (e) {
          // If not JSON, return as plain text
          return {
            'extractedText': content,
            'documentType': 'Unknown',
            'keyInfo': {},
            'businessRelevance': '',
            'analysis': content,
            'hasText': content.isNotEmpty,
          };
        }
      } else {
        // print('❌ Claude Vision API Error: ${response.statusCode}');
        // print('Response: $responseBody');
        return {
          'extractedText': 'Error: ${response.statusCode}',
          'analysis': 'Failed to analyze image with Claude Vision',
          'hasText': false,
        };
      }
    } catch (e) {
      // print('❌ Claude Vision Error: $e');
      return {
        'extractedText': 'Error analyzing image: $e',
        'analysis': 'Failed to process image with Claude Vision',
        'hasText': false,
      };
    }
  }
} 