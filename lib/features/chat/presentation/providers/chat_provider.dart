import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/chat_room.dart';
import '../../../../shared/models/wallet.dart';

class ChatNotifier extends StateNotifier<List<ChatRoom>> {
  ChatNotifier() : super([]) {
    _loadMockData();
  }

  // Messages storage
  final Map<String, List<ChatMessage>> _messages = {};

  void _loadMockData() {
    // Mock joint wallets for chat rooms
    final jointWallets = [
      Wallet(
        id: 'WALLET-JOINT-1',
        name: 'Family Savings',
        balance: 750000,
        currency: 'RWF',
        type: 'joint',
        status: 'active',
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
        owners: ['John Doe', 'Jane Doe', 'Junior Doe'],
        isDefault: false,
        description: 'Family emergency fund and savings',
      ),
      Wallet(
        id: 'WALLET-JOINT-2',
        name: 'Business Partners',
        balance: 2500000,
        currency: 'RWF',
        type: 'joint',
        status: 'active',
        createdAt: DateTime.now().subtract(const Duration(days: 120)),
        owners: ['John Doe', 'Alice Smith', 'Bob Johnson'],
        isDefault: false,
        description: 'Business operations and investments',
      ),
      Wallet(
        id: 'WALLET-JOINT-3',
        name: 'Trip Fund',
        balance: 450000,
        currency: 'RWF',
        type: 'joint',
        status: 'active',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        owners: ['John Doe', 'Sarah Wilson', 'Mike Brown'],
        isDefault: false,
        description: 'Vacation and travel expenses',
      ),
    ];

    state = [
      ChatRoom(
        id: 'CHAT-1',
        name: 'Family Savings Group',
        description: 'Group chat for Family Savings wallet',
        walletId: 'WALLET-JOINT-1',
        wallet: jointWallets[0],
        members: [
          ChatMember(
            id: 'USER-1',
            name: 'John Doe',
            email: 'john@example.com',
            avatar: 'assets/images/logo.png',
            role: 'owner',
            joinedAt: DateTime.now().subtract(const Duration(days: 90)),
            isOnline: true,
          ),
          ChatMember(
            id: 'USER-2',
            name: 'Jane Doe',
            email: 'jane@example.com',
            avatar: 'assets/images/logo.png',
            role: 'admin',
            joinedAt: DateTime.now().subtract(const Duration(days: 85)),
            isOnline: false,
          ),
          ChatMember(
            id: 'USER-3',
            name: 'Junior Doe',
            email: 'junior@example.com',
            avatar: 'assets/images/logo.png',
            role: 'member',
            joinedAt: DateTime.now().subtract(const Duration(days: 80)),
            isOnline: true,
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
        lastMessageAt: DateTime.now().subtract(const Duration(minutes: 15)),
        lastMessageContent: 'I just transferred 50,000 Frw to the savings',
        lastMessageSender: 'Jane Doe',
        unreadCount: 2,
      ),
      ChatRoom(
        id: 'CHAT-2',
        name: 'Business Partners Group',
        description: 'Group chat for Business Partners wallet',
        walletId: 'WALLET-JOINT-2',
        wallet: jointWallets[1],
        members: [
          ChatMember(
            id: 'USER-1',
            name: 'John Doe',
            email: 'john@example.com',
            avatar: 'assets/images/logo.png',
            role: 'owner',
            joinedAt: DateTime.now().subtract(const Duration(days: 120)),
            isOnline: true,
          ),
          ChatMember(
            id: 'USER-4',
            name: 'Alice Smith',
            email: 'alice@example.com',
            avatar: 'assets/images/logo.png',
            role: 'admin',
            joinedAt: DateTime.now().subtract(const Duration(days: 115)),
            isOnline: true,
          ),
          ChatMember(
            id: 'USER-5',
            name: 'Bob Johnson',
            email: 'bob@example.com',
            avatar: 'assets/images/logo.png',
            role: 'member',
            joinedAt: DateTime.now().subtract(const Duration(days: 110)),
            isOnline: false,
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 120)),
        lastMessageAt: DateTime.now().subtract(const Duration(hours: 2)),
        lastMessageContent: 'Meeting scheduled for tomorrow at 10 AM',
        lastMessageSender: 'Alice Smith',
        unreadCount: 0,
      ),
      ChatRoom(
        id: 'CHAT-3',
        name: 'Trip Fund Group',
        description: 'Group chat for Trip Fund wallet',
        walletId: 'WALLET-JOINT-3',
        wallet: jointWallets[2],
        members: [
          ChatMember(
            id: 'USER-1',
            name: 'John Doe',
            email: 'john@example.com',
            avatar: 'assets/images/logo.png',
            role: 'owner',
            joinedAt: DateTime.now().subtract(const Duration(days: 30)),
            isOnline: true,
          ),
          ChatMember(
            id: 'USER-6',
            name: 'Sarah Wilson',
            email: 'sarah@example.com',
            avatar: 'assets/images/logo.png',
            role: 'admin',
            joinedAt: DateTime.now().subtract(const Duration(days: 28)),
            isOnline: false,
          ),
          ChatMember(
            id: 'USER-7',
            name: 'Mike Brown',
            email: 'mike@example.com',
            avatar: 'assets/images/logo.png',
            role: 'member',
            joinedAt: DateTime.now().subtract(const Duration(days: 25)),
            isOnline: true,
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        lastMessageAt: DateTime.now().subtract(const Duration(days: 1)),
        lastMessageContent: 'Flight tickets booked for next month',
        lastMessageSender: 'Sarah Wilson',
        unreadCount: 5,
      ),
    ];

    _initializeMessages();
  }

  void _initializeMessages() {
    // Family Savings Group Messages
    _messages['CHAT-1'] = [
      ChatMessage(
        id: 'MSG-1-1',
        chatId: 'CHAT-1',
        senderId: 'USER-2',
        senderName: 'Jane Doe',
        senderAvatar: 'assets/images/logo.png',
        content: 'I just transferred 50,000 Frw to the savings',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: 'MSG-1-2',
        chatId: 'CHAT-1',
        senderId: 'USER-1',
        senderName: 'John Doe',
        senderAvatar: 'assets/images/logo.png',
        content: 'Great! We\'re making good progress on our savings goal',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: 'MSG-1-3',
        chatId: 'CHAT-1',
        senderId: 'USER-3',
        senderName: 'Junior Doe',
        senderAvatar: 'assets/images/logo.png',
        content: 'Can we use some of the savings for my school trip?',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        status: MessageStatus.delivered,
      ),
    ];

    // Business Partners Group Messages
    _messages['CHAT-2'] = [
      ChatMessage(
        id: 'MSG-2-1',
        chatId: 'CHAT-2',
        senderId: 'USER-4',
        senderName: 'Alice Smith',
        senderAvatar: 'assets/images/logo.png',
        content: 'Meeting scheduled for tomorrow at 10 AM',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: 'MSG-2-2',
        chatId: 'CHAT-2',
        senderId: 'USER-1',
        senderName: 'John Doe',
        senderAvatar: 'assets/images/logo.png',
        content: 'Perfect, I\'ll prepare the quarterly report',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: 'MSG-2-3',
        chatId: 'CHAT-2',
        senderId: 'USER-5',
        senderName: 'Bob Johnson',
        senderAvatar: 'assets/images/logo.png',
        content: 'I\'ll bring the financial projections',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        status: MessageStatus.delivered,
      ),
    ];

    // Trip Fund Group Messages
    _messages['CHAT-3'] = [
      ChatMessage(
        id: 'MSG-3-1',
        chatId: 'CHAT-3',
        senderId: 'USER-6',
        senderName: 'Sarah Wilson',
        senderAvatar: 'assets/images/logo.png',
        content: 'Flight tickets booked for next month',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: 'MSG-3-2',
        chatId: 'CHAT-3',
        senderId: 'USER-7',
        senderName: 'Mike Brown',
        senderAvatar: 'assets/images/logo.png',
        content: 'Awesome! Which hotel did you book?',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(hours: 12)),
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: 'MSG-3-3',
        chatId: 'CHAT-3',
        senderId: 'USER-1',
        senderName: 'John Doe',
        senderAvatar: 'assets/images/logo.png',
        content: 'I\'ll transfer my share for the hotel booking',
        type: MessageType.payment,
        timestamp: DateTime.now().subtract(const Duration(hours: 6)),
        status: MessageStatus.read,
      ),
    ];
  }

  // Chat Room Management
  void addChatRoom(ChatRoom chatRoom) {
    state = [...state, chatRoom];
  }

  void updateChatRoom(ChatRoom chatRoom) {
    state = state.map((room) => room.id == chatRoom.id ? chatRoom : room).toList();
  }

  void deleteChatRoom(String chatRoomId) {
    state = state.where((room) => room.id != chatRoomId).toList();
  }

  // Message Management
  void addMessage(ChatMessage message) {
    if (!_messages.containsKey(message.chatId)) {
      _messages[message.chatId] = [];
    }
    _messages[message.chatId]!.add(message);
    
    // Update chat room with last message info
    final chatRoom = state.firstWhere((room) => room.id == message.chatId);
    final updatedRoom = chatRoom.copyWith(
      lastMessageAt: message.timestamp,
      lastMessageContent: message.content,
      lastMessageSender: message.senderName,
      unreadCount: chatRoom.unreadCount + 1,
    );
    updateChatRoom(updatedRoom);
  }

  void updateMessage(ChatMessage message) {
    if (_messages.containsKey(message.chatId)) {
      _messages[message.chatId] = _messages[message.chatId]!
          .map((m) => m.id == message.id ? message : m)
          .toList();
    }
  }

  List<ChatMessage> getMessagesForChat(String chatId) {
    return _messages[chatId] ?? [];
  }

  void markChatAsRead(String chatId) {
    final chatRoom = state.firstWhere((room) => room.id == chatId);
    final updatedRoom = chatRoom.copyWith(unreadCount: 0);
    updateChatRoom(updatedRoom);
  }

  // Computed Lists
  List<ChatRoom> get activeChats => 
      state.where((room) => room.isActive).toList();

  List<ChatRoom> get chatsWithUnreadMessages => 
      state.where((room) => room.unreadCount > 0).toList();

  List<ChatRoom> getChatsByWalletId(String walletId) {
    return state.where((room) => room.walletId == walletId).toList();
  }

  // Statistics
  int get totalUnreadMessages {
    return state.fold(0, (sum, room) => sum + room.unreadCount);
  }

  Map<String, dynamic> get chatStats {
    return {
      'totalChats': state.length,
      'activeChats': activeChats.length,
      'chatsWithUnread': chatsWithUnreadMessages.length,
      'totalUnreadMessages': totalUnreadMessages,
    };
  }
}

// Providers
final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatRoom>>((ref) {
  return ChatNotifier();
});

final activeChatsProvider = Provider<List<ChatRoom>>((ref) {
  final notifier = ref.watch(chatProvider.notifier);
  return notifier.activeChats;
});

final chatsWithUnreadMessagesProvider = Provider<List<ChatRoom>>((ref) {
  final notifier = ref.watch(chatProvider.notifier);
  return notifier.chatsWithUnreadMessages;
});

final chatStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final notifier = ref.watch(chatProvider.notifier);
  return notifier.chatStats;
});

final chatMessagesProvider = Provider.family<List<ChatMessage>, String>((ref, chatId) {
  final notifier = ref.watch(chatProvider.notifier);
  return notifier.getMessagesForChat(chatId);
}); 