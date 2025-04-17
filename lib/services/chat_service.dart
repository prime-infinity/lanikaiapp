// lib/services/chat_service.dart
import '../models/chat.dart';
import '../models/message.dart';
import '../models/user.dart';

class ChatService {
  // Dummy users
  final List<User> _users = [
    User(
        id: "2",
        name: "John Doe",
        email: "john@example.com",
        avatar: "https://placehold.co/150"),
    User(
        id: "3",
        name: "Jane Smith",
        email: "jane@example.com",
        avatar: "https://placehold.co/150"),
    User(
        id: "4",
        name: "Mike Johnson",
        email: "mike@example.com",
        avatar: "https://placehold.co/150"),
    User(
        id: "5",
        name: "Emily Davis",
        email: "emily@example.com",
        avatar: "https://placehold.co/150"),
  ];

  // Dummy messages for each chat
  final Map<String, List<Message>> _messages = {};

  ChatService() {
    // Initialize dummy messages
    _initDummyMessages();
  }

  void _initDummyMessages() {
    const currentUserId = "1"; // Andrew's ID

    for (final user in _users) {
      final chatId = "chat_${user.id}";
      _messages[chatId] = [
        Message(
          id: "${chatId}_1",
          senderId: user.id,
          receiverId: currentUserId,
          content: "Hey there!",
          timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
        ),
        Message(
          id: "${chatId}_2",
          senderId: currentUserId,
          receiverId: user.id,
          content: "Hi! How are you?",
          timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
        ),
        Message(
          id: "${chatId}_3",
          senderId: user.id,
          receiverId: currentUserId,
          content: "I'm good, thanks! What about you?",
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];
    }
  }

  List<Chat> getChats() {
    const currentUserId = "1"; // Andrew's ID
    final List<Chat> chats = [];

    for (final user in _users) {
      final chatId = "chat_${user.id}";
      final messages = _messages[chatId] ?? [];

      if (messages.isNotEmpty) {
        chats.add(
          Chat(
            id: chatId,
            user: user,
            lastMessage: messages.last,
            unreadCount: messages
                .where((m) =>
                    m.senderId != currentUserId &&
                    m.timestamp.isAfter(
                        DateTime.now().subtract(const Duration(hours: 24))))
                .length,
          ),
        );
      }
    }

    return chats;
  }

  List<Message> getChatMessages(String chatId) {
    return _messages[chatId] ?? [];
  }

  void sendMessage(String chatId, String content) {
    const currentUserId = "1"; // Andrew's ID
    final receiverId = chatId.split('_')[1];

    final message = Message(
      id: "${chatId}_${DateTime.now().millisecondsSinceEpoch}",
      senderId: currentUserId,
      receiverId: receiverId,
      content: content,
      timestamp: DateTime.now(),
    );

    if (_messages.containsKey(chatId)) {
      _messages[chatId]!.add(message);
    } else {
      _messages[chatId] = [message];
    }
  }
}
