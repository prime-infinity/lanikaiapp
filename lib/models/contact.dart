import 'package:lanikai/models/user.dart';

class Contact {
  final String name;
  final String phoneNumber;
  final User? user; // Linked user if the contact is registered in the app

  Contact({
    required this.name,
    required this.phoneNumber,
    this.user,
  });

  Contact copyWith({
    String? name,
    String? phoneNumber,
    User? user,
  }) {
    return Contact(
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      user: user ?? this.user,
    );
  }
}
