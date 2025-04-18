// lib/screens/friends_screen.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../models/contact.dart';
import '../services/contacts_service.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import 'chat_detail_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  FriendsScreenState createState() => FriendsScreenState();
}

class FriendsScreenState extends State<FriendsScreen> {
  bool _isInitialized = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initializeContacts();
      _isInitialized = true;
    }
  }

  Future<void> _initializeContacts() async {
    final contactsProvider =
        Provider.of<ContactsProvider>(context, listen: false);
    if (!contactsProvider.hasPermission) {
      final granted = await contactsProvider.requestContactsPermission();
      if (granted) {
        await contactsProvider.loadContacts();
      }
    } else if (contactsProvider.contacts.isEmpty) {
      await contactsProvider.loadContacts();
    }
  }

  Future<void> _refreshContacts() async {
    final contactsProvider =
        Provider.of<ContactsProvider>(context, listen: false);
    await contactsProvider.loadContacts();
  }

  void _startChat(BuildContext context, Contact contact, String currentUserId) {
    if (contact.user != null && currentUserId.isNotEmpty) {
      // Create chatId by sorting the two user IDs to ensure consistency
      final chatId = currentUserId.compareTo(contact.user!.id) < 0
          ? '${currentUserId}_${contact.user!.id}'
          : '${contact.user!.id}_$currentUserId';

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatDetailScreen(
            chatId: chatId,
            user: contact.user!,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactsProvider = Provider.of<ContactsProvider>(context);
    final authService = Provider.of<AuthService>(context);
    final currentUserId = authService.currentUser?.id ?? '';

    if (!contactsProvider.hasPermission) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.contacts,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Contacts permission required',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final status = await Permission.contacts.status;
                if (status.isPermanentlyDenied) {
                  await openAppSettings();
                } else {
                  final granted =
                      await contactsProvider.requestContactsPermission();
                  if (granted) {
                    _refreshContacts();
                  }
                }
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Text(
                  'Grant Permission',
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (contactsProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Filter contacts based on search query
    final contacts = contactsProvider.contacts.where((contact) {
      if (_searchQuery.isEmpty) return true;
      return contact.name.toLowerCase().contains(_searchQuery) ||
          contact.phoneNumber.contains(_searchQuery);
    }).toList();

    final appContacts = contacts.where((c) => c.user != null).toList();
    final otherContacts = contacts.where((c) => c.user == null).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search contacts...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshContacts,
            child: ListView(
              children: [
                if (appContacts.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      'Friends on Chat App',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  ...appContacts.map(
                      (contact) => _buildContactTile(contact, currentUserId)),
                ],
                if (otherContacts.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Invite to Chat App',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  ...otherContacts.map(
                      (contact) => _buildContactTile(contact, currentUserId)),
                ],
                if (contacts.isEmpty) ...[
                  const SizedBox(height: 100),
                  const Center(
                      child: Column(
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No contacts found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  )),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactTile(Contact contact, String currentUserId) {
    final bool isAppUser = contact.user != null;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isAppUser ? AppTheme.primaryColor : Colors.grey,
        backgroundImage: isAppUser && contact.user?.avatar != null
            ? NetworkImage(contact.user!.avatar!)
            : null,
        child: isAppUser && contact.user?.avatar != null
            ? null
            : Text(
                contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white),
              ),
      ),
      title: Text(
        contact.user?.username ?? contact.name,
        style: TextStyle(
          fontWeight: isAppUser ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(contact.phoneNumber),
      trailing: isAppUser
          ? IconButton(
              icon: const Icon(Icons.chat, color: AppTheme.primaryColor),
              onPressed: () => _startChat(context, contact, currentUserId),
            )
          : IconButton(
              icon: const Icon(Icons.share, color: Colors.grey),
              onPressed: () {
                // Implement invite functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invite feature coming soon')),
                );
              },
            ),
      onTap:
          isAppUser ? () => _startChat(context, contact, currentUserId) : null,
    );
  }
}
