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
      final response = await supabase
          .from('profiles')
          .select()
          .inFilter('phone_number', phoneNumbers);

      return (response as List)
          .map((user) => app_models.User.fromJson(user))
          .toList();
    } catch (e) {
      debugPrint('Error searching users by phone: $e');
      return [];
    }
  }
}
