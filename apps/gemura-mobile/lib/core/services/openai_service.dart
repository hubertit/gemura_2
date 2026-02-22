import '../config/api_config.dart';
import 'dart:io';
import 'dart:convert';

class OpenAIService {
  static bool get _isConfigured => APIConfig.isOpenAIConfigured;

  /// Analyze document content using OpenAI
  static Future<String> analyzeDocumentContent(String extractedText, String documentType) async {
    if (!_isConfigured) {
      return 'OpenAI API not configured. Please check your API key in app_config.dart';
    }
    
    try {
      // For now, return a basic analysis since OpenAI API integration needs to be implemented
      return '''🤖 **AI Analysis**: Document Analysis
      
**Document Type**: $documentType
**Content Length**: ${extractedText.length} characters

**💡 Basic Analysis**:
• This appears to be a $documentType
• Contains ${extractedText.split(' ').length} words of text
• May contain business-relevant information

**🔧 Next Steps**:
• To enable full AI analysis, implement OpenAI API integration
• For now, this provides basic document metadata
• Contact information and business details are processed separately

**📋 Tip**: For better analysis, ensure your OpenAI API key is properly configured.''';
    } catch (e) {
      return 'Error analyzing document: $e. Please check your OpenAI API key and internet connection.';
    }
  }

  /// Generate business insights from document content
  static Future<String> generateBusinessInsights(String extractedText) async {
    if (!_isConfigured) {
      return 'OpenAI API not configured. Please check your API key in app_config.dart';
    }
    
    try {
      // For now, return basic business insights
      return '''💼 **Business Insights**: Basic Analysis
      
**📊 Document Overview**:
• Content length: ${extractedText.length} characters
• Word count: ${extractedText.split(' ').length} words
• Potential business relevance: Dairy operations

**💡 Basic Insights**:
• This document may contain business information
• Consider categorizing for dairy business records
• Review for any financial or operational data

**🔧 To Enable Full AI Analysis**:
• Implement proper OpenAI API integration
• Configure API key in app_config.dart
• Enable advanced document processing

**📋 Current Features**:
• Contact information processing ✅
• Document metadata analysis ✅
• Basic file type classification ✅''';
    } catch (e) {
      return 'Error generating insights: $e';
    }
  }

  /// Analyze image using OpenAI Vision API
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
      
      final request = await HttpClient().openUrl('POST', url);
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Authorization', 'Bearer ${APIConfig.openAIKey}');
      request.write(jsonEncode(body));
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseBody);
        final content = jsonResponse['choices'][0]['message']['content'];
        
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
        return {
          'extractedText': 'Error: ${response.statusCode}',
          'analysis': 'Failed to analyze image',
          'hasText': false,
        };
      }
    } catch (e) {
      return {
        'extractedText': 'Error analyzing image: $e',
        'analysis': 'Failed to process image',
        'hasText': false,
      };
    }
  }

  /// Process receipt and extract structured data
  static Future<Map<String, dynamic>> processReceipt(String extractedText) async {
    if (!_isConfigured) {
      return {
        'vendor_name': 'Unknown',
        'date': 'N/A',
        'total_amount': 'N/A',
        'items': [],
        'payment_method': 'N/A',
        'category': 'Unknown',
        'error': 'OpenAI API not configured'
      };
    }
    
    try {
      // For now, return basic receipt structure
      return {
        'vendor_name': 'Receipt Analysis',
        'date': 'N/A',
        'total_amount': 'N/A',
        'items': [],
        'payment_method': 'N/A',
        'category': 'Document',
        'note': 'Basic receipt processing. Enable OpenAI API for full analysis.'
      };
    } catch (e) {
      return {
        'vendor_name': 'Unknown',
        'date': 'N/A',
        'total_amount': 'N/A',
        'items': [],
        'payment_method': 'N/A',
        'category': 'Unknown',
        'error': 'Error processing receipt: $e'
      };
    }
  }


} 