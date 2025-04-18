// // lib/screens/chat_list_screen.dart
// import 'package:flutter/material.dart';
// import '../models/chat.dart';
// import '../services/chat_service.dart';
// import '../theme.dart';
// import 'chat_detail_screen.dart';

// class ChatListScreen extends StatefulWidget {
//   const ChatListScreen({super.key});

//   @override
//   ChatListScreenState createState() => ChatListScreenState();
// }

// class ChatListScreenState extends State<ChatListScreen> {
//   late final ChatService _chatService;
//   late List<Chat> _chats;

//   @override
//   void initState() {
//     super.initState();
//     _chatService = ChatService();
//     _chats = _chatService.getChats();
//   }

//   String _formatTimestamp(DateTime timestamp) {
//     final now = DateTime.now();
//     final today = DateTime(now.year, now.month, now.day);
//     final messageDate =
//         DateTime(timestamp.year, timestamp.month, timestamp.day);

//     if (messageDate == today) {
//       return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
//     } else if (messageDate == today.subtract(const Duration(days: 1))) {
//       return 'Yesterday';
//     } else {
//       return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Chats'),
//       ),
//       body: ListView.builder(
//         itemCount: _chats.length,
//         itemBuilder: (context, index) {
//           final chat = _chats[index];
//           return ListTile(
//             leading: CircleAvatar(
//               backgroundImage: NetworkImage(chat.user.avatar),
//             ),
//             title: Text(
//               chat.user.name,
//               style: const TextStyle(
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             subtitle: Text(
//               chat.lastMessage.content,
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//             ),
//             trailing: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: [
//                 Text(
//                   _formatTimestamp(chat.lastMessage.timestamp),
//                   style: const TextStyle(
//                     fontSize: 12,
//                     color: AppTheme.subtitleColor,
//                   ),
//                 ),
//                 if (chat.unreadCount > 0) ...[
//                   const SizedBox(height: 4),
//                   Container(
//                     padding: const EdgeInsets.all(6),
//                     decoration: const BoxDecoration(
//                       color: AppTheme.primaryColor,
//                       shape: BoxShape.circle,
//                     ),
//                     child: Text(
//                       chat.unreadCount.toString(),
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 10,
//                       ),
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//             onTap: () {
//               Navigator.of(context).push(
//                 MaterialPageRoute(
//                   builder: (_) => ChatDetailScreen(
//                     chatId: chat.id,
//                     user: chat.user,
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
