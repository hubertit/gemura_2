import 'package:share_plus/share_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class InviteService {
  static InviteService? _instance;
  static InviteService get instance => _instance ??= InviteService._();
  
  InviteService._();

  /// Generate a referral code for the current user
  String generateReferralCode(String userId) {
    // Create a simple referral code based on user ID
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    final userCode = userId.substring(0, 3).toUpperCase();
    return 'GEM${userCode}${timestamp}';
  }

  /// Get app information for sharing
  Future<Map<String, String>> getAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return {
      'appName': packageInfo.appName,
      'version': packageInfo.version,
      'buildNumber': packageInfo.buildNumber,
    };
  }

  /// Create invite message with referral code
  Future<String> createInviteMessage(String referralCode, {String? customMessage}) async {
    final appInfo = await getAppInfo();
    
    final defaultMessage = '''
🌟 Join me on ${appInfo['appName']} - The ultimate dairy management app!

🚀 What you can do:
• Manage your dairy business
• Track milk collections and sales
• Connect with suppliers and customers
• Access financial services
• And much more!

📱 Download now and use my referral code: $referralCode

Get started today and transform your dairy business! 🐄💪

#DairyManagement #GemuraApp #BusinessGrowth
''';

    return customMessage ?? defaultMessage;
  }

  /// Share app via system share sheet
  Future<void> shareApp({
    required String referralCode,
    String? customMessage,
    String? subject,
  }) async {
    try {
      final message = await createInviteMessage(referralCode, customMessage: customMessage);
      final appInfo = await getAppInfo();
      
      await Share.share(
        message,
        subject: subject ?? 'Join me on ${appInfo['appName']}!',
      );
    } catch (e) {
      print('Error sharing app: $e');
      rethrow;
    }
  }

  /// Share via WhatsApp
  Future<void> shareViaWhatsApp({
    required String referralCode,
    String? customMessage,
    String? phoneNumber,
  }) async {
    try {
      final message = await createInviteMessage(referralCode, customMessage: customMessage);
      final encodedMessage = Uri.encodeComponent(message);
      
      String url;
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        // Share to specific contact
        url = 'https://wa.me/$phoneNumber?text=$encodedMessage';
      } else {
        // Open WhatsApp without specific contact
        url = 'https://wa.me/?text=$encodedMessage';
      }
      
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch WhatsApp');
      }
    } catch (e) {
      print('Error sharing via WhatsApp: $e');
      rethrow;
    }
  }

  /// Share via SMS
  Future<void> shareViaSMS({
    required String referralCode,
    String? customMessage,
    String? phoneNumber,
  }) async {
    try {
      final message = await createInviteMessage(referralCode, customMessage: customMessage);
      
      String url;
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        url = 'sms:$phoneNumber?body=${Uri.encodeComponent(message)}';
      } else {
        url = 'sms:?body=${Uri.encodeComponent(message)}';
      }
      
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch SMS app');
      }
    } catch (e) {
      print('Error sharing via SMS: $e');
      rethrow;
    }
  }

  /// Share via Email
  Future<void> shareViaEmail({
    required String referralCode,
    String? customMessage,
    String? email,
    String? subject,
  }) async {
    try {
      final message = await createInviteMessage(referralCode, customMessage: customMessage);
      final appInfo = await getAppInfo();
      
      String url;
      if (email != null && email.isNotEmpty) {
        url = 'mailto:$email?subject=${Uri.encodeComponent(subject ?? 'Join me on ${appInfo['appName']}!')}&body=${Uri.encodeComponent(message)}';
      } else {
        url = 'mailto:?subject=${Uri.encodeComponent(subject ?? 'Join me on ${appInfo['appName']}!')}&body=${Uri.encodeComponent(message)}';
      }
      
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch email app');
      }
    } catch (e) {
      print('Error sharing via email: $e');
      rethrow;
    }
  }

  /// Get device contacts
  Future<List<Contact>> getContacts() async {
    try {
      // Check and request permission
      final permission = await Permission.contacts.request();
      if (permission != PermissionStatus.granted) {
        throw Exception('Contacts permission denied');
      }

      // Get contacts
      final contacts = await ContactsService.getContacts(
        withThumbnails: false,
        photoHighResolution: false,
      );

      return contacts;
    } catch (e) {
      print('Error getting contacts: $e');
      rethrow;
    }
  }

  /// Check if contacts permission is granted
  Future<bool> hasContactsPermission() async {
    final permission = await Permission.contacts.status;
    return permission == PermissionStatus.granted;
  }

  /// Request contacts permission
  Future<bool> requestContactsPermission() async {
    final permission = await Permission.contacts.request();
    return permission == PermissionStatus.granted;
  }

  /// Get contacts with phone numbers only
  Future<List<Contact>> getContactsWithPhone() async {
    final contacts = await getContacts();
    return contacts.where((contact) => 
      contact.phones != null && 
      contact.phones!.isNotEmpty
    ).toList();
  }

  /// Get contacts with email addresses only
  Future<List<Contact>> getContactsWithEmail() async {
    final contacts = await getContacts();
    return contacts.where((contact) => 
      contact.emails != null && 
      contact.emails!.isNotEmpty
    ).toList();
  }

  /// Copy referral code to clipboard
  Future<void> copyReferralCode(String referralCode) async {
    // Note: You might want to use flutter/services Clipboard for this
    // For now, we'll use the share functionality
    await Share.share(
      referralCode,
      subject: 'My Gemura Referral Code',
    );
  }

  /// Generate QR code data for referral
  String generateQRCodeData(String referralCode) {
    final appInfo = getAppInfo();
    return 'gemura://invite?code=$referralCode';
  }

  /// Validate referral code format
  bool isValidReferralCode(String code) {
    // Check if code matches the format: GEM + 3 letters + timestamp
    final regex = RegExp(r'^GEM[A-Z]{3}\d{5}$');
    return regex.hasMatch(code);
  }

  /// Extract user ID from referral code
  String? extractUserIdFromReferralCode(String code) {
    if (!isValidReferralCode(code)) return null;
    
    // Extract the 3-letter user code from the referral code
    final userCode = code.substring(3, 6);
    return userCode;
  }
}
