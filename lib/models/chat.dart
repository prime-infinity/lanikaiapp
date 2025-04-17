// lib/models/chat.dart
import 'package:lanikai/models/message.dart';
import 'package:lanikai/models/user.dart';

class Chat {
  final String id;
  final User user;
  final Message lastMessage;
  final int unreadCount;

  Chat({
    required this.id,
    required this.user,
    required this.lastMessage,
    this.unreadCount = 0,
  });
}
