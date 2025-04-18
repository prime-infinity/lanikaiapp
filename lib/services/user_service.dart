// lib/services/user_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/user.dart' as app_models;

class UserService extends ChangeNotifier {
  final supabase = Supabase.instance.client;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<bool> updateProfile({
    required String userId,
    String? username,
    String? phoneNumber,
    File? avatarFile,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      Map<String, dynamic> updates = {};

      if (username != null) {
        updates['username'] = username;
      }

      if (phoneNumber != null) {
        updates['phone_number'] = phoneNumber;
      }

      // Upload avatar if provided
      if (avatarFile != null) {
        final fileExt = avatarFile.path.split('.').last;
        final fileName = '${const Uuid().v4()}.$fileExt';
        final filePath = 'avatars/$userId/$fileName';

        await supabase.storage.from('avatars').upload(
              filePath,
              avatarFile,
            );

        final imageUrl =
            supabase.storage.from('avatars').getPublicUrl(filePath);
        updates['avatar'] = imageUrl;
      }

      if (updates.isNotEmpty) {
        await supabase.from('profiles').update(updates).eq('id', userId);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error updating profile: $e');
      return false;
    }
  }

  Future<List<app_models.User>> searchUsersByPhoneNumbers(
      List<String> phoneNumbers) async {
    try {
      // Prepare two versions of each phone number for matching
      final List<String> searchNumbers = [];
      for (final number in phoneNumbers) {
        searchNumbers.add(number); // Original normalized number

        // Add version with + if it's missing and looks like international format
        if (!number.startsWith('+') && number.length > 10) {
          searchNumbers.add('+$number');
        }

        // Add version without + for matching
        if (number.startsWith('+')) {
          searchNumbers.add(number.substring(1));
        }
      }

      // Get profiles with phone numbers
      final response = await supabase
          .from('profiles')
          .select()
          .not('phone_number', 'is', null);

      // Match phone numbers with flexibility
      List<app_models.User> matchedUsers = [];
      for (final user in response) {
        if (user['phone_number'] == null) continue;

        final dbNumber = user['phone_number'] as String;

        // Try to match with original form in database
        if (searchNumbers.contains(dbNumber)) {
          matchedUsers.add(app_models.User.fromJson(user));
          continue;
        }

        // Try with normalized version
        final normalizedDbNumber =
            dbNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
        if (searchNumbers.contains(normalizedDbNumber)) {
          matchedUsers.add(app_models.User.fromJson(user));
          continue;
        }

        // Try without + if present
        if (normalizedDbNumber.startsWith('+') &&
            searchNumbers.contains(normalizedDbNumber.substring(1))) {
          matchedUsers.add(app_models.User.fromJson(user));
          continue;
        }

        // Try with + if not present and looks like international
        if (!normalizedDbNumber.startsWith('+') &&
            normalizedDbNumber.length > 10 &&
            searchNumbers.contains('+$normalizedDbNumber')) {
          matchedUsers.add(app_models.User.fromJson(user));
        }
      }

      return matchedUsers;
    } catch (e) {
      debugPrint('Error searching users by phone: $e');
      return [];
    }
  }
}
