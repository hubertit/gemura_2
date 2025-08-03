import 'dart:io';
import '../../features/chat/domain/models/attachment_message.dart';
import 'hybrid_ai_service.dart';
import '../../core/config/app_config.dart';

class AttachmentProcessorService {
  /// Process attachments and extract meaningful information for bot responses
  static Future<String> processAttachments(List<Attachment> attachments) async {
    if (attachments.isEmpty) return '';
    
    final List<String> processedInfo = [];
    
    for (final attachment in attachments) {
      switch (attachment.type) {
        case AttachmentType.image:
          processedInfo.add(await _processImage(attachment));
          break;
        case AttachmentType.document:
          processedInfo.add(await _processDocument(attachment));
          break;
        case AttachmentType.contact:
          processedInfo.add(_processContact(attachment));
          break;
      }
    }
    
    return processedInfo.join('\n\n');
  }
  
  /// Process image attachments
  static Future<String> _processImage(Attachment attachment) async {
    try {
      final file = File(attachment.path);
      if (!await file.exists()) {
        return 'Image: Unable to access image file';
      }
      
      // Check if AI services are configured
      final isConfigured = AppConfig.chatGptApiKey.isNotEmpty && 
                          AppConfig.chatGptApiKey != 'YOUR_OPENAI_API_KEY_HERE' &&
                          AppConfig.claudeApiKey.isNotEmpty && 
                          AppConfig.claudeApiKey != 'YOUR_CLAUDE_API_KEY_HERE';
      
      if (!isConfigured) {
        // Fallback response when AI services are not configured
        return '''📸 **Image Analysis**
I can see you've shared an image! This looks like it could be related to your dairy operations.

**💡 What I can help with:**
• If it's a supplement or medication, I can help you understand its benefits for your cattle
• If it's a receipt or invoice, I can help with record keeping
• If it's a contact or business card, I can help you manage your network

**🔧 To enable AI image analysis:**
Please configure your OpenAI and Claude AI API keys in the app settings.

**📋 For now, you can:**
• Tell me what the image shows
• Ask me about dairy business topics
• Share contact information instead

What would you like to know about this image? 🐄''';
      }
      
      // Use hybrid AI service (Claude Vision + GPT)
      final response = await HybridAIService.processImageWithHybridAI(File(attachment.path));
      
      return response;
      
    } catch (e) {
      return '''📸 **Image Analysis**
I had trouble analyzing that image, but I can still help you with your dairy business!

**💡 What you can do:**
• Tell me what the image shows
• Ask me about supplements, suppliers, or dairy operations
• Share contact information instead

**🔧 Common dairy topics I can help with:**
• Finding supplement suppliers in your area
• Understanding cattle nutrition
• Managing milk collection and sales
• Connecting with veterinary services

What would you like to know? 🐄''';
    }
  }
  
  /// Process document attachments
  static Future<String> _processDocument(Attachment attachment) async {
    try {
      final file = File(attachment.path);
      if (!await file.exists()) {
        return 'Document: Unable to access document file';
      }
      
      final extension = attachment.fileExtension.toLowerCase();
      String documentType = 'Unknown document';
      String businessContext = '';
      
      switch (extension) {
        case 'pdf':
          documentType = 'PDF Document';
          businessContext = 'This could be a dairy business report, invoice, or contract.';
          break;
        case 'doc':
        case 'docx':
          documentType = 'Word Document';
          businessContext = 'This appears to be a business document, possibly a proposal or report.';
          break;
        case 'xls':
        case 'xlsx':
          documentType = 'Excel Spreadsheet';
          businessContext = 'This looks like financial data or inventory records for your dairy business.';
          break;
        case 'txt':
          documentType = 'Text Document';
          businessContext = 'This contains text information that might be notes or records.';
          break;
        case 'ppt':
        case 'pptx':
          documentType = 'PowerPoint Presentation';
          businessContext = 'This could be a business presentation or training material.';
          break;
      }
      
      String analysis = '''📄 **Document Analysis**
• **Name**: ${attachment.name}
• **Type**: $documentType
• **Size**: ${attachment.readableSize}
• **Format**: ${extension.toUpperCase()}
• **Business Context**: $businessContext''';
      
      // Basic document analysis
      analysis += '\n\n**🤖 AI Analysis**:\n';
      analysis += 'Document analysis requires text extraction. For now, please share text-based documents or use the contact sharing feature.';
      analysis += '\n\n**💡 Tip**: For AI analysis, try sharing:\n';
      analysis += '• Text files (.txt)\n';
      analysis += '• Receipts as images\n';
      analysis += '• Contact information\n';
      
      return analysis;
    } catch (e) {
      return 'Document: Error processing document - $e';
    }
  }
  
