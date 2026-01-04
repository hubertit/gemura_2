import 'dart:io';

class MockOCRService {
  /// Mock image analysis - simulates what the bot should do
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
      
      // Simulate processing time
      await Future.delayed(const Duration(seconds: 2));
      
      // Mock extracted text based on file name or simulate different document types
      String mockText = '';
      String documentType = 'Unknown';
      Map<String, dynamic> keyInfo = {};
      
      // Simulate different types of documents based on file path
      if (imagePath.toLowerCase().contains('receipt')) {
        mockText = '''RECEIPT
Store: Walmart
Date: 12/15/2024
Items:
- Milk \$3.99
- Bread \$2.49
- Eggs \$4.99
Total: \$11.47
Payment: Credit Card''';
        documentType = 'Receipt';
        keyInfo = {
          'vendor': 'Walmart',
          'amount': r'$11.47',
          'date': '12/15/2024',
          'payment_method': 'Credit Card'
        };
      } else if (imagePath.toLowerCase().contains('invoice')) {
        mockText = '''INVOICE #12345
ABC Company
Date: 12/10/2024
Services:
- Consulting \$500.00
- Materials \$150.00
Subtotal: \$650.00
Tax: \$52.00
Total: \$702.00''';
        documentType = 'Invoice';
        keyInfo = {
          'vendor': 'ABC Company',
          'amount': r'$702.00',
          'date': '12/10/2024',
          'invoice_number': '12345'
        };
      } else if (imagePath.toLowerCase().contains('contact')) {
        mockText = '''John Smith
Marketing Manager
ABC Corporation
Email: john.smith@abc.com
Phone: (555) 123-4567
Address: 123 Business St, City, State 12345''';
        documentType = 'Contact Information';
        keyInfo = {
          'name': 'John Smith',
          'email': 'john.smith@abc.com',
          'phone': '(555) 123-4567',
          'company': 'ABC Corporation'
        };
      } else {
        // Default mock text
        mockText = '''Sample Document
This is a sample document with text content.
It contains various information that could be useful
for business purposes.

Date: 12/20/2024
Amount: \$150.00
Contact: info@example.com''';
        documentType = 'Business Document';
        keyInfo = {
          'amount': r'$150.00',
          'date': '12/20/2024',
          'email': 'info@example.com'
        };
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
      if (mockText.isNotEmpty) {
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
        'extractedText': mockText,
        'documentType': documentType,
        'keyInfo': keyInfo,
        'businessRelevance': businessRelevance,
        'analysis': analysis,
        'hasText': true,
      };
      
    } catch (e) {
      return {
        'extractedText': 'Error analyzing image: $e',
        'analysis': 'Failed to process image',
        'hasText': false,
      };
    }
  }
} 