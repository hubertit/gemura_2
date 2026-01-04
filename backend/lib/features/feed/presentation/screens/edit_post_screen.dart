import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/feed_service.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../domain/models/post.dart';
import '../providers/feed_provider.dart';

class EditPostScreen extends ConsumerStatefulWidget {
  final Post post;

  const EditPostScreen({
    super.key,
    required this.post,
  });

  @override
  ConsumerState<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends ConsumerState<EditPostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _hashtagController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  
  File? _selectedImage;
  final List<String> _hashtags = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    _contentController.text = widget.post.content ?? '';
    _hashtags.addAll(widget.post.hashtags);
    _locationController.text = widget.post.location ?? '';
  }

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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Edit Post',
          style: AppTheme.titleLarge.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _updatePost,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Update',
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.primaryColor,
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
            
            // Update Button
            _buildUpdateButton(),
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
        Text(
          'Editing Post',
          style: AppTheme.titleMedium.copyWith(
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
        Text(
          'What\'s on your mind?',
          style: AppTheme.titleMedium.copyWith(
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
            style: AppTheme.bodyMedium.copyWith(
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
        Text(
          'Post Image',
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: AppTheme.spacing12),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: _selectedImage != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: AppTheme.spacing8,
                        right: AppTheme.spacing8,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImage = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(AppTheme.spacing4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : widget.post.imageUrls.isNotEmpty
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                            child: Image.network(
                              widget.post.imageUrls.first,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppTheme.borderColor,
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    color: AppTheme.textSecondaryColor,
                                    size: 48,
                                  ),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            top: AppTheme.spacing8,
                            right: AppTheme.spacing8,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedImage = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(AppTheme.spacing4),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo,
                            color: AppTheme.textSecondaryColor,
                            size: 40,
                          ),
                          const SizedBox(height: AppTheme.spacing8),
                          Text(
                            'Add Photo',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
          ),
        ),
      ],
    );
  }

  Widget _buildHashtagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hashtags',
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: AppTheme.spacing12),
        TextField(
          controller: _hashtagController,
          decoration: InputDecoration(
            hintText: 'Add hashtags (e.g., #agriculture #farming)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(AppTheme.spacing16),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addHashtag,
            ),
          ),
          onSubmitted: (_) => _addHashtag(),
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textPrimaryColor,
          ),
        ),
        if (_hashtags.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spacing12),
          Wrap(
            spacing: AppTheme.spacing8,
            runSpacing: AppTheme.spacing8,
            children: _hashtags
                .map(
                  (hashtag) => Chip(
                    label: Text(hashtag),
                    onDeleted: () => _removeHashtag(hashtag),
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    labelStyle: AppTheme.bodySmall.copyWith(color: AppTheme.primaryColor),
                    deleteIconColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
                      side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: AppTheme.spacing12),
        TextField(
          controller: _locationController,
          decoration: InputDecoration(
            hintText: 'Add location (optional)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(AppTheme.spacing16),
            prefixIcon: const Icon(Icons.location_on_outlined),
          ),
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textPrimaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateButton() {
    return SizedBox(
      width: double.infinity,
      child: PrimaryButton(
        onPressed: _isLoading ? null : _updatePost,
        label: _isLoading ? 'Updating...' : 'Update Post',
        isLoading: _isLoading,
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addHashtag() {
    final text = _hashtagController.text.trim();
    if (text.isNotEmpty) {
      final newHashtags = text
          .split(RegExp(r'[,\s]+'))
          .where((tag) => tag.isNotEmpty)
          .map((tag) => tag.startsWith('#') ? tag : '#$tag')
          .toList();
      setState(() {
        _hashtags.addAll(newHashtags.where((tag) => !_hashtags.contains(tag)));
        _hashtagController.clear();
      });
    }
  }

  void _removeHashtag(String hashtag) {
    setState(() {
      _hashtags.remove(hashtag);
    });
  }

  Future<void> _updatePost() async {
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
        'media_url': _selectedImage?.path, // For now, we'll use local path
      };

      // Call the API to update post
      final response = await FeedService.updatePost(
        postId: int.parse(widget.post.id),
        content: postData['content'] as String,
        mediaUrl: postData['media_url'] as String?,
        hashtags: postData['hashtags'] as List<String>,
        location: postData['location'] as String?,
      );

      if (mounted) {
        if (response['code'] == 200) {
          // Refresh feed to show the updated post
          ref.read(feedProvider.notifier).refreshFeed();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navigate back
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${response['message'] ?? 'Failed to update post'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating post: $e'),
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