  /// Process contact attachments
  static String _processContact(Attachment attachment) {
    try {
      final metadata = attachment.metadata;
      final displayName = metadata?['displayName'] ?? 'Unknown Contact';
      final phones = (metadata?['phones'] as List<dynamic>?) ?? [];
      final emails = (metadata?['emails'] as List<dynamic>?) ?? [];
      
      String contactInfo = '''👤 **Contact Analysis**
• **Name**: $displayName''';
      
      if (phones.isNotEmpty) {
        contactInfo += '\n• **Phone Numbers**: ${phones.join(', ')}';
      }
      
      if (emails.isNotEmpty) {
        contactInfo += '\n• **Email Addresses**: ${emails.join(', ')}';
      }
      
      // Add business context based on contact info
      String businessContext = '';
      if (displayName.toLowerCase().contains('farm') || 
          displayName.toLowerCase().contains('dairy') ||
          displayName.toLowerCase().contains('milk')) {
        businessContext = 'This contact appears to be related to your dairy business network.';
      } else if (phones.isNotEmpty || emails.isNotEmpty) {
        businessContext = 'This contact could be a potential business partner, supplier, or customer.';
      } else {
        businessContext = 'This contact information could be useful for your business network.';
      }
      
      contactInfo += '\n• **Business Context**: $businessContext';
      
      return contactInfo;
    } catch (e) {
      return 'Contact: Error processing contact - $e';
    }
  }
  
  /// Generate contextual bot response based on processed attachment information
  static String generateBotResponse(String processedInfo, List<Attachment> attachments) {
    if (processedInfo.isEmpty) {
      return "I can see you've shared some attachments. How can I help you with these files?";
    }
    
    // Return the processed info directly - it should already contain the conversational response
    return processedInfo;
  }
  
  /// Generate conversational response based on document type
  static String _generateConversationalResponse(String documentType, Map<String, dynamic> keyInfo, String businessRelevance, String aiAnalysis) {
    final lowerDocType = documentType.toLowerCase();
    
    // Handle supplements and medications
    if (lowerDocType.contains('supplement') || lowerDocType.contains('medication') || 
        lowerDocType.contains('product_package') || lowerDocType.contains('nutrition')) {
      return _generateSupplementResponse(keyInfo, businessRelevance, aiAnalysis);
    }
    
    // Handle receipts and invoices
    if (lowerDocType.contains('receipt') || lowerDocType.contains('invoice')) {
      return _generateReceiptResponse(keyInfo, businessRelevance, aiAnalysis);
    }
    
    // Handle contact information
    if (lowerDocType.contains('contact') || lowerDocType.contains('business_card')) {
      return _generateContactResponse(keyInfo, businessRelevance, aiAnalysis);
    }
    
    // Default response for other document types
    return _generateDefaultResponse(documentType, keyInfo, businessRelevance, aiAnalysis);
  }
  
