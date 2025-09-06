import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/post.dart';

class FeedState {
  final List<Post> posts;
  final bool isLoading;
  final String? error;
  final bool hasMorePosts;

  const FeedState({
    this.posts = const [],
    this.isLoading = false,
    this.error,
    this.hasMorePosts = true,
  });

  FeedState copyWith({
    List<Post>? posts,
    bool? isLoading,
    String? error,
    bool? hasMorePosts,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      hasMorePosts: hasMorePosts ?? this.hasMorePosts,
    );
  }
}

class FeedNotifier extends StateNotifier<FeedState> {
  FeedNotifier() : super(const FeedState()) {
    _loadInitialData();
  }

  void _loadInitialData() {
    state = state.copyWith(isLoading: true);
    
    // Simulate loading data
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          posts: _generateMockPosts(),
        );
      }
    });
  }

  Future<void> refreshFeed() async {
    state = state.copyWith(isLoading: true, error: null);
    
    // Simulate refresh
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      state = state.copyWith(
        isLoading: false,
        posts: _generateMockPosts(),
      );
    }
  }

  Future<void> loadMorePosts() async {
    if (!state.hasMorePosts || state.isLoading) return;
    
    state = state.copyWith(isLoading: true);
    
    // Simulate loading more posts
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      final newPosts = _generateMockPosts();
      state = state.copyWith(
        isLoading: false,
        posts: [...state.posts, ...newPosts],
        hasMorePosts: state.posts.length < 50, // Limit to 50 posts
      );
    }
  }

  void likePost(String postId) {
    final updatedPosts = state.posts.map((post) {
      if (post.id == postId) {
        return post.copyWith(
          isLiked: !post.isLiked,
          likesCount: post.isLiked ? post.likesCount - 1 : post.likesCount + 1,
        );
      }
      return post;
    }).toList();
    
    state = state.copyWith(posts: updatedPosts);
  }

  void sharePost(String postId) {
    final updatedPosts = state.posts.map((post) {
      if (post.id == postId) {
        return post.copyWith(sharesCount: post.sharesCount + 1);
      }
      return post;
    }).toList();
    
    state = state.copyWith(posts: updatedPosts);
  }

  void addComment(String postId, String content) {
    final updatedPosts = state.posts.map((post) {
      if (post.id == postId) {
        return post.copyWith(commentsCount: post.commentsCount + 1);
      }
      return post;
    }).toList();
    
    state = state.copyWith(posts: updatedPosts);
  }


  List<Post> _generateMockPosts() {
    final now = DateTime.now();
    return List.generate(10, (index) {
      return Post(
        id: 'post_${DateTime.now().millisecondsSinceEpoch}_$index',
        userId: 'user_$index',
        userName: _getRandomName(index),
        userAvatar: 'https://picsum.photos/100/100?random=$index',
        content: _getRandomContent(index),
        imageUrls: _getRandomImages(index),
        createdAt: now.subtract(Duration(hours: index)),
        updatedAt: now.subtract(Duration(hours: index)),
        likesCount: (index * 7) % 100 + 10,
        commentsCount: (index * 3) % 50 + 5,
        sharesCount: (index * 2) % 20 + 2,
        isLiked: index % 3 == 0,
        hashtags: _getRandomHashtags(index),
        location: index % 4 == 0 ? _getRandomLocation(index) : null,
        isVerified: index % 5 == 0,
      );
    });
  }


  String _getRandomName(int index) {
    final names = [
      'Jean Claude', 'Marie Claire', 'Paul', 'Grace', 'David',
      'Sarah', 'Peter', 'Ruth', 'John', 'Esther', 'James', 'Hope'
    ];
    return names[index % names.length];
  }

  String _getRandomContent(int index) {
    final contents = [
      'Morning milking session with my beautiful cows 🐄 #DairyFarming #MorningMilking',
      'New calves born today! Welcome to the farm little ones 🐮 #NewCalves #FarmLife',
      'Fresh grass feeding time for the herd 🌱 #GrassFeeding #HealthyCows',
      'Veterinary check-up day - all cows are healthy! 🩺 #VetCheck #HealthyHerd',
      'Building a new barn for the growing herd 🏗️ #BarnConstruction #FarmExpansion',
      'Harvesting hay for winter feed 🌾 #HayHarvest #WinterPreparation',
      'Teaching my children about dairy farming 👨‍👩‍👧‍👦 #FamilyFarm #NextGeneration',
      'Record milk production this month! 📈 #MilkProduction #FarmSuccess',
      'Organic farming practices for better milk quality 🌿 #OrganicFarming #QualityMilk',
      'Community dairy farming workshop today 📚 #DairyEducation #CommunityLearning',
    ];
    return contents[index % contents.length];
  }

  List<String> _getRandomImages(int index) {
    if (index % 3 == 0) {
      return ['https://picsum.photos/400/400?random=$index'];
    } else if (index % 3 == 1) {
      return [
        'https://picsum.photos/400/400?random=$index',
        'https://picsum.photos/400/400?random=${index + 1}',
      ];
    } else {
      return [
        'https://picsum.photos/400/400?random=$index',
        'https://picsum.photos/400/400?random=${index + 1}',
        'https://picsum.photos/400/400?random=${index + 2}',
      ];
    }
  }

  List<String> _getRandomHashtags(int index) {
    final hashtags = [
      ['#DairyFarming', '#MorningMilking'],
      ['#NewCalves', '#FarmLife'],
      ['#GrassFeeding', '#HealthyCows'],
      ['#VetCheck', '#HealthyHerd'],
      ['#BarnConstruction', '#FarmExpansion'],
      ['#HayHarvest', '#WinterPreparation'],
      ['#FamilyFarm', '#NextGeneration'],
      ['#MilkProduction', '#FarmSuccess'],
      ['#OrganicFarming', '#QualityMilk'],
      ['#DairyEducation', '#CommunityLearning'],
    ];
    return hashtags[index % hashtags.length];
  }

  String _getRandomLocation(int index) {
    final locations = [
      'Kigali Dairy Farm, Rwanda',
      'Nyarugenge Cattle Ranch, Kigali',
      'Kacyiru Dairy Cooperative, Kigali',
      'Kimisagara Farm, Kigali',
      'Nyamirambo Livestock Farm, Kigali',
      'Rwamagana Dairy Farm, Eastern Province',
      'Musanze Cattle Farm, Northern Province',
      'Huye Dairy Cooperative, Southern Province',
      'Rubavu Livestock Farm, Western Province',
      'Gicumbi Dairy Farm, Northern Province',
    ];
    return locations[index % locations.length];
  }
}

final feedProvider = StateNotifierProvider<FeedNotifier, FeedState>((ref) {
  return FeedNotifier();
});
