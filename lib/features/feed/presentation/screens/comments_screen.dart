import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/comment.dart';
import '../../domain/models/post.dart';
import '../../../market/presentation/screens/seller_profile_screen.dart';
import '../../../market/presentation/providers/products_provider.dart';

class CommentsScreen extends ConsumerStatefulWidget {
  final Post post;

  const CommentsScreen({
    super.key,
    required this.post,
  });

  @override
  ConsumerState<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends ConsumerState<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Comment> _comments = [];

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadComments() {
    // Generate mock comments
    _comments = _generateMockComments();
  }

  void _submitComment() {
    if (_commentController.text.trim().isEmpty) return;

    final newComment = Comment(
      id: 'comment_${DateTime.now().millisecondsSinceEpoch}',
      postId: widget.post.id,
      userId: 'current_user',
      userName: 'You',
      userAvatar: 'https://picsum.photos/100/100?random=999',
      content: _commentController.text.trim(),
      createdAt: DateTime.now(),
      isVerified: false,
    );

    setState(() {
      _comments.insert(0, newComment);
    });

    _commentController.clear();
    
    // Scroll to top to show new comment
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        title: Text(
          'Comments',
          style: AppTheme.titleLarge.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Post Header
          _buildPostHeader(),
          
          // Comments List
          Expanded(
            child: _comments.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppTheme.spacing16),
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      return _buildCommentCard(_comments[index]);
                    },
                  ),
          ),
          
          // Comment Input
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildPostHeader() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: widget.post.userAvatar != null
                ? NetworkImage(widget.post.userAvatar!)
                : null,
            child: widget.post.userAvatar == null
                ? const Icon(Icons.person, color: AppTheme.textSecondaryColor)
                : null,
          ),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.post.userName,
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.post.isVerified) ...[
                      const SizedBox(width: AppTheme.spacing4),
                      const Icon(
                        Icons.verified,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                    ],
                  ],
                ),
                if (widget.post.content != null && widget.post.content!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppTheme.spacing4),
                    child: Text(
                      widget.post.content!,
                      style: AppTheme.bodyMedium,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppTheme.textSecondaryColor,
          ),
          const SizedBox(height: AppTheme.spacing16),
          Text(
            'No comments yet',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'Be the first to comment!',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard(Comment comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _navigateToUserProfile(comment),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: comment.userAvatar != null
                  ? NetworkImage(comment.userAvatar!)
                  : null,
              child: comment.userAvatar == null
                  ? const Icon(Icons.person, size: 16, color: AppTheme.textSecondaryColor)
                  : null,
            ),
          ),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _navigateToUserProfile(comment),
                      child: Text(
                        comment.userName,
                        style: AppTheme.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (comment.isVerified) ...[
                      const SizedBox(width: AppTheme.spacing4),
                      const Icon(
                        Icons.verified,
                        size: 14,
                        color: AppTheme.primaryColor,
                      ),
                    ],
                    const SizedBox(width: AppTheme.spacing8),
                    Text(
                      _getTimeAgo(comment.createdAt),
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  comment.content,
                  style: AppTheme.bodyMedium,
                ),
                const SizedBox(height: AppTheme.spacing8),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _likeComment(comment),
                      child: Row(
                        children: [
                          Icon(
                            comment.isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: comment.isLiked ? Colors.red : AppTheme.textSecondaryColor,
                          ),
                          if (comment.likesCount > 0) ...[
                            const SizedBox(width: AppTheme.spacing4),
                            Text(
                              '${comment.likesCount}',
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing16),
                    GestureDetector(
                      onTap: () => _replyToComment(comment),
                      child: Text(
                        'Reply',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          top: BorderSide(
            color: AppTheme.borderColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: const NetworkImage('https://picsum.photos/100/100?random=999'),
            child: null,
          ),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Add a comment...',
                hintStyle: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                  borderSide: BorderSide(color: AppTheme.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                  borderSide: BorderSide(color: AppTheme.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                  borderSide: BorderSide(color: AppTheme.primaryColor),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing16,
                  vertical: AppTheme.spacing12,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submitComment(),
            ),
          ),
          const SizedBox(width: AppTheme.spacing12),
          GestureDetector(
            onTap: _submitComment,
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spacing8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
              ),
              child: const Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToUserProfile(Comment comment) {
    // Create a mock seller from the comment data
    final seller = TopSeller(
      id: int.tryParse(comment.userId) ?? 1,
      code: comment.userId,
      name: comment.userName,
      email: '${comment.userId}@example.com',
      phone: '+250700000000',
      imageUrl: comment.userAvatar,
      totalProducts: 0,
      totalSales: 0,
      rating: 4.5,
      isVerified: comment.isVerified,
      location: 'Kigali, Rwanda',
      joinDate: DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SellerProfileScreen(seller: seller),
      ),
    );
  }

  void _likeComment(Comment comment) {
    setState(() {
      final index = _comments.indexWhere((c) => c.id == comment.id);
      if (index != -1) {
        _comments[index] = comment.copyWith(
          isLiked: !comment.isLiked,
          likesCount: comment.isLiked ? comment.likesCount - 1 : comment.likesCount + 1,
        );
      }
    });
  }

  void _replyToComment(Comment comment) {
    _commentController.text = '@${comment.userName} ';
    _commentController.selection = TextSelection.fromPosition(
      TextPosition(offset: _commentController.text.length),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  List<Comment> _generateMockComments() {
    final now = DateTime.now();
    return [
      Comment(
        id: 'comment_1',
        postId: widget.post.id,
        userId: 'user_1',
        userName: 'Marie Claire',
        userAvatar: 'https://picsum.photos/100/100?random=1',
        content: 'Amazing work! Your cows look so healthy and well-cared for. 🐄',
        createdAt: now.subtract(const Duration(hours: 2)),
        likesCount: 5,
        isLiked: false,
        isVerified: true,
      ),
      Comment(
        id: 'comment_2',
        postId: widget.post.id,
        userId: 'user_2',
        userName: 'Jean Claude',
        userAvatar: 'https://picsum.photos/100/100?random=2',
        content: 'What breed are these cows? They look like excellent milk producers!',
        createdAt: now.subtract(const Duration(hours: 4)),
        likesCount: 3,
        isLiked: true,
        isVerified: false,
      ),
      Comment(
        id: 'comment_3',
        postId: widget.post.id,
        userId: 'user_3',
        userName: 'Grace',
        userAvatar: 'https://picsum.photos/100/100?random=3',
        content: 'Great to see young farmers learning the trade! 👨‍👩‍👧‍👦',
        createdAt: now.subtract(const Duration(hours: 6)),
        likesCount: 8,
        isLiked: false,
        isVerified: true,
      ),
      Comment(
        id: 'comment_4',
        postId: widget.post.id,
        userId: 'user_4',
        userName: 'Paul',
        userAvatar: 'https://picsum.photos/100/100?random=4',
        content: 'Do you have any tips for new dairy farmers? I\'m just starting out.',
        createdAt: now.subtract(const Duration(hours: 8)),
        likesCount: 2,
        isLiked: false,
        isVerified: false,
      ),
    ];
  }
}