  /// Generate conversational response for supplements and medications
  static String _generateSupplementResponse(Map<String, dynamic> keyInfo, String businessRelevance, String aiAnalysis) {
    String response = '\n\n**💊 What I Found**:\n';
    
    // Extract product name and vendor from AI analysis
    String productName = keyInfo['product'] ?? '';
    String vendor = keyInfo['vendor'] ?? '';
    
    // Build friendly response
    if (productName.isNotEmpty && vendor.isNotEmpty) {
      response += 'This is **$productName** from **$vendor**.\n\n';
    } else if (vendor.isNotEmpty) {
      response += 'This is a veterinary product from **$vendor**.\n\n';
    }
    
    // Use the AI analysis if it's conversational, otherwise provide friendly defaults
    if (aiAnalysis.isNotEmpty && !aiAnalysis.contains('technical') && !aiAnalysis.contains('analysis')) {
      response += aiAnalysis + '\n\n';
    } else {
      response += 'This looks like a supplement that helps keep your cattle healthy and strong.\n\n';
    }
    
    // Add friendly benefits
    response += '**🐄 How it helps your dairy operation**:\n';
    response += '• Keeps your cattle strong and healthy\n';
    response += '• Helps with breeding and reproduction\n';
    response += '• Boosts immune system to prevent diseases\n';
    response += '• Supports growth in young animals\n\n';
    
    // Add friendly safety notes
    response += '**💡 Good to know**:\n';
    response += '• Talk to your vet before using\n';
    response += '• Follow the dosage instructions\n';
    response += '• Store it in a cool, dark place\n';
    response += '• Keep track of when you give it\n\n';
    
    response += '**🤔 Want to know more?**\n';
    response += '• How to give it to your animals?\n';
    response += '• Where to buy it around here?\n';
    response += '• How to store it safely?\n';
    response += '• How much to give each animal?\n\n';
    
    response += 'Just ask me anything about it! 🐄';
    
    return response;
  }
  
  /// Generate conversational response for receipts and invoices
  static String _generateReceiptResponse(Map<String, dynamic> keyInfo, String businessRelevance, String aiAnalysis) {
    String response = '\n\n**🧾 Receipt Analysis**:\n';
    
    if (keyInfo['vendor'] != null) {
      response += 'This is from **${keyInfo['vendor']}**.\n';
    }
    
    if (keyInfo['amount'] != null) {
      response += 'Total amount: **${keyInfo['amount']}**\n';
    }
    
    if (keyInfo['date'] != null) {
      response += 'Date: **${keyInfo['date']}**\n';
    }
    
    response += '\n**💡 Business Tips**:\n';
    response += '• Keep this for your expense records\n';
    response += '• Consider if this is a regular business expense\n';
    response += '• Track spending patterns for budgeting\n\n';
    
    response += '**🤔 Need help with**:\n';
    response += '• Expense categorization\n';
    response += '• Budget planning\n';
    response += '• Tax preparation\n';
    response += '• Financial reporting\n\n';
    
    return response;
  }
  
  /// Generate conversational response for contact information
  static String _generateContactResponse(Map<String, dynamic> keyInfo, String businessRelevance, String aiAnalysis) {
    String response = '\n\n**👤 Contact Information**:\n';
    
    if (keyInfo['vendor'] != null) {
      response += 'Contact: **${keyInfo['vendor']}**\n';
    }
    
    if (keyInfo['contact'] != null) {
      response += 'Details: **${keyInfo['contact']}**\n';
    }
    
    response += '\n**🤔 Would you like to**:\n';
    response += '• Add this to your contacts\n';
    response += '• Set up a meeting\n';
    response += '• Send a follow-up message\n';
    response += '• Get directions to their location\n';
    response += '• Check their business hours\n\n';
    
    return response;
  }
  
  /// Generate default conversational response
  static String _generateDefaultResponse(String documentType, Map<String, dynamic> keyInfo, String businessRelevance, String aiAnalysis) {
    String response = '\n\n**📄 What I Found**:\n';
    
    // Extract key information in a friendly way
    if (keyInfo['vendor'] != null) {
      response += 'This is from **${keyInfo['vendor']}**.\n';
    }
    
    if (keyInfo['amount'] != null) {
      response += 'Amount: **${keyInfo['amount']}**\n';
    }
    
    if (keyInfo['date'] != null) {
      response += 'Date: **${keyInfo['date']}**\n';
    }
    
    if (keyInfo['contact'] != null) {
      response += 'Contact: **${keyInfo['contact']}**\n';
    }
    
    response += '\n';
    
    // Use the AI analysis if it's conversational
    if (aiAnalysis.isNotEmpty && !aiAnalysis.contains('technical') && !aiAnalysis.contains('analysis')) {
      response += aiAnalysis + '\n\n';
    } else if (businessRelevance.isNotEmpty) {
      response += '**💡 Why this matters**:\n';
      response += businessRelevance + '\n\n';
    }
    
    response += '**🤔 How can I help you with this?**\n';
    response += '• Get more details about specific information\n';
    response += '• Understand how it affects your business\n';
    response += '• Help you organize your records\n';
    response += '• Give you insights for better decisions\n\n';
    
    return response;
  }
} 