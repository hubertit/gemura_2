import 'dart:io';
import 'dart:convert';
import '../config/api_config.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class OpenAIVisionService {
  static bool get _isConfigured => APIConfig.isOpenAIConfigured;
  
  /// Analyze image using OpenAI Vision API (GPT-4 Vision)
  static Future<Map<String, dynamic>> analyzeImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConfig.openaiApiKey}',
        },
        body: jsonEncode({
          'model': 'gpt-4-vision-preview',
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': 'Analyze this image for a dairy farmer. Extract any text, identify document types, and provide business-relevant insights. Focus on: 1) Any text content 2) Document type (receipt, invoice, medical record, etc.) 3) Key business information 4) How this relates to dairy farming operations. Return as JSON with keys: extractedText, documentType, keyInfo, businessRelevance, analysis',
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$base64Image',
                  },
                },
              ],
            },
          ],
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        
        // Try to parse as JSON, fallback to text if it's not JSON
        try {
          return jsonDecode(content);
        } catch (e) {
          return {
            'extractedText': content,
            'documentType': 'Unknown',
            'keyInfo': {},
            'businessRelevance': 'Document analysis completed',
            'analysis': content,
          };
        }
      } else {
        final responseBody = response.body;
        return {
          'extractedText': 'Unable to analyze image',
          'documentType': 'Unknown',
          'keyInfo': {},
          'businessRelevance': 'Analysis failed',
          'analysis': 'Error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'extractedText': 'Error processing image',
        'documentType': 'Unknown',
        'keyInfo': {},
        'businessRelevance': 'Processing error',
        'analysis': 'Exception: $e',
      };
    }
  }
} 