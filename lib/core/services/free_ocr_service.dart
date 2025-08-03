import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class FreeOCRService {
  /// Analyze image using a free OCR service
  static Future<Map<String, dynamic>> analyzeImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        return {
          'extractedText': 'Image file not found',
          'analysis': 'Unable to access image file',
          'hasText': false,
        };
      }
      
      // Read image as bytes for multipart request
      final bytes = await file.readAsBytes();
      
      // Use a free OCR service (OCR.space API - 500 requests/month free)
      final url = Uri.parse('https://api.ocr.space/parse/image');
      
      final request = http.MultipartRequest('POST', url)
        ..fields['apikey'] = 'K894634387496' // Free API key
        ..fields['language'] = 'eng'
        ..fields['isOverlayRequired'] = 'false'
        ..fields['filetype'] = 'jpeg'
        ..files.add(http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: 'image.jpg',
        ));
      
      print('🚀 Sending request to free OCR service...');
      
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      print('📊 Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseBody);
        
        if (jsonResponse['IsErroredOnProcessing'] == false) {
          final parsedResults = jsonResponse['ParsedResults'] as List;
          
          if (parsedResults.isNotEmpty) {
            final parsedText = parsedResults.first['ParsedText'] ?? '';
            
            print('📝 Extracted Text: "$parsedText"');
            
            if (parsedText.isNotEmpty) {
              // Analyze the extracted text
              final analysis = _analyzeExtractedText(parsedText);
              
              return {
                'extractedText': parsedText,
                'documentType': analysis['documentType'],
                'keyInfo': analysis['keyInfo'],
                'businessRelevance': analysis['businessRelevance'],
                'analysis': analysis['analysis'],
                'hasText': true,
              };
            } else {
              return {
                'extractedText': 'No text found in image',
                'documentType': 'Unknown',
                'keyInfo': {},
                'businessRelevance': '',
                'analysis': 'No readable text detected in this image',
                'hasText': false,
              };
            }
          } else {
            return {
              'extractedText': 'No text found in image',
              'documentType': 'Unknown',
              'keyInfo': {},
              'businessRelevance': '',
              'analysis': 'No readable text detected in this image',
              'hasText': false,
            };
          }
        } else {
          return {
            'extractedText': 'Error processing image',
            'analysis': 'Failed to process image with OCR service',
            'hasText': false,
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