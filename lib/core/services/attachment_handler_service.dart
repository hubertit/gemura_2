import 'dart:io';
import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';
import '../../core/theme/app_theme.dart';
import '../../features/chat/presentation/screens/contact_selection_screen.dart';
import 'attachment_service.dart';

class AttachmentHandlerService {
  /// Handle camera attachment
  static Future<List<File>?> handleCamera(BuildContext context) async {
    try {
      final File? photo = await AttachmentService.takePhoto();
      
      if (photo != null) {
        return [photo];
      } else {
        // User cancelled camera
        return null;
      }
    } catch (e) {
      // Don't use context after async operation
      return null;
    }
  }

  /// Handle gallery attachment
  static Future<List<File>?> handleGallery(BuildContext context) async {
    try {
      final List<File> images = await AttachmentService.pickImages();
      
      if (images.isNotEmpty) {
        return images;
      } else {
        // User cancelled gallery picker
        return null;
      }
    } catch (e) {
      // Don't use context after async operation
      return null;
    }
  }

  /// Handle document attachment
  static Future<List<File>?> handleDocument(BuildContext context) async {
    try {
      final List<File> documents = await AttachmentService.pickDocuments();
      if (documents.isNotEmpty) {
        return documents;
      }
      return null;
    } catch (e) {
      // Don't use context after async operation
      return null;
    }
  }

  /// Handle contacts attachment
  static Future<List<Contact>?> handleContacts(BuildContext context) async {
    try {
      final selectedContacts = await Navigator.push<List<Contact>>(
        context,
        MaterialPageRoute(
          builder: (context) => const ContactSelectionScreen(),
        ),
      );
      
      if (selectedContacts != null && selectedContacts.isNotEmpty) {
        return selectedContacts;
      } else {
        // User cancelled contact selection
        return null;
      }
    } catch (e) {
      // Don't use context after async operation
      return null;
    }
  }

  /// Show error snackbar
  static void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.snackbarErrorColor,
      ),
    );
  }

  /// Show permission error dialog
  static void _showPermissionError(BuildContext context, String feature, String error) {
    final isPermanentlyDenied = error.contains('permanently denied');
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Permission Required'),
          content: Text(
            isPermanentlyDenied
                ? 'This app needs access to $feature to function properly. Please enable it in your device settings.'
                : 'Please grant permission to access $feature.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            if (isPermanentlyDenied)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  AttachmentService.openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
          ],
        );
      },
    );
  }

  /// Get attachment text for different types
  static String getAttachmentText(String type, int count) {
    switch (type.toLowerCase()) {
      case 'image':
        return count == 1 ? '📷 Image' : '📷 $count Images';
      case 'document':
        return count == 1 ? '📄 Document' : '📄 $count Documents';
      case 'contact':
        return count == 1 ? '👤 Contact' : '👤 $count Contacts';
      default:
        return count == 1 ? '📎 Attachment' : '📎 $count Attachments';
    }
  }
} 