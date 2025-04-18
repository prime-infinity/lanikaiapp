// lib/services/chat_service.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/chat.dart';
import '../models/message.dart';
// Import with alias to avoid conflict
import '../models/user.dart' as app_models;

class ChatService extends ChangeNotifier {
  final supabase = Supabase.instance.client;
  bool _isLoading = false;
  final Map<String, List<Message>> _messageCache = {};

  bool get isLoading => _isLoading;

  Future<List<Chat>> getChats(String currentUserId) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Get all conversations where current user is involved
      final messagesResponse = await supabase
          .from('messages')
          .select('id, sender_id, receiver_id, content, created_at, is_read')
          .or('sender_id.eq.$currentUserId,receiver_id.eq.$currentUserId')
          .order('created_at', ascending: false);

      // Extract unique user IDs from messages
      final Set<String> userIds = {};
      for (final message in messagesResponse) {
        if (message['sender_id'] != currentUserId) {
          userIds.add(message['sender_id']);
        }
        if (message['receiver_id'] != currentUserId) {
          userIds.add(message['receiver_id']);
        }
      }

      // Get user profiles
      final usersResponse = await supabase
          .from('profiles')
          .select()
          .inFilter('id', userIds.toList());

      final Map<String, app_models.User> usersMap = {};
      for (final user in usersResponse) {
        usersMap[user['id']] = app_models.User.fromJson(user);
      }

      // Create chats
      final List<Chat> chats = [];
      final Map<String, Message> lastMessages = {};
      final Map<String, int> unreadCounts = {};

      for (final message in messagesResponse) {
        final Message msg = Message.fromJson(message);
        final String otherUserId =
            msg.senderId == currentUserId ? msg.receiverId : msg.senderId;
        final String chatId = getChatId(currentUserId, otherUserId);

        // Track last message
        if (!lastMessages.containsKey(chatId)) {
          lastMessages[chatId] = msg;
        }

        // Count unread messages
        if (msg.receiverId == currentUserId && !msg.isRead) {
          unreadCounts[chatId] = (unreadCounts[chatId] ?? 0) + 1;
        }
      }

      // Create chat objects
      for (final String otherUserId in usersMap.keys) {
        if (otherUserId == currentUserId) continue;

        final chatId = getChatId(currentUserId, otherUserId);
        if (lastMessages.containsKey(chatId)) {
          chats.add(Chat(
            id: chatId,
            user: usersMap[otherUserId]!,
            lastMessage: lastMessages[
                chatId], // Chat constructor accepts nullable lastMessage
            unreadCount: unreadCounts[chatId] ?? 0,
          ));
        }
      }

      _isLoading = false;
      notifyListeners();
      return chats;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error getting chats: $e');
      return [];
    }
  }

  String getChatId(String userId1, String userId2) {
    // Ensure consistent chat ID regardless of sender/receiver order
    // Fix the cascade operator and sort/join issue
    final sortedIds = [userId1, userId2];
    sortedIds.sort();
    return sortedIds.join('_');
  }

  Future<List<Message>> getChatMessages(String chatId) async {
    try {
      // Extract user IDs from chat ID
      final userIds = chatId.split('_');
      if (userIds.length != 2) return [];

      final response = await supabase
          .from('messages')
          .select()
          .or('and(sender_id.eq.${userIds[0]},receiver_id.eq.${userIds[1]}),and(sender_id.eq.${userIds[1]},receiver_id.eq.${userIds[0]})')
          .order('created_at');

      final List<Message> messages =
          (response as List).map((msg) => Message.fromJson(msg)).toList();
      _messageCache[chatId] = messages;

      return messages;
    } catch (e) {
      debugPrint('Error getting chat messages: $e');
      return _messageCache[chatId] ?? [];
    }
  }

  Future<bool> sendMessage(
      String senderId, String receiverId, String content) async {
    try {
      final messageId = const Uuid().v4();
      final chatId = getChatId(senderId, receiverId);

      await supabase.from('messages').insert({
        'id': messageId,
        'sender_id': senderId,
        'receiver_id': receiverId,
        'content': content,
        'is_read': false,
      });

      // Update local cache
      final newMessage = Message(
        id: messageId,
        senderId: senderId,
        receiverId: receiverId,
        content: content,
        timestamp: DateTime.now(),
        isRead: false,
      );

      if (_messageCache.containsKey(chatId)) {
        _messageCache[chatId]!.add(newMessage);
      } else {
        _messageCache[chatId] = [newMessage];
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error sending message: $e');
      return false;
    }
  }

  Future<bool> markMessagesAsRead(String chatId, String currentUserId) async {
    try {
      // Extract the other user's ID from chat ID
      final userIds = chatId.split('_');
      final otherUserId = userIds[0] == currentUserId ? userIds[1] : userIds[0];

      await supabase
          .from('messages')
          .update({'is_read': true})
          .eq('sender_id', otherUserId)
          .eq('receiver_id', currentUserId)
          .eq('is_read', false);

      // Update local cache
      if (_messageCache.containsKey(chatId)) {
        for (final message in _messageCache[chatId]!) {
          if (message.receiverId == currentUserId && !message.isRead) {
            // Can't modify the is_read field directly due to immutability
            final index = _messageCache[chatId]!.indexOf(message);
            final updatedMessage = Message(
              id: message.id,
              senderId: message.senderId,
              receiverId: message.receiverId,
              content: message.content,
              timestamp: message.timestamp,
              isRead: true,
            );
            _messageCache[chatId]![index] = updatedMessage;
          }
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
      return false;
    }
  }
}
