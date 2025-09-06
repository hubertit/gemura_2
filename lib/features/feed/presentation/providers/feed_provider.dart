import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/post.dart';

class FeedState {
  final List<Post> nearMePosts;
  final List<Post> followingPosts;
  final bool isLoading;
  final String? error;
  final bool hasMoreNearMePosts;
  final bool hasMoreFollowingPosts;
  final String currentFeedType;

  const FeedState({
    this.nearMePosts = const [],
    this.followingPosts = const [],
    this.isLoading = false,
    this.error,
    this.hasMoreNearMePosts = true,
    this.hasMoreFollowingPosts = true,
    this.currentFeedType = 'near_me',
  });

  List<Post> get posts {
    return currentFeedType == 'near_me' ? nearMePosts : followingPosts;
  }

  bool get hasMorePosts {
    return currentFeedType == 'near_me' ? hasMoreNearMePosts : hasMoreFollowingPosts;
  }

  FeedState copyWith({
    List<Post>? nearMePosts,
    List<Post>? followingPosts,
    bool? isLoading,
    String? error,
    bool? hasMoreNearMePosts,
    bool? hasMoreFollowingPosts,
    String? currentFeedType,
  }) {
    return FeedState(
      nearMePosts: nearMePosts ?? this.nearMePosts,
      followingPosts: followingPosts ?? this.followingPosts,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      hasMoreNearMePosts: hasMoreNearMePosts ?? this.hasMoreNearMePosts,
      hasMoreFollowingPosts: hasMoreFollowingPosts ?? this.hasMoreFollowingPosts,
      currentFeedType: currentFeedType ?? this.currentFeedType,
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
          nearMePosts: _generateMockPosts('near_me'),
          followingPosts: _generateMockPosts('following'),
        );
      }
    });
  }

  Future<void> refreshFeed([String? feedType]) async {
    final currentFeedType = feedType ?? state.currentFeedType;
    state = state.copyWith(isLoading: true, error: null, currentFeedType: currentFeedType);
    
    // Simulate refresh
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      if (currentFeedType == 'near_me') {
        state = state.copyWith(
          isLoading: false,
          nearMePosts: _generateMockPosts('near_me'),
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          followingPosts: _generateMockPosts('following'),
        );
      }
    }
  }

  Future<void> loadMorePosts() async {
    if (!state.hasMorePosts || state.isLoading) return;
    
    state = state.copyWith(isLoading: true);
    
    // Simulate loading more posts
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      final newPosts = _generateMockPosts(state.currentFeedType);
      if (state.currentFeedType == 'near_me') {
        state = state.copyWith(
          isLoading: false,
          nearMePosts: [...state.nearMePosts, ...newPosts],
          hasMoreNearMePosts: state.nearMePosts.length < 50,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          followingPosts: [...state.followingPosts, ...newPosts],
          hasMoreFollowingPosts: state.followingPosts.length < 50,
        );
      }
    }
  }

  void likePost(String postId) {
    if (state.currentFeedType == 'near_me') {
      final updatedPosts = state.nearMePosts.map((post) {
        if (post.id == postId) {
          return post.copyWith(
            isLiked: !post.isLiked,
            likesCount: post.isLiked ? post.likesCount - 1 : post.likesCount + 1,
          );
        }
        return post;
      }).toList();
      
      state = state.copyWith(nearMePosts: updatedPosts);
    } else {
      final updatedPosts = state.followingPosts.map((post) {
        if (post.id == postId) {
          return post.copyWith(
            isLiked: !post.isLiked,
            likesCount: post.isLiked ? post.likesCount - 1 : post.likesCount + 1,
          );
        }
        return post;
      }).toList();
      
      state = state.copyWith(followingPosts: updatedPosts);
    }
  }

  void sharePost(String postId) {
    if (state.currentFeedType == 'near_me') {
      final updatedPosts = state.nearMePosts.map((post) {
        if (post.id == postId) {
          return post.copyWith(sharesCount: post.sharesCount + 1);
        }
        return post;
      }).toList();
      
      state = state.copyWith(nearMePosts: updatedPosts);
    } else {
      final updatedPosts = state.followingPosts.map((post) {
        if (post.id == postId) {
          return post.copyWith(sharesCount: post.sharesCount + 1);
        }
        return post;
      }).toList();
      
      state = state.copyWith(followingPosts: updatedPosts);
    }
  }

  void addComment(String postId, String content) {
    if (state.currentFeedType == 'near_me') {
      final updatedPosts = state.nearMePosts.map((post) {
        if (post.id == postId) {
          return post.copyWith(commentsCount: post.commentsCount + 1);
        }
        return post;
      }).toList();
      
      state = state.copyWith(nearMePosts: updatedPosts);
    } else {
      final updatedPosts = state.followingPosts.map((post) {
        if (post.id == postId) {
          return post.copyWith(commentsCount: post.commentsCount + 1);
        }
        return post;
      }).toList();
      
      state = state.copyWith(followingPosts: updatedPosts);
    }
  }


  List<Post> _generateMockPosts(String feedType) {
    final now = DateTime.now();
    return List.generate(10, (index) {
      return Post(
        id: '${feedType}_post_${DateTime.now().millisecondsSinceEpoch}_$index',
        userId: 'user_$index',
        userName: _getRandomName(index),
        userAvatar: 'https://picsum.photos/100/100?random=$index',
        content: _getRandomContent(index, feedType),
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

  String _getRandomContent(int index, String feedType) {
    if (feedType == 'near_me') {
      final nearMeContents = [
        'Local dairy farm in your area - morning milking session 🐄 #LocalFarm #NearMe',
        'Neighbor\'s new calves born today! 🐮 #LocalNews #CommunityFarm',
        'Fresh grass feeding at nearby farm 🌱 #LocalFarming #Community',
        'Vet check-up at local dairy cooperative 🩺 #LocalVet #CommunityHealth',
        'New barn construction in the neighborhood 🏗️ #LocalConstruction #FarmExpansion',
        'Hay harvest season in our area 🌾 #LocalHarvest #SeasonalWork',
        'Local farming family teaching next generation 👨‍👩‍👧‍👦 #LocalFamily #Community',
        'Record milk production at nearby farm 📈 #LocalSuccess #CommunityPride',
        'Organic farming practices in our region 🌿 #LocalOrganic #Community',
        'Local dairy farming workshop this weekend 📚 #LocalEducation #Community',
      ];
      return nearMeContents[index % nearMeContents.length];
    } else {
      final followingContents = [
        'Following: Morning milking session with my beautiful cows 🐄 #DairyFarming #Following',
        'Following: New calves born today! Welcome to the farm little ones 🐮 #NewCalves #Following',
        'Following: Fresh grass feeding time for the herd 🌱 #GrassFeeding #Following',
        'Following: Veterinary check-up day - all cows are healthy! 🩺 #VetCheck #Following',
        'Following: Building a new barn for the growing herd 🏗️ #BarnConstruction #Following',
        'Following: Harvesting hay for winter feed 🌾 #HayHarvest #Following',
        'Following: Teaching my children about dairy farming 👨‍👩‍👧‍👦 #FamilyFarm #Following',
        'Following: Record milk production this month! 📈 #MilkProduction #Following',
        'Following: Organic farming practices for better milk quality 🌿 #OrganicFarming #Following',
        'Following: Community dairy farming workshop today 📚 #DairyEducation #Following',
      ];
      return followingContents[index % followingContents.length];
    }
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
