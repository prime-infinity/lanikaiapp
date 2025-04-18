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

  @override
  Widget build(BuildContext context) {
    final contactsProvider = Provider.of<ContactsProvider>(context);
    final authService = Provider.of<AuthService>(context);

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
                  // Open app settings if permission is permanently denied
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

    final contacts = contactsProvider.contacts;
    final appContacts = contacts.where((c) => c.user != null).toList();
    final otherContacts = contacts.where((c) => c.user == null).toList();

    return RefreshIndicator(
      onRefresh: _refreshContacts,
      child: ListView(
        children: [
          if (appContacts.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Friends on Chat App',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            ...appContacts.map((contact) =>
                _buildContactTile(contact, authService.currentUser?.id ?? '')),
          ],
          if (otherContacts.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Other Contacts',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
            ...otherContacts.map((contact) => _buildContactTile(contact, '')),
          ],
          if (contacts.isEmpty) ...[
            const SizedBox(height: 100),
            const Center(
              child: Text(
                'No contacts found',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ],
      ),
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
            ? null // Will be replaced by backgroundImage below
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
              onPressed: () {
                if (contact.user != null && currentUserId.isNotEmpty) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatDetailScreen(
                        chatId: currentUserId.compareTo(contact.user!.id) < 0
                            ? '${currentUserId}_${contact.user!.id}'
                            : '${contact.user!.id}_$currentUserId',
                        user: contact.user!,
                      ),
                    ),
                  );
                }
              },
            )
          : null,
    );
  }
}
