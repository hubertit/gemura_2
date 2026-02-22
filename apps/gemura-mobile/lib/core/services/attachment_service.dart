import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AttachmentService {
  static final ImagePicker _imagePicker = ImagePicker();

  // Camera functionality
  static Future<File?> takePhoto() async {
    try {
      // Let image_picker handle permissions directly
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to take photo: $e');
    }
  }

  // Gallery functionality
  static Future<List<File>> pickImages() async {
    try {
      // Let image_picker handle permissions directly
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      return images.map((image) => File(image.path)).toList();
    } catch (e) {
      throw Exception('Failed to pick images: $e');
    }
  }

  // Document functionality
  static Future<List<File>> pickDocuments() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx', 'ppt', 'pptx'
        ],
        allowMultiple: true,
      );

      if (result != null) {
        return result.paths.map((path) => File(path!)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to pick documents: $e');
    }
  }

  // Contacts functionality
  static Future<List<Contact>> pickContacts() async {
    try {
      // Load contacts in background to avoid UI blocking
      final contacts = await Future(() async {
        return await ContactsService.getContacts();
      });
      return contacts.toList();
    } catch (e) {
      throw Exception('Failed to pick contacts: $e');
    }
  }

  // Get file size in readable format
  static String getFileSize(File file) {
    final bytes = file.lengthSync();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // Get file extension
  static String getFileExtension(String fileName) {
    return fileName.split('.').last.toLowerCase();
  }

  // Get file icon based on extension
  static IconData getFileIcon(String extension) {
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'txt':
        return Icons.text_snippet;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  // Open app settings
  static Future<void> openAppSettings() async {
    try {
      // Try to open app settings directly
      final Uri settingsUri = Uri(
        scheme: 'app-settings',
      );
      
      if (await canLaunchUrl(settingsUri)) {
        await launchUrl(settingsUri);
      } else {
        // Fallback: Open iOS Settings app
        final Uri iosSettingsUri = Uri(
          scheme: 'App-Prefs',
        );
        await launchUrl(iosSettingsUri);
      }
    } catch (e) {
      // Final fallback: Try to open general settings
      final Uri generalSettingsUri = Uri(
        scheme: 'App-Prefs',
        path: 'root=General',
      );
      await launchUrl(generalSettingsUri);
    }
  }
} 