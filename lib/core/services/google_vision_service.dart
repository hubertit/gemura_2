import 'dart:io';
import 'dart:convert';
import '../config/api_config.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class GoogleVisionService {
  static bool get _isConfigured => APIConfig.isGoogleVisionConfigured;
  
  /// Analyze image using Google Cloud Vision API
  static Future<Map<String, dynamic>> analyzeImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse('https://vision.googleapis.com/v1/images:annotate?key=${AppConfig.googleVisionApiKey}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'requests': [
            {
              'image': {
                'content': base64Image,
              },
              'features': [
                {
                  'type': 'TEXT_DETECTION',
                  'maxResults': 1,
                },
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responses = data['responses'] as List;
        
        if (responses.isNotEmpty && responses.first['textAnnotations'] != null) {
          final textAnnotations = responses.first['textAnnotations'] as List;
          final extractedText = textAnnotations.isNotEmpty ? textAnnotations.first['description'] ?? '' : '';
          
          return {
            'extractedText': extractedText,
            'documentType': 'Unknown',
            'keyInfo': {},
            'businessRelevance': 'Text extraction completed',
            'analysis': 'Successfully extracted text from image',
          };
        } else {
          return {
            'extractedText': 'No text found in image',
            'documentType': 'Unknown',
            'keyInfo': {},
            'businessRelevance': 'No text detected',
            'analysis': 'No readable text found in image',
          };
        }
      } else {
        return {
          'extractedText': 'Unable to process image',
          'documentType': 'Unknown',
          'keyInfo': {},
          'businessRelevance': 'Service error',
          'analysis': 'HTTP error: ${response.statusCode}',
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
  
  /// Analyze extracted text to determine document type and key information
  static Map<String, dynamic> _analyzeExtractedText(String text) {
    final lowerText = text.toLowerCase();
    
    // Determine document type
    String documentType = 'Unknown';
    if (lowerText.contains('receipt') || lowerText.contains('total') || lowerText.contains('subtotal')) {
      documentType = 'Receipt';
    } else if (lowerText.contains('invoice') || lowerText.contains('bill')) {
      documentType = 'Invoice';
    } else if (lowerText.contains('@') || lowerText.contains('phone') || lowerText.contains('email')) {
      documentType = 'Contact Information';
    } else if (lowerText.contains('bank') || lowerText.contains('account') || lowerText.contains('balance')) {
      documentType = 'Bank Statement';
    } else if (lowerText.contains('milk') || lowerText.contains('dairy') || lowerText.contains('farm')) {
      documentType = 'Dairy Business Document';
    }
    
    // Extract key information
    Map<String, dynamic> keyInfo = {};
    
    // Extract amounts (look for currency patterns)
    final amountRegex = RegExp(r'\$?\d+\.?\d*');
    final amounts = amountRegex.allMatches(text);
    if (amounts.isNotEmpty) {
      keyInfo['amount'] = amounts.first.group(0);
    }
    
    // Extract dates
    final dateRegex = RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}');
    final dates = dateRegex.allMatches(text);
    if (dates.isNotEmpty) {
      keyInfo['date'] = dates.first.group(0);
    }
    
    // Extract vendor/store names (look for common patterns)
    final vendorPatterns = [
      RegExp(r'(?:store|shop|market|supermarket|mall):\s*([^\n]+)', caseSensitive: false),
      RegExp(r'(?:vendor|merchant|business):\s*([^\n]+)', caseSensitive: false),
    ];
    
    for (final pattern in vendorPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        keyInfo['vendor'] = match.group(1)?.trim();
        break;
      }
    }
    
    // Extract contact information
    final emailRegex = RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b');
    final email = emailRegex.firstMatch(text);
    if (email != null) {
      keyInfo['email'] = email.group(0);
    }
    
    final phoneRegex = RegExp(r'(\+?\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}');
    final phone = phoneRegex.firstMatch(text);
    if (phone != null) {
      keyInfo['phone'] = phone.group(0);
    }
    
    // Generate business relevance
    String businessRelevance = '';
    if (documentType == 'Receipt' || documentType == 'Invoice') {
      businessRelevance = 'This appears to be a financial document. Consider tracking this expense for your dairy business records.';
    } else if (documentType == 'Contact Information') {
      businessRelevance = 'This contains contact information that could be useful for business networking or supplier management.';
    } else if (documentType == 'Dairy Business Document') {
      businessRelevance = 'This document is directly related to your dairy operations. Important for business management.';
    } else {
      businessRelevance = 'This document may contain information relevant to your dairy business operations.';
    }
    
    // Generate analysis
    String analysis = '';
    if (text.isNotEmpty) {
      analysis = 'I found text in this image! Here\'s what I detected:\n';
      analysis += '• Document type: $documentType\n';
      if (keyInfo.isNotEmpty) {
        analysis += '• Key information extracted:\n';
        keyInfo.forEach((key, value) {
          analysis += '  - ${key.toUpperCase()}: $value\n';
        });
      }
      analysis += '• Business relevance: $businessRelevance';
    }
    
    return {
      'documentType': documentType,
      'keyInfo': keyInfo,
      'businessRelevance': businessRelevance,
      'analysis': analysis,
    };
  }
} 