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
    // Mock joint ikofi for chat rooms
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
      Wallet(
        id: 'WALLET-JOINT-4',
        name: 'MCC Project Fund',
        balance: 1800000,
        currency: 'RWF',
        type: 'joint',
        status: 'active',
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
        owners: ['John Doe', 'Emma Davis', 'Tom Wilson', 'Lisa Chen'],
        isDefault: false,
        description: 'MCC development project funds',
      ),
      Wallet(
        id: 'WALLET-JOINT-5',
        name: 'RAB Investment',
        balance: 3200000,
        currency: 'RWF',
        type: 'joint',
        status: 'active',
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        owners: ['John Doe', 'David Kim', 'Maria Garcia', 'Alex Thompson'],
        isDefault: false,
        description: 'RAB investment portfolio',
      ),
      Wallet(
        id: 'WALLET-JOINT-6',
        name: 'Friends Weekend',
        balance: 280000,
        currency: 'RWF',
        type: 'joint',
        status: 'active',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        owners: ['John Doe', 'Chris Lee', 'Anna Park', 'Sam Johnson'],
        isDefault: false,
        description: 'Weekend getaway fund',
      ),
      Wallet(
        id: 'WALLET-JOINT-7',
        name: 'Study Group',
        balance: 150000,
        currency: 'RWF',
        type: 'joint',
        status: 'active',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        owners: ['John Doe', 'Sarah Miller', 'James Wilson', 'Emma Brown'],
        isDefault: false,
        description: 'Study materials and resources',
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
      ChatRoom(
        id: 'CHAT-4',
        name: 'MCC Development Team',
        description: 'Group chat for MCC Project Fund wallet',
        walletId: 'WALLET-JOINT-4',
        wallet: jointWallets[3],
        members: [
          ChatMember(
            id: 'USER-1',
            name: 'John Doe',
            email: 'john@example.com',
            avatar: 'assets/images/logo.png',
            role: 'owner',
            joinedAt: DateTime.now().subtract(const Duration(days: 45)),
            isOnline: true,
          ),
          ChatMember(
            id: 'USER-8',
            name: 'Emma Davis',
            email: 'emma@example.com',
            avatar: 'assets/images/logo.png',
            role: 'admin',
            joinedAt: DateTime.now().subtract(const Duration(days: 44)),
            isOnline: true,
          ),
          ChatMember(
            id: 'USER-9',
            name: 'Tom Wilson',
            email: 'tom@example.com',
            avatar: 'assets/images/logo.png',
            role: 'member',
            joinedAt: DateTime.now().subtract(const Duration(days: 43)),
            isOnline: false,
          ),
          ChatMember(
            id: 'USER-10',
            name: 'Lisa Chen',
            email: 'lisa@example.com',
            avatar: 'assets/images/logo.png',
            role: 'member',
            joinedAt: DateTime.now().subtract(const Duration(days: 42)),
            isOnline: true,
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
        lastMessageAt: DateTime.now().subtract(const Duration(minutes: 30)),
        lastMessageContent: 'New feature deployment completed successfully',
        lastMessageSender: 'Emma Davis',
        unreadCount: 1,
      ),
      ChatRoom(
        id: 'CHAT-5',
        name: 'RAB Investment Group',
        description: 'Group chat for RAB Investment wallet',
        walletId: 'WALLET-JOINT-5',
        wallet: jointWallets[4],
        members: [
          ChatMember(
            id: 'USER-1',
            name: 'John Doe',
            email: 'john@example.com',
            avatar: 'assets/images/logo.png',
            role: 'owner',
            joinedAt: DateTime.now().subtract(const Duration(days: 60)),
            isOnline: true,
          ),
          ChatMember(
            id: 'USER-11',
            name: 'David Kim',
            email: 'david@example.com',
            avatar: 'assets/images/logo.png',
            role: 'admin',
            joinedAt: DateTime.now().subtract(const Duration(days: 59)),
            isOnline: false,
          ),
          ChatMember(
            id: 'USER-12',
            name: 'Maria Garcia',
            email: 'maria@example.com',
            avatar: 'assets/images/logo.png',
            role: 'member',
            joinedAt: DateTime.now().subtract(const Duration(days: 58)),
            isOnline: true,
          ),
          ChatMember(
            id: 'USER-13',
            name: 'Alex Thompson',
            email: 'alex@example.com',
            avatar: 'assets/images/logo.png',
            role: 'member',
            joinedAt: DateTime.now().subtract(const Duration(days: 57)),
            isOnline: false,
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        lastMessageAt: DateTime.now().subtract(const Duration(hours: 4)),
        lastMessageContent: 'Portfolio performance report is ready',
        lastMessageSender: 'David Kim',
        unreadCount: 3,
      ),
      ChatRoom(
        id: 'CHAT-6',
        name: 'Friends Weekend Crew',
        description: 'Group chat for Friends Weekend wallet',
        walletId: 'WALLET-JOINT-6',
        wallet: jointWallets[5],
        members: [
          ChatMember(
            id: 'USER-1',
            name: 'John Doe',
            email: 'john@example.com',
            avatar: 'assets/images/logo.png',
            role: 'owner',
            joinedAt: DateTime.now().subtract(const Duration(days: 15)),
            isOnline: true,
          ),
          ChatMember(
            id: 'USER-14',
            name: 'Chris Lee',
            email: 'chris@example.com',
            avatar: 'assets/images/logo.png',
            role: 'admin',
            joinedAt: DateTime.now().subtract(const Duration(days: 14)),
            isOnline: true,
          ),
          ChatMember(
            id: 'USER-15',
            name: 'Anna Park',
            email: 'anna@example.com',
            avatar: 'assets/images/logo.png',
            role: 'member',
            joinedAt: DateTime.now().subtract(const Duration(days: 13)),
            isOnline: false,
          ),
          ChatMember(
            id: 'USER-16',
            name: 'Sam Johnson',
            email: 'sam@example.com',
            avatar: 'assets/images/logo.png',
            role: 'member',
            joinedAt: DateTime.now().subtract(const Duration(days: 12)),
            isOnline: true,
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        lastMessageAt: DateTime.now().subtract(const Duration(minutes: 5)),
        lastMessageContent: 'Who\'s bringing snacks for the trip?',
        lastMessageSender: 'Anna Park',
        unreadCount: 0,
      ),
      ChatRoom(
        id: 'CHAT-7',
        name: 'Study Group Team',
        description: 'Group chat for Study Group wallet',
        walletId: 'WALLET-JOINT-7',
        wallet: jointWallets[6],
        members: [
          ChatMember(
            id: 'USER-1',
            name: 'John Doe',
            email: 'john@example.com',
            avatar: 'assets/images/logo.png',
            role: 'owner',
            joinedAt: DateTime.now().subtract(const Duration(days: 20)),
            isOnline: true,
          ),
          ChatMember(
            id: 'USER-17',
            name: 'Sarah Miller',
            email: 'sarah@example.com',
            avatar: 'assets/images/logo.png',
            role: 'admin',
            joinedAt: DateTime.now().subtract(const Duration(days: 19)),
            isOnline: false,
          ),
          ChatMember(
            id: 'USER-18',
            name: 'James Wilson',
            email: 'james@example.com',
            avatar: 'assets/images/logo.png',
            role: 'member',
            joinedAt: DateTime.now().subtract(const Duration(days: 18)),
            isOnline: true,
          ),
          ChatMember(
            id: 'USER-19',
            name: 'Emma Brown',
            email: 'emma.b@example.com',
            avatar: 'assets/images/logo.png',
            role: 'member',
            joinedAt: DateTime.now().subtract(const Duration(days: 17)),
            isOnline: false,
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        lastMessageAt: DateTime.now().subtract(const Duration(hours: 1)),
        lastMessageContent: 'Study session tomorrow at 2 PM',
        lastMessageSender: 'Sarah Miller',
        unreadCount: 2,
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

    // MCC Development Team Messages
    _messages['CHAT-4'] = [
      ChatMessage(
        id: 'MSG-4-1',
        chatId: 'CHAT-4',
        senderId: 'USER-8',
        senderName: 'Emma Davis',
        senderAvatar: 'assets/images/logo.png',
        content: 'New feature deployment completed successfully',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: 'MSG-4-2',
        chatId: 'CHAT-4',
        senderId: 'USER-1',
        senderName: 'John Doe',
        senderAvatar: 'assets/images/logo.png',
        content: 'Great work team! The new UI looks amazing',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: 'MSG-4-3',
        chatId: 'CHAT-4',
        senderId: 'USER-10',
        senderName: 'Lisa Chen',
        senderAvatar: 'assets/images/logo.png',
        content: 'Should we schedule a code review for tomorrow?',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
        status: MessageStatus.delivered,
      ),
    ];

    // RAB Investment Group Messages
    _messages['CHAT-5'] = [
      ChatMessage(
        id: 'MSG-5-1',
        chatId: 'CHAT-5',
        senderId: 'USER-11',
        senderName: 'David Kim',
        senderAvatar: 'assets/images/logo.png',
        content: 'Portfolio performance report is ready',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: 'MSG-5-2',
        chatId: 'CHAT-5',
        senderId: 'USER-12',
        senderName: 'Maria Garcia',
        senderAvatar: 'assets/images/logo.png',
        content: 'The returns look promising this quarter',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: 'MSG-5-3',
        chatId: 'CHAT-5',
        senderId: 'USER-1',
        senderName: 'John Doe',
        senderAvatar: 'assets/images/logo.png',
        content: 'Should we consider expanding to new markets?',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        status: MessageStatus.delivered,
      ),
    ];

    // Friends Weekend Crew Messages
    _messages['CHAT-6'] = [
      ChatMessage(
        id: 'MSG-6-1',
        chatId: 'CHAT-6',
        senderId: 'USER-15',
        senderName: 'Anna Park',
        senderAvatar: 'assets/images/logo.png',
        content: 'Who\'s bringing snacks for the trip?',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: 'MSG-6-2',
        chatId: 'CHAT-6',
        senderId: 'USER-14',
        senderName: 'Chris Lee',
        senderAvatar: 'assets/images/logo.png',
        content: 'I\'ll bring chips and drinks',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: 'MSG-6-3',
        chatId: 'CHAT-6',
        senderId: 'USER-16',
        senderName: 'Sam Johnson',
        senderAvatar: 'assets/images/logo.png',
        content: 'I\'ll handle the sandwiches',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
        status: MessageStatus.delivered,
      ),
    ];

    // Study Group Team Messages
    _messages['CHAT-7'] = [
      ChatMessage(
        id: 'MSG-7-1',
        chatId: 'CHAT-7',
        senderId: 'USER-17',
        senderName: 'Sarah Miller',
        senderAvatar: 'assets/images/logo.png',
        content: 'Study session tomorrow at 2 PM',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: 'MSG-7-2',
        chatId: 'CHAT-7',
        senderId: 'USER-18',
        senderName: 'James Wilson',
        senderAvatar: 'assets/images/logo.png',
        content: 'I\'ll bring the study materials',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: 'MSG-7-3',
        chatId: 'CHAT-7',
        senderId: 'USER-19',
        senderName: 'Emma Brown',
        senderAvatar: 'assets/images/logo.png',
        content: 'Can we focus on the math section?',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        status: MessageStatus.delivered,
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