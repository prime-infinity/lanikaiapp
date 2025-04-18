// lib/services/contacts_service.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../models/contact.dart' as app_model;
import '../models/user.dart';
import 'user_service.dart';

class ContactsProvider extends ChangeNotifier {
  final UserService _userService = UserService();
  List<app_model.Contact> _contacts = [];
  bool _isLoading = false;
  bool _hasPermission = false;

  List<app_model.Contact> get contacts => _contacts;
  bool get isLoading => _isLoading;
  bool get hasPermission => _hasPermission;

  Future<bool> requestContactsPermission() async {
    // Check current status first
    PermissionStatus status = await Permission.contacts.status;

    // If already granted, return true
    if (status.isGranted) {
      _hasPermission = true;
      notifyListeners();
      return true;
    }

    // If permanently denied, can't request directly
    if (status.isPermanentlyDenied) {
      _hasPermission = false;
      notifyListeners();
      return false;
    }

    // Request permission
    status = await Permission.contacts.request();
    _hasPermission = status.isGranted;
    notifyListeners();
    return _hasPermission;
  }

  Future<void> loadContacts() async {
    if (!_hasPermission) {
      final granted = await requestContactsPermission();
      if (!granted) return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      // Check permission directly with flutter_contacts as well (belt and suspenders approach)
      if (!await FlutterContacts.requestPermission()) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Fetch device contacts with phone numbers
      final deviceContacts = await FlutterContacts.getContacts(
          withProperties: true, withPhoto: false);

      // Convert to our Contact model and normalize phone numbers
      List<app_model.Contact> appContacts = [];
      List<String> phoneNumbers = [];

      for (final deviceContact in deviceContacts) {
        if (deviceContact.phones.isNotEmpty) {
          for (final phone in deviceContact.phones) {
            if (phone.number.isNotEmpty) {
              // Normalize phone number (remove spaces, dashes, etc.)
              final normalizedNumber = normalizePhoneNumber(phone.number);
              if (normalizedNumber.isNotEmpty) {
                appContacts.add(app_model.Contact(
                  name: deviceContact.displayName,
                  phoneNumber: normalizedNumber,
                ));
                phoneNumbers.add(normalizedNumber);
              }
            }
          }
        }
      }

      // Find contacts that are registered in our app
      if (phoneNumbers.isNotEmpty) {
        final registeredUsers =
            await _userService.searchUsersByPhoneNumbers(phoneNumbers);

        // Link users to contacts
        for (int i = 0; i < appContacts.length; i++) {
          final contact = appContacts[i];
          final matchingUser = registeredUsers.firstWhere(
            (user) => user.phoneNumber == contact.phoneNumber,
            orElse: () => User(id: '', email: ''),
          );

          if (matchingUser.id.isNotEmpty) {
            appContacts[i] = app_model.Contact(
              name: contact.name,
              phoneNumber: contact.phoneNumber,
              user: matchingUser,
            );
          }
        }

        // Sort contacts: app users first, then alphabetically
        appContacts.sort((a, b) {
          if (a.user != null && b.user == null) return -1;
          if (a.user == null && b.user != null) return 1;
          return a.name.compareTo(b.name);
        });
      }

      _contacts = appContacts;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error loading contacts: $e');
    }
  }

  String normalizePhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    return phoneNumber.replaceAll(RegExp(r'\D'), '');
  }
}
