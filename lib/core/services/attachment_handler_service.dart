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
      // print('Opening camera...');
      final File? photo = await AttachmentService.takePhoto();
      // print('Camera result: ${photo?.path ?? 'null'}');
      
      if (photo != null) {
        return [photo];
      } else {
        // User cancelled camera
        // print('Camera was cancelled by user');
        return null;
      }
    } catch (e) {
      // print('Camera error: $e');
      _showErrorSnackBar(context, 'Camera error: ${e.toString()}');
      return null;
    }
  }

  /// Handle gallery attachment
  static Future<List<File>?> handleGallery(BuildContext context) async {
    try {
      // print('Opening gallery...');
      final List<File> images = await AttachmentService.pickImages();
      // print('Gallery result: ${images.length} images');
      
      if (images.isNotEmpty) {
        return images;
      } else {
        // User cancelled gallery picker
        // print('Gallery picker was cancelled by user');
        return null;
      }
    } catch (e) {
      // print('Gallery error: $e');
      _showErrorSnackBar(context, 'Gallery error: ${e.toString()}');
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
      _showPermissionError(context, 'Document Picker', e.toString());
      return null;
    }
  }

  /// Handle contacts attachment
  static Future<List<Contact>?> handleContacts(BuildContext context) async {
    try {
      // print('Opening contact selection...');
      
      final selectedContacts = await Navigator.push<List<Contact>>(
        context,
        MaterialPageRoute(
          builder: (context) => const ContactSelectionScreen(),
        ),
      );
      
      if (selectedContacts != null && selectedContacts.isNotEmpty) {
        // print('Selected contacts: ${selectedContacts.length}');
        return selectedContacts;
      } else {
        // User cancelled contact selection
        // print('Contact selection was cancelled by user');
        return null;
      }
    } catch (e) {
      // print('Contacts error: $e');
      _showErrorSnackBar(context, 'Contacts error: ${e.toString()}');
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