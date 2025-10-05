import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/feed_service.dart';
import '../../../../shared/widgets/primary_button.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _hashtagController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  
  File? _selectedImage;
  List<String> _hashtags = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _contentController.dispose();
    _hashtagController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Create Post',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _publishPost,
            child: Text(
              'Publish',
              style: TextStyle(
                color: _isLoading ? Colors.grey : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Section
            _buildUserInfoSection(),
            
            const SizedBox(height: AppTheme.spacing24),
            
            // Content Input
            _buildContentSection(),
            
            const SizedBox(height: AppTheme.spacing24),
            
            // Image Section
            _buildImageSection(),
            
            const SizedBox(height: AppTheme.spacing24),
            
            // Hashtags Section
            _buildHashtagsSection(),
            
            const SizedBox(height: AppTheme.spacing24),
            
            // Location Section
            _buildLocationSection(),
            
            const SizedBox(height: AppTheme.spacing32),
            
            // Publish Button
            _buildPublishButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoSection() {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: const Icon(
            Icons.person,
            color: AppTheme.primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: AppTheme.spacing12),
        const Text(
          'Your Post',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildContentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What\'s on your mind?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: AppTheme.spacing12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: TextField(
            controller: _contentController,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: 'Share your thoughts, experiences, or updates...',
              hintStyle: TextStyle(color: AppTheme.textSecondaryColor),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(AppTheme.spacing16),
            ),
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add Photo',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: AppTheme.spacing12),
        if (_selectedImage != null) ...[
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
              child: Image.file(
                _selectedImage!,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Change Photo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: AppTheme.primaryColor),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _removeImage,
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Remove'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
              border: Border.all(
                color: AppTheme.borderColor,
                style: BorderStyle.solid,
                width: 2,
              ),
            ),
            child: InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    size: 48,
                    color: AppTheme.primaryColor.withOpacity(0.6),
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  Text(
                    'Tap to add photo',
                    style: TextStyle(
                      color: AppTheme.primaryColor.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHashtagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hashtags',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: AppTheme.spacing12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: TextField(
            controller: _hashtagController,
            decoration: const InputDecoration(
              hintText: 'Add hashtags (e.g., #agriculture #farming)',
              hintStyle: TextStyle(color: AppTheme.textSecondaryColor),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(AppTheme.spacing16),
            ),
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textPrimaryColor,
            ),
            onSubmitted: _addHashtag,
          ),
        ),
        if (_hashtags.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spacing12),
          Wrap(
            spacing: AppTheme.spacing8,
            runSpacing: AppTheme.spacing8,
            children: _hashtags.map((hashtag) => _buildHashtagChip(hashtag)).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildHashtagChip(String hashtag) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing12,
        vertical: AppTheme.spacing6,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            hashtag,
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: AppTheme.spacing4),
          GestureDetector(
            onTap: () => _removeHashtag(hashtag),
            child: const Icon(
              Icons.close,
              size: 16,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location (Optional)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: AppTheme.spacing12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: TextField(
            controller: _locationController,
            decoration: const InputDecoration(
              hintText: 'Where are you?',
              hintStyle: TextStyle(color: AppTheme.textSecondaryColor),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(AppTheme.spacing16),
              prefixIcon: Icon(
                Icons.location_on,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPublishButton() {
    return SizedBox(
      width: double.infinity,
      child: PrimaryButton(
        onPressed: _isLoading ? null : _publishPost,
        text: _isLoading ? 'Publishing...' : 'Publish Post',
        isLoading: _isLoading,
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  void _addHashtag(String hashtag) {
    if (hashtag.trim().isNotEmpty) {
      String cleanHashtag = hashtag.trim();
      if (!cleanHashtag.startsWith('#')) {
        cleanHashtag = '#$cleanHashtag';
      }
      
      if (!_hashtags.contains(cleanHashtag)) {
        setState(() {
          _hashtags.add(cleanHashtag);
          _hashtagController.clear();
        });
      }
    }
  }

  void _removeHashtag(String hashtag) {
    setState(() {
      _hashtags.remove(hashtag);
    });
  }

  Future<void> _publishPost() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write something to share'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare post data
      final postData = {
        'content': _contentController.text.trim(),
        'hashtags': _hashtags,
        'location': _locationController.text.trim().isNotEmpty 
            ? _locationController.text.trim() 
            : null,
        'media_url': _selectedImage != null 
            ? _selectedImage!.path // For now, we'll use local path
            : null,
      };

      // Call the API to create post
      final response = await FeedService.createPost(
        content: postData['content']!,
        mediaUrl: postData['media_url'],
        hashtags: postData['hashtags'] as List<String>,
        location: postData['location'] as String?,
      );

      if (mounted) {
        if (response['code'] == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post published successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Clear form
          _contentController.clear();
          _hashtagController.clear();
          _locationController.clear();
          setState(() {
            _selectedImage = null;
            _hashtags.clear();
          });
          
          // Navigate back
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${response['message'] ?? 'Failed to publish post'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error publishing post: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
