import 'dart:io';
import 'dart:convert';
import '../config/api_config.dart';

class OpenAIVisionService {
  static bool get _isConfigured => APIConfig.isOpenAIConfigured;
  
  /// Analyze image using OpenAI Vision API (GPT-4 Vision)
  static Future<Map<String, dynamic>> analyzeImage(String imagePath) async {
    if (!_isConfigured) {
      return {
        'extractedText': 'OpenAI API not configured',
        'analysis': 'Please configure your OpenAI API key',
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
      final url = Uri.parse('https://api.openai.com/v1/chat/completions');
      // Headers are set directly on the request
      
      final body = {
        'model': 'gpt-4-vision-preview',
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': '''Analyze this image and extract all text content. If this is a receipt, invoice, or business document, provide detailed analysis including:

1. All text content found in the image
2. Document type (receipt, invoice, business card, etc.)
3. Key information like amounts, dates, vendor names, contact details
4. Business relevance for dairy operations

Format your response as JSON with these fields:
{
  "extractedText": "all text found in image",
  "documentType": "receipt/invoice/business_card/etc",
  "keyInfo": {
    "vendor": "vendor name if found",
    "amount": "total amount if found", 
    "date": "date if found",
    "contact": "contact info if found"
  },
  "businessRelevance": "how this relates to dairy business",
  "analysis": "detailed analysis of the document"
}'''
              },
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:image/jpeg;base64,$base64Image'
                }
              }
            ]
          }
        ],
        'max_tokens': 1000,
        'temperature': 0.3,
      };
      
      print('🚀 Sending request to OpenAI Vision API...');
      
      final request = await HttpClient().openUrl('POST', url);
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Authorization', 'Bearer ${APIConfig.openAIKey}');
      request.write(jsonEncode(body));
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      print('📊 OpenAI Vision Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseBody);
        final content = jsonResponse['choices'][0]['message']['content'];
        
        print('📝 OpenAI Vision Response: $content');
        
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
        print('❌ OpenAI Vision API Error: ${response.statusCode}');
        print('Response: $responseBody');
        return {
          'extractedText': 'Error: ${response.statusCode}',
          'analysis': 'Failed to analyze image with OpenAI Vision',
          'hasText': false,
        };
      }
    } catch (e) {
      print('❌ OpenAI Vision Error: $e');
      return {
        'extractedText': 'Error analyzing image: $e',
        'analysis': 'Failed to process image with OpenAI Vision',
        'hasText': false,
      };
    }
  }
} 