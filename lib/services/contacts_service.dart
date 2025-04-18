// lib/services/contacts_service.dart
import 'package:flutter/material.dart';
import 'package:lanikai/models/user.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../models/contact.dart' as app_model;
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

      // Check permission with flutter_contacts
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

        // Link users to contacts with flexible matching
        for (int i = 0; i < appContacts.length; i++) {
          final contact = appContacts[i];
          final String contactNumber = contact.phoneNumber;

          // Try to find a matching user with flexible phone number comparison
          final matchingUser = registeredUsers.firstWhere(
            (user) {
              if (user.phoneNumber == null) return false;

              final dbNumber = user.phoneNumber!;

              // Direct match
              if (dbNumber == contactNumber) return true;

              // Match with + variations
              if (dbNumber.startsWith('+') &&
                  dbNumber.substring(1) == contactNumber) return true;
              if (!dbNumber.startsWith('+') && '+$dbNumber' == contactNumber) {
                return true;
              }

              // Strip all formatting and compare digits only as last resort
              final strippedDbNumber = dbNumber.replaceAll(RegExp(r'\D'), '');
              final strippedContactNumber =
                  contactNumber.replaceAll(RegExp(r'\D'), '');
              return strippedDbNumber == strippedContactNumber;
            },
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
    // Remove spaces, dashes and other non-essential characters but keep the plus sign
    String normalized = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // If the number starts with a plus sign, keep it as is
    if (normalized.startsWith('+')) {
      return normalized;
    }
    // If the number doesn't have a plus sign but looks like an international number
    // (e.g. starts with country code like 1 for US), add the plus sign
    else if (normalized.length > 10 &&
        (normalized.startsWith('1') || normalized.startsWith('44'))) {
      return '+$normalized';
    }
    // Otherwise just return the digits
    else {
      return normalized.replaceAll(RegExp(r'\D'), '');
    }
  }
}
